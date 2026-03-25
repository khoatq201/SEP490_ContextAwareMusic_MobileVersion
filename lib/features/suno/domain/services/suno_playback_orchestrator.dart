import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/enums/queue_insert_mode_enum.dart';
import '../../../../core/error/failures.dart';
import '../../../cams/data/services/store_hub_service.dart';
import '../../../cams/domain/entities/space_playback_state.dart';
import '../../../cams/domain/usecases/get_space_state.dart';
import '../../../cams/domain/usecases/queue_usecases.dart';
import '../../../tracks/domain/entities/api_track.dart';
import '../../../tracks/domain/entities/track_metadata_status.dart';
import '../../../tracks/domain/usecases/track_usecases.dart';
import '../../data/datasources/suno_remote_datasource.dart';
import '../entities/suno_generation.dart';
import '../entities/suno_generation_status.dart';
import '../usecases/suno_usecases.dart';

enum SunoPlaybackUpdateKind {
  generation,
  track,
  queue,
  error,
}

class SunoPlaybackContext extends Equatable {
  final String spaceId;
  final bool usePlaybackDeviceScope;

  const SunoPlaybackContext({
    required this.spaceId,
    this.usePlaybackDeviceScope = false,
  });

  @override
  List<Object?> get props => [spaceId, usePlaybackDeviceScope];
}

class SunoPlaybackUpdate extends Equatable {
  final String generationId;
  final SunoPlaybackUpdateKind kind;
  final SunoGeneration? generation;
  final ApiTrack? track;
  final String? message;

  const SunoPlaybackUpdate({
    required this.generationId,
    required this.kind,
    this.generation,
    this.track,
    this.message,
  });

  @override
  List<Object?> get props => [generationId, kind, generation, track, message];
}

class SunoPlaybackOrchestrator {
  SunoPlaybackOrchestrator({
    required CreateSunoGeneration createSunoGeneration,
    required GetSunoGeneration getSunoGeneration,
    required GetTrackById getTrackById,
    required GetSpaceState getSpaceState,
    required QueueTracks queueTracks,
    this.generationPollInterval = const Duration(seconds: 5),
    this.trackPollInterval = const Duration(seconds: 5),
    this.generationPollAttempts = 24,
    this.trackPollAttempts = 12,
  })  : _createSunoGeneration = createSunoGeneration,
        _getSunoGeneration = getSunoGeneration,
        _getTrackById = getTrackById,
        _getSpaceState = getSpaceState,
        _queueTracks = queueTracks;

  final CreateSunoGeneration _createSunoGeneration;
  final GetSunoGeneration _getSunoGeneration;
  final GetTrackById _getTrackById;
  final GetSpaceState _getSpaceState;
  final QueueTracks _queueTracks;
  final Duration generationPollInterval;
  final Duration trackPollInterval;
  final int generationPollAttempts;
  final int trackPollAttempts;

  final StreamController<SunoPlaybackUpdate> _updates =
      StreamController<SunoPlaybackUpdate>.broadcast();
  final Map<String, SunoPlaybackContext> _contextsByGenerationId =
      <String, SunoPlaybackContext>{};
  final Map<String, SunoGeneration> _generationSnapshots =
      <String, SunoGeneration>{};
  final Set<String> _activeGenerationPollIds = <String>{};
  final Set<String> _activeTrackPollIds = <String>{};
  final Set<String> _queuedGenerationIds = <String>{};

  Stream<SunoPlaybackUpdate> get updates => _updates.stream;

  Future<Either<Failure, SunoGeneration>> createAndTrack({
    required CreateSunoGenerationRequest request,
    required SunoPlaybackContext context,
  }) async {
    final result = await _createSunoGeneration(request);
    return result.fold(
      Left.new,
      (generationId) {
        final generation = SunoGeneration(
          id: generationId,
          generationStatus: SunoGenerationStatus.queued,
          progressPercent: 0,
          prompt: request.prompt,
          title: request.title,
          artist: request.artist,
          moodId: request.moodId,
          targetPlaylistId: request.targetPlaylistId,
          autoAddToTargetPlaylist: request.autoAddToTargetPlaylist,
        );
        _contextsByGenerationId[generationId] = context;
        _generationSnapshots[generationId] = generation;
        _emit(
          SunoPlaybackUpdate(
            generationId: generationId,
            kind: SunoPlaybackUpdateKind.generation,
            generation: generation,
          ),
        );
        _startGenerationPolling(generationId, context);
        return Right(generation);
      },
    );
  }

