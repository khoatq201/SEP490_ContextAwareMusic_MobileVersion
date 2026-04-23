import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/enums/playback_command_enum.dart';
import 'package:cams_store_manager/core/enums/queue_insert_mode_enum.dart';
import 'package:cams_store_manager/core/error/failures.dart';
import 'package:cams_store_manager/features/cams/data/models/override_response_model.dart';
import 'package:cams_store_manager/features/cams/data/repositories/cams_repository_impl.dart';
import 'package:cams_store_manager/features/cams/domain/entities/pair_code_snapshot.dart';
import 'package:cams_store_manager/features/cams/domain/entities/pair_device_info.dart';
import 'package:cams_store_manager/features/cams/domain/entities/space_playback_state.dart';
import 'package:cams_store_manager/features/cams/domain/entities/space_queue_state_item.dart';
import 'package:cams_store_manager/features/cams/domain/usecases/cancel_override.dart';
import 'package:cams_store_manager/features/cams/domain/usecases/get_space_state.dart';
import 'package:cams_store_manager/features/cams/domain/usecases/override_space.dart';
import 'package:cams_store_manager/features/home/domain/entities/category_entity.dart';
import 'package:cams_store_manager/features/home/domain/entities/sensor_entity.dart';
import 'package:cams_store_manager/features/home/domain/repositories/home_repository.dart';
import 'package:cams_store_manager/features/home/presentation/bloc/home_cubit.dart';
import 'package:cams_store_manager/features/moods/data/repositories/mood_repository_impl.dart';
import 'package:cams_store_manager/features/moods/domain/entities/mood.dart';
import 'package:cams_store_manager/features/moods/domain/usecases/get_moods.dart';

