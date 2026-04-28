import 'package:dartz/dartz.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/enums/playback_command_enum.dart';
import '../../../../core/enums/queue_insert_mode_enum.dart';
import '../../domain/entities/pair_code_snapshot.dart';
import '../../domain/entities/pair_device_info.dart';
import '../../domain/entities/space_queue_state_item.dart';
import '../../domain/entities/space_playback_state.dart';
import '../models/override_response_model.dart';
import '../datasources/cams_remote_datasource.dart';

abstract class CamsRepository {
  /// Override Space music.
  Future<Either<Failure, OverrideResponse>> overrideSpace({
    required String spaceId,
    List<String>? trackIds,
    String? playlistId,
    String? moodId,
    bool? isClearManagerSelectedQueues,
    bool? isCutOver,
    int? manualOverrideTtlSeconds,
    String? reason,
    bool usePlaybackDeviceScope = false,
  });

  /// Cancel active override.
  Future<Either<Failure, void>> cancelOverride(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  });

  /// Send playback command.
  Future<Either<Failure, void>> sendPlaybackCommand({
    required String spaceId,
    required PlaybackCommandEnum command,
    double? seekPositionSeconds,
    String? targetQueueItemId,
    String? targetTrackId,
    bool usePlaybackDeviceScope = false,
  });

  Future<Either<Failure, void>> updateAudioState({
    required String spaceId,
    int? volumePercent,
    bool? isMuted,
    int? queueEndBehavior,
    bool usePlaybackDeviceScope = false,
  });

  Future<Either<Failure, void>> updateSchedulingState({
    required String spaceId,
    required bool isScheduling,
    bool usePlaybackDeviceScope = false,
  });

  Future<Either<Failure, void>> queueTracks({
    required String spaceId,
    required List<String> trackIds,
    required QueueInsertModeEnum mode,
    bool isClearExistingQueue = false,
    String? reason,
    bool usePlaybackDeviceScope = false,
  });

  Future<Either<Failure, void>> queuePlaylist({
    required String spaceId,
    required String playlistId,
    required QueueInsertModeEnum mode,
    bool isClearExistingQueue = false,
    String? reason,
    bool usePlaybackDeviceScope = false,
  });

  Future<Either<Failure, void>> reorderQueue({
    required String spaceId,
    required List<String> queueItemIds,
    bool usePlaybackDeviceScope = false,
  });

  Future<Either<Failure, void>> removeQueueItems({
    required String spaceId,
    required List<String> queueItemIds,
    bool usePlaybackDeviceScope = false,
  });

  Future<Either<Failure, void>> clearQueue({
    required String spaceId,
    bool usePlaybackDeviceScope = false,
  });

  Future<Either<Failure, List<SpaceQueueStateItem>>> getQueue(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  });

  /// Get current playback state.
  Future<Either<Failure, SpacePlaybackState>> getSpaceState(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  });

  Future<Either<Failure, SpacePlaybackState>> getSpaceStateForPlaybackDevice();

  Future<Either<Failure, PairDeviceInfo>> getPairDeviceInfoForManager(
    String spaceId,
  );

  Future<Either<Failure, PairDeviceInfo>> getPairDeviceInfoForPlaybackDevice();

  Future<Either<Failure, PairCodeSnapshot>> generatePairCode(String spaceId);

  Future<Either<Failure, void>> revokePairCode(String spaceId);

  Future<Either<Failure, void>> unpairDevice(String spaceId);
}

class CamsRepositoryImpl implements CamsRepository {
  final CamsRemoteDataSource remoteDataSource;

  CamsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, OverrideResponse>> overrideSpace({
    required String spaceId,
    List<String>? trackIds,
    String? playlistId,
    String? moodId,
    bool? isClearManagerSelectedQueues,
    bool? isCutOver,
    int? manualOverrideTtlSeconds,
    String? reason,
    bool usePlaybackDeviceScope = false,
  }) async {
    try {
      final result = await remoteDataSource.overrideSpace(
        spaceId: spaceId,
        trackIds: trackIds,
        playlistId: playlistId,
        moodId: moodId,
        isClearManagerSelectedQueues: isClearManagerSelectedQueues,
        isCutOver: isCutOver,
        manualOverrideTtlSeconds: manualOverrideTtlSeconds,
        reason: reason,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to override space: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelOverride(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  }) async {
    try {
      await remoteDataSource.cancelOverride(
        spaceId,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to cancel override: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> sendPlaybackCommand({
    required String spaceId,
    required PlaybackCommandEnum command,
    double? seekPositionSeconds,
    String? targetQueueItemId,
    String? targetTrackId,
    bool usePlaybackDeviceScope = false,
  }) async {
    try {
      await remoteDataSource.sendPlaybackCommand(
        spaceId: spaceId,
        command: command,
        seekPositionSeconds: seekPositionSeconds,
        targetQueueItemId: targetQueueItemId,
        targetTrackId: targetTrackId,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to send playback command: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateAudioState({
    required String spaceId,
    int? volumePercent,
    bool? isMuted,
    int? queueEndBehavior,
    bool usePlaybackDeviceScope = false,
  }) async {
    try {
      await remoteDataSource.updateAudioState(
        spaceId: spaceId,
        volumePercent: volumePercent,
        isMuted: isMuted,
        queueEndBehavior: queueEndBehavior,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to update audio state: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateSchedulingState({
    required String spaceId,
    required bool isScheduling,
    bool usePlaybackDeviceScope = false,
  }) async {
    try {
      await remoteDataSource.updateSchedulingState(
        spaceId: spaceId,
        isScheduling: isScheduling,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
      );
      return const Right(null);
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to update scheduling right now.',
          stackTrace: stackTrace,
        ),
      );
    }
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
    try {
      await remoteDataSource.queueTracks(
        spaceId: spaceId,
        trackIds: trackIds,
        mode: mode,
        isClearExistingQueue: isClearExistingQueue,
        reason: reason,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to queue tracks: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> queuePlaylist({
    required String spaceId,
    required String playlistId,
    required QueueInsertModeEnum mode,
    bool isClearExistingQueue = false,
    String? reason,
    bool usePlaybackDeviceScope = false,
  }) async {
    try {
      await remoteDataSource.queuePlaylist(
        spaceId: spaceId,
        playlistId: playlistId,
        mode: mode,
        isClearExistingQueue: isClearExistingQueue,
        reason: reason,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to queue playlist: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> reorderQueue({
    required String spaceId,
    required List<String> queueItemIds,
    bool usePlaybackDeviceScope = false,
  }) async {
    try {
      await remoteDataSource.reorderQueue(
        spaceId: spaceId,
        queueItemIds: queueItemIds,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to reorder queue: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> removeQueueItems({
    required String spaceId,
    required List<String> queueItemIds,
    bool usePlaybackDeviceScope = false,
  }) async {
    try {
      await remoteDataSource.removeQueueItems(
        spaceId: spaceId,
        queueItemIds: queueItemIds,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to remove queue items: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearQueue({
    required String spaceId,
    bool usePlaybackDeviceScope = false,
  }) async {
    try {
      await remoteDataSource.clearQueue(
        spaceId: spaceId,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to clear queue: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SpaceQueueStateItem>>> getQueue(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  }) async {
    try {
      final queue = await remoteDataSource.getQueue(
        spaceId,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
      );
      return Right(queue);
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to load the CAMS queue right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, SpacePlaybackState>> getSpaceState(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  }) async {
    try {
      final state = await remoteDataSource.getSpaceState(
        spaceId,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
      );
      final enrichedState = await _withProfileBpmGuidance(state);
      return Right(enrichedState);
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to load CAMS playback state right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, SpacePlaybackState>>
      getSpaceStateForPlaybackDevice() async {
    try {
      final state = await remoteDataSource.getSpaceStateForPlaybackDevice();
      final enrichedState = await _withProfileBpmGuidance(state);
      return Right(enrichedState);
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to load CAMS playback state right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<SpacePlaybackState> _withProfileBpmGuidance(
    SpacePlaybackState state,
  ) async {
    final moodName = state.explainability?.moodName ?? state.moodName;
    final baseExplainability = _ensureMoodExplainability(
      state.explainability,
      moodName,
    );

    if (_hasCompleteBpmGuidance(baseExplainability)) {
      return state.copyWith(explainability: baseExplainability);
    }

    SpacePlaybackExplainability? profileGuidance;
    try {
      profileGuidance = await remoteDataSource.getFuzzyProfileBpmGuidance(
        spaceId: state.spaceId,
        storeId: state.storeId,
        moodName: moodName,
      );
    } catch (_) {
      profileGuidance = null;
    }

    final merged = _mergeExplainability(
      baseExplainability,
      profileGuidance,
    );
    return merged == null ? state : state.copyWith(explainability: merged);
  }

  bool _hasCompleteBpmGuidance(SpacePlaybackExplainability? explainability) {
    return explainability?.hasBpmBand == true &&
        explainability?.recommendedBpmTarget != null;
  }

  SpacePlaybackExplainability? _ensureMoodExplainability(
    SpacePlaybackExplainability? explainability,
    String? moodName,
  ) {
    final trimmedMood = moodName?.trim();
    if (trimmedMood == null || trimmedMood.isEmpty) return explainability;
    if (explainability == null) {
      return SpacePlaybackExplainability(moodName: trimmedMood);
    }
    if (explainability.moodName?.trim().isNotEmpty ?? false) {
      return explainability;
    }
    return _mergeExplainability(
      explainability,
      SpacePlaybackExplainability(moodName: trimmedMood),
    );
  }

  SpacePlaybackExplainability? _mergeExplainability(
    SpacePlaybackExplainability? primary,
    SpacePlaybackExplainability? fallback,
  ) {
    if (primary == null) return fallback;
    if (fallback == null) return primary;
    return SpacePlaybackExplainability(
      triggeredRule: primary.triggeredRule ?? fallback.triggeredRule,
      reason: primary.reason ?? fallback.reason,
      moodName: primary.moodName ?? fallback.moodName,
      recommendedBpmMin:
          primary.recommendedBpmMin ?? fallback.recommendedBpmMin,
      recommendedBpmMax:
          primary.recommendedBpmMax ?? fallback.recommendedBpmMax,
      recommendedBpmTarget:
          primary.recommendedBpmTarget ?? fallback.recommendedBpmTarget,
      usedMoodOnlyFallback:
          primary.usedMoodOnlyFallback ?? fallback.usedMoodOnlyFallback,
      moodOnlyCount: primary.moodOnlyCount ?? fallback.moodOnlyCount,
      bpmFilteredCount: primary.bpmFilteredCount ?? fallback.bpmFilteredCount,
      aiGenerationMode: primary.aiGenerationMode ?? fallback.aiGenerationMode,
      fuzzyProfileName: primary.fuzzyProfileName ?? fallback.fuzzyProfileName,
      fuzzyProfileTemplate:
          primary.fuzzyProfileTemplate ?? fallback.fuzzyProfileTemplate,
      restrictedToAllowedPlaylists: primary.restrictedToAllowedPlaylists ??
          fallback.restrictedToAllowedPlaylists,
      allowedPlaylistCount:
          primary.allowedPlaylistCount ?? fallback.allowedPlaylistCount,
    );
  }

  @override
  Future<Either<Failure, PairDeviceInfo>> getPairDeviceInfoForManager(
    String spaceId,
  ) async {
    try {
      final result =
          await remoteDataSource.getPairDeviceInfoForManager(spaceId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get pair device info: $e'));
    }
  }

  @override
  Future<Either<Failure, PairDeviceInfo>>
      getPairDeviceInfoForPlaybackDevice() async {
    try {
      final result =
          await remoteDataSource.getPairDeviceInfoForPlaybackDevice();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get pair device info: $e'));
    }
  }

  @override
  Future<Either<Failure, PairCodeSnapshot>> generatePairCode(
    String spaceId,
  ) async {
    try {
      final result = await remoteDataSource.generatePairCode(spaceId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to generate pair code: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> revokePairCode(String spaceId) async {
    try {
      await remoteDataSource.revokePairCode(spaceId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to revoke pair code: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> unpairDevice(String spaceId) async {
    try {
      await remoteDataSource.unpairDevice(spaceId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to unpair device: $e'));
    }
  }
}
