import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/enums/queue_insert_mode_enum.dart';
import 'package:cams_store_manager/core/error/failures.dart';
import 'package:cams_store_manager/features/cams/data/repositories/cams_repository_impl.dart';
import 'package:cams_store_manager/features/cams/data/services/store_hub_service.dart';
import 'package:cams_store_manager/features/cams/domain/entities/space_playback_state.dart';
import 'package:cams_store_manager/features/cams/domain/usecases/get_space_state.dart';
import 'package:cams_store_manager/features/cams/domain/usecases/queue_usecases.dart';
import 'package:cams_store_manager/features/suno/data/datasources/suno_remote_datasource.dart';
import 'package:cams_store_manager/features/suno/data/repositories/suno_repository_impl.dart';
import 'package:cams_store_manager/features/suno/domain/entities/suno_config.dart';
import 'package:cams_store_manager/features/suno/domain/entities/suno_generation.dart';
import 'package:cams_store_manager/features/suno/domain/entities/suno_generation_status.dart';
import 'package:cams_store_manager/features/suno/domain/services/suno_playback_orchestrator.dart';
import 'package:cams_store_manager/features/suno/domain/usecases/suno_usecases.dart';
import 'package:cams_store_manager/features/tracks/data/repositories/track_repository_impl.dart';
import 'package:cams_store_manager/features/tracks/domain/entities/api_track.dart';
import 'package:cams_store_manager/features/tracks/domain/usecases/track_usecases.dart';