void main() {
  group('HomeCubit queue-first behavior', () {
    late _FakeHomeRepository homeRepository;
    late _FakeCamsRepository camsRepository;
    late _FakeMoodRepository moodRepository;
    late HomeCubit cubit;

    setUp(() {
      homeRepository = _FakeHomeRepository();
      camsRepository = _FakeCamsRepository();
      moodRepository = _FakeMoodRepository();

      cubit = HomeCubit(
        homeRepository,
        getSpaceState: GetSpaceState(camsRepository),
        getMoods: GetMoods(moodRepository),
        overrideSpace: OverrideSpace(camsRepository),
        cancelOverride: CancelOverride(camsRepository),
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('loadSpacePlaybackState prefers currentTrackName over playlist name',
        () async {
      camsRepository.getSpaceStateResult = const Right(
        SpacePlaybackState(
          spaceId: 'space-1',
          moodName: 'Chill',
          currentTrackName: 'Queue Track',
          currentPlaylistName: 'Legacy Playlist',
          hlsUrl: 'https://stream.example.com/live.m3u8',
        ),
      );

      await cubit.loadSpacePlaybackState('space-1');

      expect(cubit.state.activeSpaceId, 'space-1');
      expect(cubit.state.currentMoodName, 'Chill');
      expect(cubit.state.currentPlaybackName, 'Queue Track');
      expect(cubit.state.currentPlaylistName, 'Queue Track');
      expect(cubit.state.isStreaming, isTrue);
      expect(cubit.state.isPendingTranscode, isFalse);
    });

    test('loadSpacePlaybackState falls back to explainability mood name',
        () async {
      const explainability = SpacePlaybackExplainability(
        moodName: 'Focus',
        triggeredRule: 'Crowd pressure',
        reason: 'Steady daytime traffic',
      );
      camsRepository.getSpaceStateResult = const Right(
        SpacePlaybackState(
          spaceId: 'space-1',
          currentTrackName: 'AI Queue Track',
          explainability: explainability,
        ),
      );

      await cubit.loadSpacePlaybackState('space-1');

      expect(cubit.state.currentMoodName, 'Focus');
      expect(cubit.state.explainability, explainability);
    });

    test('syncForSpace(null) clears active playback labels', () async {
      camsRepository.getSpaceStateResult = const Right(
        SpacePlaybackState(
          spaceId: 'space-1',
          moodName: 'Focus',
          currentTrackName: 'Track Before Clear',
          hlsUrl: 'https://stream.example.com/live.m3u8',
        ),
      );
      await cubit.loadSpacePlaybackState('space-1');
      expect(cubit.state.currentPlaybackName, 'Track Before Clear');

      await cubit.syncForSpace(null);

      expect(cubit.state.activeSpaceId, isNull);
      expect(cubit.state.currentMoodName, isNull);
      expect(cubit.state.currentPlaybackName, isNull);
      expect(cubit.state.isManualOverride, isFalse);
      expect(cubit.state.isPendingTranscode, isFalse);
    });

    test(
        'selectAutoMode refreshes AI explainability again when only manual picker was open',
        () async {
      camsRepository.getSpaceStateResults = [
        const Right(
          SpacePlaybackState(
            spaceId: 'space-1',
            currentTrackName: 'Auto Track',
            explainability: SpacePlaybackExplainability(
              moodName: 'Chill',
              triggeredRule: 'Baseline',
            ),
          ),
        ),
      ];
      await cubit.loadSpacePlaybackState('space-1');
      cubit.openManualSelection();

      camsRepository.getSpaceStateResults = [
        const Right(
          SpacePlaybackState(
            spaceId: 'space-1',
            currentTrackName: 'Auto Track',
            explainability: SpacePlaybackExplainability(
              moodName: 'Focus',
              triggeredRule: 'Traffic',
              reason: 'Guests returned',
            ),
          ),
        ),
      ];

      await cubit.selectAutoMode();

      expect(camsRepository.getSpaceStateCallCount, greaterThanOrEqualTo(2));
      expect(cubit.state.isManualSelectionOpen, isFalse);
      expect(cubit.state.currentMoodName, 'Focus');
      expect(cubit.state.explainability?.triggeredRule, 'Traffic');
    });

    test(
        'syncFromRuntimePlaybackState keeps manual picker open while hydrating live explainability',
        () async {
      await cubit.loadSpacePlaybackState('space-1');
      cubit.openManualSelection();
      expect(cubit.state.isManualSelectionOpen, isTrue);

      cubit.syncFromRuntimePlaybackState(
        const SpacePlaybackState(
          spaceId: 'space-1',
          currentTrackName: 'Live AI Track',
          explainability: SpacePlaybackExplainability(
            moodName: 'Energetic',
            triggeredRule: 'Rush hour',
            reason: 'Traffic picked up',
          ),
        ),
      );

      expect(cubit.state.isManualSelectionOpen, isTrue);
      expect(cubit.state.currentMoodName, 'Energetic');
      expect(cubit.state.currentPlaybackName, 'Live AI Track');
      expect(cubit.state.explainability?.triggeredRule, 'Rush hour');
    });

    test(
        'syncFromRuntimePlaybackState preserves richer explainability when runtime snapshot only keeps mood',
        () async {
      await cubit.loadSpacePlaybackState('space-1');
      cubit.syncFromRuntimePlaybackState(
        const SpacePlaybackState(
          spaceId: 'space-1',
          currentTrackName: 'Seed Track',
          explainability: SpacePlaybackExplainability(
            moodName: 'Focus',
            triggeredRule: 'Floor occupancy',
            reason: 'Lunch buildup',
            recommendedBpmMin: 85,
            recommendedBpmMax: 105,
            recommendedBpmTarget: 95,
            fuzzyProfileName: 'L1 Override',
          ),
        ),
      );

      cubit.syncFromRuntimePlaybackState(
        const SpacePlaybackState(
          spaceId: 'space-1',
          currentTrackName: 'Live Track',
          moodName: 'Focus',
        ),
      );

      expect(cubit.state.currentMoodName, 'Focus');
      expect(cubit.state.currentPlaybackName, 'Live Track');
      expect(cubit.state.explainability?.triggeredRule, 'Floor occupancy');
      expect(cubit.state.explainability?.recommendedBpmTarget, 95);
      expect(cubit.state.explainability?.fuzzyProfileName, 'L1 Override');
    });

    test('selectAutoMode retries space-state refresh until auto mood returns',
        () async {
      camsRepository.getSpaceStateResults = [
        const Right(
          SpacePlaybackState(
            spaceId: 'space-1',
            isManualOverride: true,
          ),
        ),
      ];
      await cubit.loadSpacePlaybackState('space-1');

      camsRepository.getSpaceStateResults = [
        const Right(
          SpacePlaybackState(
            spaceId: 'space-1',
            isManualOverride: true,
          ),
        ),
        const Right(
          SpacePlaybackState(
            spaceId: 'space-1',
            currentTrackName: 'Recovered Auto Track',
            explainability: SpacePlaybackExplainability(
              moodName: 'Energetic',
              triggeredRule: 'Peak hour',
            ),
          ),
        ),
      ];

      await cubit.selectAutoMode();

      expect(camsRepository.cancelOverrideCallCount, 1);
      expect(camsRepository.getSpaceStateCallCount, greaterThanOrEqualTo(2));
      expect(cubit.state.isManualOverride, isFalse);
      expect(cubit.state.currentMoodName, 'Energetic');
      expect(cubit.state.explainability?.triggeredRule, 'Peak hour');
    });

    test('applyMoodOverride forwards required manual override ttl seconds',
        () async {
      await cubit.loadSpacePlaybackState('space-1');

      await cubit.applyMoodOverride(
        'mood-1',
        manualOverrideTtlSeconds: 1800,
        isCutOver: true,
      );

      expect(camsRepository.lastOverrideSpaceId, 'space-1');
      expect(camsRepository.lastOverrideMoodId, 'mood-1');
      expect(camsRepository.lastManualOverrideTtlSeconds, 1800);
      expect(camsRepository.lastIsCutOver, isTrue);
    });
  });
}

class _FakeHomeRepository implements HomeRepository {
  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<SensorEntity>>> getSensorData({
    String? storeId,
    String? spaceId,
  }) async {
    return const Right([]);
  }
}

class _FakeMoodRepository implements MoodRepository {
  Either<Failure, List<Mood>> result = const Right([]);

  @override
  Future<Either<Failure, List<Mood>>> getMoods() async => result;
}

class _FakeCamsRepository implements CamsRepository {
  Either<Failure, SpacePlaybackState> getSpaceStateResult =
      const Right(SpacePlaybackState(spaceId: 'space-1'));
  List<Either<Failure, SpacePlaybackState>> getSpaceStateResults = [];
  int getSpaceStateCallCount = 0;
  int cancelOverrideCallCount = 0;
  String? lastOverrideSpaceId;
  String? lastOverrideMoodId;
  int? lastManualOverrideTtlSeconds;
  bool? lastIsCutOver;

  @override
  Future<Either<Failure, SpacePlaybackState>> getSpaceState(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  }) async {
    getSpaceStateCallCount += 1;
    if (getSpaceStateResults.isNotEmpty) {
      return getSpaceStateResults.removeAt(0);
    }
    return getSpaceStateResult;
  }

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
    lastOverrideSpaceId = spaceId;
    lastOverrideMoodId = moodId;
    lastManualOverrideTtlSeconds = manualOverrideTtlSeconds;
    lastIsCutOver = isCutOver;
    return Right(OverrideResponse(spaceId: spaceId));
  }

  @override
  Future<Either<Failure, void>> cancelOverride(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  }) async {
    cancelOverrideCallCount += 1;
    return const Right(null);
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
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateAudioState({
    required String spaceId,
    int? volumePercent,
    bool? isMuted,
    int? queueEndBehavior,
    bool usePlaybackDeviceScope = false,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateSchedulingState({
    required String spaceId,
    required bool isScheduling,
    bool usePlaybackDeviceScope = false,
  }) async {
    return const Right(null);
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
    return const Right(null);
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
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> reorderQueue({
    required String spaceId,
    required List<String> queueItemIds,
    bool usePlaybackDeviceScope = false,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> removeQueueItems({
    required String spaceId,
    required List<String> queueItemIds,
    bool usePlaybackDeviceScope = false,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> clearQueue({
    required String spaceId,
    bool usePlaybackDeviceScope = false,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<SpaceQueueStateItem>>> getQueue(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  }) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, SpacePlaybackState>>
      getSpaceStateForPlaybackDevice() async {
    return getSpaceState('', usePlaybackDeviceScope: true);
  }

  @override
  Future<Either<Failure, PairDeviceInfo>> getPairDeviceInfoForManager(
    String spaceId,
  ) async {
    return const Left(ServerFailure('not used in this test'));
  }

  @override
  Future<Either<Failure, PairDeviceInfo>>
      getPairDeviceInfoForPlaybackDevice() async {
    return const Left(ServerFailure('not used in this test'));
  }

  @override
  Future<Either<Failure, PairCodeSnapshot>> generatePairCode(
    String spaceId,
  ) async {
    return const Left(ServerFailure('not used in this test'));
  }

  @override
  Future<Either<Failure, void>> revokePairCode(String spaceId) async {
    return const Left(ServerFailure('not used in this test'));
  }

  @override
  Future<Either<Failure, void>> unpairDevice(String spaceId) async {
    return const Left(ServerFailure('not used in this test'));
  }
}