  void handleRealtimeStatusChanged({
    required SunoGenerationStatusChangedEvent event,
    required SunoPlaybackContext context,
  }) {
    if (event.id.isEmpty) return;

    _contextsByGenerationId[event.id] = context;
    final previous = _generationSnapshots[event.id];
    final generation = (previous ?? SunoGeneration(id: event.id)).copyWith(
      brandId: event.brandId.isEmpty ? null : event.brandId,
      generationStatus: event.generationStatus,
      progressPercent: event.progressPercent,
      errorMessage: event.errorMessage,
      generatedTrackId: event.generatedTrackId,
    );
    _generationSnapshots[event.id] = generation;
    _emit(
      SunoPlaybackUpdate(
        generationId: event.id,
        kind: SunoPlaybackUpdateKind.generation,
        generation: generation,
      ),
    );

    if (event.generationStatus.isTerminal ||
        (event.generatedTrackId?.isNotEmpty ?? false)) {
      unawaited(_refreshGenerationSnapshot(event.id, context));
      if (generation.generationStatus == SunoGenerationStatus.completed &&
          (generation.generatedTrackId?.isNotEmpty ?? false)) {
        unawaited(
          handleGenerationSnapshot(
            generation: generation,
            context: context,
          ),
        );
      }
      return;
    }

    _startGenerationPolling(event.id, context);
  }

  Future<void> handleGenerationSnapshot({
    required SunoGeneration generation,
    required SunoPlaybackContext context,
  }) async {
    if (generation.id.isEmpty) return;

    _contextsByGenerationId[generation.id] = context;
    _generationSnapshots[generation.id] = generation;
    _emit(
      SunoPlaybackUpdate(
        generationId: generation.id,
        kind: SunoPlaybackUpdateKind.generation,
        generation: generation,
      ),
    );

    if (!generation.generationStatus.isTerminal) {
      _startGenerationPolling(generation.id, context);
      return;
    }

    if (generation.generationStatus != SunoGenerationStatus.completed) {
      return;
    }

    final trackId = generation.generatedTrackId;
    if (trackId == null || trackId.isEmpty) return;
    await _pollTrackUntilStreamReady(
      generationId: generation.id,
      trackId: trackId,
      context: context,
    );
  }

  Future<void> dispose() async {
    await _updates.close();
  }

  void _startGenerationPolling(
    String generationId,
    SunoPlaybackContext context,
  ) {
    if (!_activeGenerationPollIds.add(generationId)) {
      return;
    }
    unawaited(_pollGeneration(generationId, context));
  }

  Future<void> _refreshGenerationSnapshot(
    String generationId,
    SunoPlaybackContext context,
  ) async {
    final result = await _getSunoGeneration(generationId);
    await result.fold(
      (_) async {},
      (generation) => handleGenerationSnapshot(
        generation: generation,
        context: context,
      ),
    );
  }

  Future<void> _pollGeneration(
    String generationId,
    SunoPlaybackContext context,
  ) async {
    try {
      for (var attempt = 0; attempt < generationPollAttempts; attempt++) {
        if (attempt > 0) {
          await Future<void>.delayed(generationPollInterval);
        }

        final result = await _getSunoGeneration(generationId);
        var shouldStop = false;
        await result.fold(
          (_) async {
            shouldStop = attempt == generationPollAttempts - 1;
          },
          (generation) async {
            await handleGenerationSnapshot(
              generation: generation,
              context: context,
            );
            shouldStop = generation.generationStatus.isTerminal;
          },
        );

        if (shouldStop) {
          break;
        }
      }
    } finally {
      _activeGenerationPollIds.remove(generationId);
    }
  }