void main() {
  group('SunoPlaybackOrchestrator', () {
    late _FakeSunoRepository sunoRepository;
    late _FakeTrackRepository trackRepository;
    late _FakeCamsRepository camsRepository;
    late SunoPlaybackOrchestrator orchestrator;
    late List<SunoPlaybackUpdate> updates;
    late StreamSubscription<SunoPlaybackUpdate> subscription;

    setUp(() {
      sunoRepository = _FakeSunoRepository();
      trackRepository = _FakeTrackRepository();
      camsRepository = _FakeCamsRepository();
      orchestrator = SunoPlaybackOrchestrator(
        createSunoGeneration: CreateSunoGeneration(sunoRepository),
        getSunoGeneration: GetSunoGeneration(sunoRepository),
        getTrackById: GetTrackById(trackRepository),
        getSpaceState: GetSpaceState(camsRepository),
        queueTracks: QueueTracks(camsRepository),
        generationPollInterval: const Duration(milliseconds: 1),
        trackPollInterval: const Duration(milliseconds: 1),
        generationPollAttempts: 1,
        trackPollAttempts: 2,
      );
      updates = <SunoPlaybackUpdate>[];
      subscription = orchestrator.updates.listen(updates.add);
    });

    tearDown(() async {
      await subscription.cancel();
      await orchestrator.dispose();
    });

    test('appends completed Suno track to active queue', () async {
      camsRepository.spaceState = const SpacePlaybackState(
        spaceId: 'space-1',
        currentQueueItemId: 'queue-1',
        hlsUrl: 'https://stream.example.com/live.m3u8',
      );
      trackRepository.trackById['track-1'] = _buildTrack(
        id: 'track-1',
        title: 'Suno Night Drive',
        hlsUrl: 'https://stream.example.com/track-1.m3u8',
      );

      await orchestrator.handleGenerationSnapshot(
        generation: const SunoGeneration(
          id: 'gen-1',
          generationStatus: SunoGenerationStatus.completed,
          generatedTrackId: 'track-1',
        ),
        context: const SunoPlaybackContext(spaceId: 'space-1'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(camsRepository.lastQueueTracksParams, isNotNull);
      expect(
        camsRepository.lastQueueTracksParams?.mode,
        QueueInsertModeEnum.addToQueue,
      );
      expect(camsRepository.lastQueueTracksParams?.trackIds, ['track-1']);
      expect(
        updates.any(
          (update) =>
              update.kind == SunoPlaybackUpdateKind.queue &&
              update.message == 'Suno track appended to the live queue.',
        ),
        isTrue,
      );
    });

    test('uses playNow when the space is idle and empty', () async {
      camsRepository.spaceState = const SpacePlaybackState(spaceId: 'space-1');
      trackRepository.trackById['track-2'] = _buildTrack(
        id: 'track-2',
        title: 'Suno Sunrise',
        hlsUrl: 'https://stream.example.com/track-2.m3u8',
      );
      sunoRepository.generationById['gen-2'] = const SunoGeneration(
        id: 'gen-2',
        brandId: 'brand-1',
        generationStatus: SunoGenerationStatus.completed,
        progressPercent: 100,
        generatedTrackId: 'track-2',
      );

      orchestrator.handleRealtimeStatusChanged(
        event: const SunoGenerationStatusChangedEvent(
          id: 'gen-2',
          brandId: 'brand-1',
          generationStatus: SunoGenerationStatus.completed,
          progressPercent: 100,
          generatedTrackId: 'track-2',
        ),
        context: const SunoPlaybackContext(spaceId: 'space-1'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(camsRepository.lastQueueTracksParams, isNotNull);
      expect(
        camsRepository.lastQueueTracksParams?.mode,
        QueueInsertModeEnum.playNow,
      );
      expect(
        updates.any(
          (update) =>
              update.kind == SunoPlaybackUpdateKind.queue &&
              update.message == 'Suno track queued and playback started.',
        ),
        isTrue,
      );
    });

    test('reports waiting HLS when generated track never becomes stream ready',
        () async {
      camsRepository.spaceState = const SpacePlaybackState(spaceId: 'space-1');
      trackRepository.sequenceByTrackId['track-3'] = <ApiTrack>[
        _buildTrack(id: 'track-3', title: 'Suno Draft'),
        _buildTrack(id: 'track-3', title: 'Suno Draft'),
      ];

      await orchestrator.handleGenerationSnapshot(
        generation: const SunoGeneration(
          id: 'gen-3',
          generationStatus: SunoGenerationStatus.completed,
          generatedTrackId: 'track-3',
        ),
        context: const SunoPlaybackContext(spaceId: 'space-1'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(camsRepository.lastQueueTracksParams, isNull);
      expect(
        updates.any(
          (update) =>
              update.kind == SunoPlaybackUpdateKind.error &&
              update.message == 'Suno track is ready in library but still waiting for HLS.',
        ),
        isTrue,
      );
    });
  });
}

ApiTrack _buildTrack({
  required String id,
  required String title,
  String? hlsUrl,
}) {
  return ApiTrack(
    id: id,
    title: title,
    hlsUrl: hlsUrl,
    createdAt: DateTime.parse('2026-03-24T08:00:00Z'),
  );
}

class _FakeSunoRepository implements SunoRepository {
  final Map<String, SunoGeneration> generationById = <String, SunoGeneration>{};

  @override
  Future<Either<Failure, String>> createGeneration(
    CreateSunoGenerationRequest request,
  ) async {
    return const Right('gen-created');
  }

  @override
  Future<Either<Failure, SunoGeneration>> getGeneration(String id) async {
    final generation = generationById[id];
    if (generation == null) {
      return const Left(ServerFailure('Generation not found'));
    }
    return Right(generation);
  }

  @override
  Future<Either<Failure, void>> cancelGeneration(String id) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, SunoConfig>> getConfig() async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, SunoConfig>> updateConfig(
    UpdateSunoConfigRequest request,
  ) async {
    throw UnimplementedError();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTrackRepository implements TrackRepository {
  final Map<String, ApiTrack> trackById = <String, ApiTrack>{};
  final Map<String, List<ApiTrack>> sequenceByTrackId = <String, List<ApiTrack>>{};

  @override
  Future<Either<Failure, ApiTrack>> getTrackById(String trackId) async {
    final sequence = sequenceByTrackId[trackId];
    if (sequence != null && sequence.isNotEmpty) {
      return Right(sequence.removeAt(0));
    }
    final track = trackById[trackId];
    if (track == null) {
      return const Left(ServerFailure('Track not found'));
    }
    return Right(track);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCamsRepository implements CamsRepository {
  SpacePlaybackState spaceState = const SpacePlaybackState(spaceId: 'space-1');
  QueueTracksParams? lastQueueTracksParams;

  @override
  Future<Either<Failure, SpacePlaybackState>> getSpaceState(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  }) async {
    return Right(spaceState);
  }

  @override
  Future<Either<Failure, void>> queueTracks({
    required String spaceId,
    required List<String> trackIds,
    required QueueInsertModeEnum mode,
    bool isClearExistingQueue = false,
    String? reason,
    bool usePlaybackDeviceScope = false,
  }) async {
    lastQueueTracksParams = QueueTracksParams(
      spaceId: spaceId,
      trackIds: trackIds,
      mode: mode,
      isClearExistingQueue: isClearExistingQueue,
      reason: reason,
      usePlaybackDeviceScope: usePlaybackDeviceScope,
    );
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