  Future<void> _pollTrackUntilStreamReady({
    required String generationId,
    required String trackId,
    required SunoPlaybackContext context,
  }) async {
    if (!_activeTrackPollIds.add(generationId)) {
      return;
    }

    try {
      for (var attempt = 0; attempt < trackPollAttempts; attempt++) {
        if (attempt > 0) {
          await Future<void>.delayed(trackPollInterval);
        }

        final result = await _getTrackById(trackId);
        var shouldStop = false;
        await result.fold(
          (_) async {
            if (attempt == trackPollAttempts - 1) {
              _emit(
                SunoPlaybackUpdate(
                  generationId: generationId,
                  kind: SunoPlaybackUpdateKind.error,
                  message:
                      'Suno track was created but could not be refreshed yet.',
                ),
              );
              shouldStop = true;
            }
          },
          (track) async {
            final nextTrack = _withDerivedMetadataStatus(
              track,
              isFinalAttempt: attempt == trackPollAttempts - 1,
            );
            _emit(
              SunoPlaybackUpdate(
                generationId: generationId,
                kind: SunoPlaybackUpdateKind.track,
                track: nextTrack,
              ),
            );
            if (nextTrack.isStreamReady) {
              await _queueTrackForPlayback(
                generationId: generationId,
                track: nextTrack,
                context: context,
              );
              shouldStop = true;
              return;
            }

            if (attempt == trackPollAttempts - 1) {
              _emit(
                SunoPlaybackUpdate(
                  generationId: generationId,
                  kind: SunoPlaybackUpdateKind.error,
                  track: nextTrack,
                  message:
                      'Suno track is ready in library but still waiting for HLS.',
                ),
              );
              shouldStop = true;
            }
          },
        );

        if (shouldStop) {
          break;
        }
      }
    } finally {
      _activeTrackPollIds.remove(generationId);
    }
  }

  Future<void> _queueTrackForPlayback({
    required String generationId,
    required ApiTrack track,
    required SunoPlaybackContext context,
  }) async {
    if (_queuedGenerationIds.contains(generationId)) {
      return;
    }

    final queueMode = await _resolveQueueMode(context);
    final queueResult = await _queueTracks(
      QueueTracksParams(
        spaceId: context.spaceId,
        trackIds: [track.id],
        mode: queueMode,
        reason: queueMode == QueueInsertModeEnum.playNow
            ? 'Suno AI auto-play'
            : 'Suno AI appended to queue',
        usePlaybackDeviceScope: context.usePlaybackDeviceScope,
      ),
    );

    queueResult.fold(
      (failure) {
        _emit(
          SunoPlaybackUpdate(
            generationId: generationId,
            kind: SunoPlaybackUpdateKind.error,
            track: track,
            message: failure.message,
          ),
        );
      },
      (_) {
        _queuedGenerationIds.add(generationId);
        _emit(
          SunoPlaybackUpdate(
            generationId: generationId,
            kind: SunoPlaybackUpdateKind.queue,
            track: track,
            message: queueMode == QueueInsertModeEnum.playNow
                ? 'Suno track queued and playback started.'
                : 'Suno track appended to the live queue.',
          ),
        );
      },
    );
  }

  Future<QueueInsertModeEnum> _resolveQueueMode(
    SunoPlaybackContext context,
  ) async {
    final result = await _getSpaceState(
      context.spaceId,
      usePlaybackDeviceScope: context.usePlaybackDeviceScope,
    );

    return result.fold(
      (_) => QueueInsertModeEnum.addToQueue,
      (state) => _shouldBootstrapPlayback(state)
          ? QueueInsertModeEnum.playNow
          : QueueInsertModeEnum.addToQueue,
    );
  }

  bool _shouldBootstrapPlayback(SpacePlaybackState state) {
    final hasCurrentQueueItem = state.currentQueueItemId != null &&
        state.currentQueueItemId!.isNotEmpty;
    final hasPendingQueueItem = state.pendingQueueItemId != null &&
        state.pendingQueueItemId!.isNotEmpty;
    return !state.isStreaming &&
        !state.isPaused &&
        !hasCurrentQueueItem &&
        !hasPendingQueueItem &&
        state.spaceQueueItems.isEmpty;
  }

  ApiTrack _withDerivedMetadataStatus(
    ApiTrack track, {
    required bool isFinalAttempt,
  }) {
    final status = track.hasMeaningfulMetadata
        ? TrackMetadataStatus.metadataReady
        : isFinalAttempt
            ? TrackMetadataStatus.metadataUnknown
            : TrackMetadataStatus.metadataPending;
    return track.copyWith(metadataStatusOverride: status);
  }

  void _emit(SunoPlaybackUpdate update) {
    if (_updates.isClosed) return;
    _updates.add(update);
  }
}
