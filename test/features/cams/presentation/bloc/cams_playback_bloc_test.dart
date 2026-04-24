import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/enums/app_mode.dart';
import 'package:cams_store_manager/core/enums/playback_command_enum.dart';
import 'package:cams_store_manager/core/enums/queue_insert_mode_enum.dart';
import 'package:cams_store_manager/core/enums/entity_status_enum.dart';
import 'package:cams_store_manager/core/enums/space_type_enum.dart';
import 'package:cams_store_manager/core/enums/transition_type_enum.dart';
import 'package:cams_store_manager/core/enums/user_role.dart';
import 'package:cams_store_manager/core/error/failure_kind.dart';
import 'package:cams_store_manager/core/error/failures.dart';
import 'package:cams_store_manager/core/services/local_storage_service.dart';
import 'package:cams_store_manager/core/session/session_cubit.dart';
import 'package:cams_store_manager/features/cams/data/models/override_response_model.dart';
import 'package:cams_store_manager/features/cams/data/models/space_playback_state_model.dart';
import 'package:cams_store_manager/features/cams/data/repositories/cams_repository_impl.dart';
import 'package:cams_store_manager/features/cams/data/services/queue_first_playback_runtime.dart';
import 'package:cams_store_manager/features/cams/data/services/store_hub_service.dart';
import 'package:cams_store_manager/features/cams/domain/entities/pair_code_snapshot.dart';
import 'package:cams_store_manager/features/cams/domain/entities/pair_device_info.dart';
import 'package:cams_store_manager/features/cams/domain/entities/space_playback_state.dart';
import 'package:cams_store_manager/features/cams/domain/entities/space_queue_state_item.dart';
import 'package:cams_store_manager/features/cams/domain/services/cams_playback_capability_provider.dart';
import 'package:cams_store_manager/features/cams/domain/usecases/cancel_override.dart';
import 'package:cams_store_manager/features/cams/domain/usecases/get_space_state.dart';
import 'package:cams_store_manager/features/cams/domain/usecases/override_space.dart';
import 'package:cams_store_manager/features/cams/domain/usecases/queue_usecases.dart';
import 'package:cams_store_manager/features/cams/domain/usecases/send_playback_command.dart';
import 'package:cams_store_manager/features/cams/domain/usecases/update_audio_state.dart';
import 'package:cams_store_manager/features/cams/domain/usecases/update_scheduling_state.dart';
import 'package:cams_store_manager/features/cams/presentation/bloc/cams_playback_bloc.dart';
import 'package:cams_store_manager/features/cams/presentation/bloc/cams_playback_event.dart';
import 'package:cams_store_manager/features/cams/presentation/bloc/cams_playback_state.dart';
import 'package:cams_store_manager/features/moods/data/repositories/mood_repository_impl.dart';
import 'package:cams_store_manager/features/moods/domain/entities/mood.dart';
import 'package:cams_store_manager/features/moods/domain/usecases/get_moods.dart';
import 'package:cams_store_manager/features/space_control/domain/entities/space.dart';
import 'package:cams_store_manager/features/store_dashboard/domain/entities/store.dart';

void main() {
  group('CamsPlaybackBloc queue-first behavior', () {
    late _FakeCamsRepository repository;
    late _FakeMoodRepository moodRepository;
    late _FakeStoreHubService storeHubService;
    late SessionCubit sessionCubit;
    late QueueFirstPlaybackRuntime runtime;
    late CamsPlaybackBloc bloc;

    setUp(() {
      repository = _FakeCamsRepository();
      moodRepository = _FakeMoodRepository();
      storeHubService = _FakeStoreHubService();
      sessionCubit = SessionCubit(localStorage: _InMemoryLocalStorageService());
      sessionCubit.changeStore(const Store(
        id: 'store-1',
        name: 'Store 1',
        brandId: 'brand-1',
      ));
      sessionCubit.changeSpace(const Space(
        id: 'space-1',
        name: 'Space 1',
        storeId: 'store-1',
        type: SpaceTypeEnum.hall,
        status: EntityStatusEnum.active,
      ));
      runtime = QueueFirstPlaybackRuntime(
        getSpaceState: GetSpaceState(repository),
        queueTracks: QueueTracks(repository),
        queuePlaylist: QueuePlaylist(repository),
        reorderQueue: ReorderQueue(repository),
        removeQueueItems: RemoveQueueItems(repository),
        clearQueue: ClearQueue(repository),
        getSpaceQueue: GetSpaceQueue(repository),
        sendPlaybackCommand: SendPlaybackCommand(repository),
        updateAudioState: UpdateAudioState(repository),
        updateSchedulingState: UpdateSchedulingState(repository),
        storeHubService: storeHubService,
      );

      bloc = CamsPlaybackBloc(
        overrideSpace: OverrideSpace(repository),
        cancelOverride: CancelOverride(repository),
        getMoods: GetMoods(moodRepository),
        storeHubService: storeHubService,
        sessionCubit: sessionCubit,
        runtime: runtime,
      );
    });

    tearDown(() async {
      await bloc.close();
      await runtime.dispose();
      await sessionCubit.close();
      storeHubService.dispose();
    });

    test('uses queue/playlist add-to-queue flow for CamsPlayPlaylist',
        () async {
      await _initBloc(bloc);

      bloc.add(const CamsPlayPlaylist(
        playlistId: 'playlist-42',
        reason: 'Manual playlist queue request',
      ));

      await _waitUntil(() => repository.lastQueuePlaylistRequest != null);

      final request = repository.lastQueuePlaylistRequest!;
      expect(request.spaceId, 'space-1');
      expect(request.playlistId, 'playlist-42');
      expect(request.mode, QueueInsertModeEnum.addToQueue);
      expect(request.isClearExistingQueue, isFalse);
      expect(request.reason, 'Manual playlist queue request');
      expect(bloc.state.isOverriding, isFalse);
    });

    test('uses queue/tracks add-to-queue flow for CamsPlayTrack', () async {
      await _initBloc(bloc);

      bloc.add(const CamsPlayTrack(
        trackId: 'track-99',
      ));

      await _waitUntil(() => repository.lastQueueTracksRequest != null);

      final request = repository.lastQueueTracksRequest!;
      expect(request.spaceId, 'space-1');
      expect(request.trackIds, ['track-99']);
      expect(request.mode, QueueInsertModeEnum.addToQueue);
      expect(request.isClearExistingQueue, isFalse);
      expect(request.reason, 'Manual track add-to-queue request');
      expect(bloc.state.isOverriding, isFalse);
    });

    test('does not carry playback state across space switches', () async {
      await _initBloc(bloc);

      bloc.add(const CamsStateSyncReceived(
        playbackState: SpacePlaybackState(
          spaceId: 'space-1',
          currentQueueItemId: 'queue-1',
          currentTrackName: 'Track One',
          hlsUrl: 'https://stream.example.com/space-1.m3u8',
        ),
      ));
      await _nextTick();

      expect(bloc.state.playbackState?.spaceId, 'space-1');
      expect(
        bloc.state.playbackState?.hlsUrl,
        'https://stream.example.com/space-1.m3u8',
      );

      sessionCubit.changeSpace(const Space(
        id: 'space-2',
        name: 'Space 2',
        storeId: 'store-1',
        type: SpaceTypeEnum.hall,
        status: EntityStatusEnum.active,
      ));
      repository.getSpaceStateResult =
          const Right(SpacePlaybackState(spaceId: 'space-2'));

      bloc.add(const CamsInitPlayback(spaceId: 'space-2'));
      await _waitUntil(
        () =>
            bloc.state.spaceId == 'space-2' &&
            bloc.state.status != CamsStatus.loading,
      );

      expect(bloc.state.playbackState?.spaceId, 'space-2');
      expect(bloc.state.playbackState?.hlsUrl, isNull);

      bloc.add(const CamsStateSyncReceived(
        playbackState: SpacePlaybackState(
          spaceId: 'space-1',
          currentQueueItemId: 'queue-stale',
          hlsUrl: 'https://stream.example.com/stale.m3u8',
        ),
      ));
      await _nextTick();

      expect(bloc.state.spaceId, 'space-2');
      expect(bloc.state.playbackState?.spaceId, 'space-2');
      expect(bloc.state.playbackState?.hlsUrl, isNull);
    });

    test('keeps requested PlayNow for playlist queue actions', () async {
      await _initBloc(bloc);

      bloc.add(const CamsPlayPlaylist(
        playlistId: 'playlist-42',
        requestedMode: QueueInsertModeEnum.playNow,
        clearExistingQueue: true,
        reason: 'Manual playlist play request',
      ));

      await _waitUntil(() => repository.lastQueuePlaylistRequest != null);

      final request = repository.lastQueuePlaylistRequest!;
      expect(request.mode, QueueInsertModeEnum.playNow);
      expect(request.isClearExistingQueue, isTrue);
      expect(request.reason, 'Manual playlist play request');
    });

    test('honors requested PlayNow when immediate takeover capability is on',
        () async {
      final capableBloc = CamsPlaybackBloc(
        overrideSpace: OverrideSpace(repository),
        cancelOverride: CancelOverride(repository),
        getMoods: GetMoods(moodRepository),
        storeHubService: storeHubService,
        sessionCubit: sessionCubit,
        runtime: runtime,
        capabilityProvider: const StaticCamsPlaybackCapabilityProvider(
          CamsPlaybackCapabilities(
            supportsImmediateManualQueueTakeover: true,
          ),
        ),
      );
      addTearDown(capableBloc.close);

      await _initBloc(capableBloc);

      capableBloc.add(const CamsPlayTrack(
        trackId: 'track-100',
        requestedMode: QueueInsertModeEnum.playNow,
        clearExistingQueue: true,
      ));

      await _waitUntil(() => repository.lastQueueTracksRequest != null);

      final request = repository.lastQueueTracksRequest!;
      expect(request.mode, QueueInsertModeEnum.playNow);
      expect(request.isClearExistingQueue, isTrue);
      expect(request.reason, 'Manual track play-now request');
    });

    test('keeps mood override on overrideSpace with moodId only', () async {
      await _initBloc(bloc);

      bloc.add(const CamsOverrideMood(
        moodId: 'mood-chill',
        manualOverrideTtlSeconds: 1800,
        reason: 'Manual vibe test',
      ));

      await _waitUntil(() => repository.lastOverrideRequest != null);
      final request = repository.lastOverrideRequest!;

      expect(request.spaceId, 'space-1');
      expect(request.moodId, 'mood-chill');
      expect(request.trackIds, isNull);
      expect(request.playlistId, isNull);
      expect(request.manualOverrideTtlSeconds, 1800);
      expect(request.reason, 'Manual vibe test');
      expect(bloc.state.isOverriding, isFalse);
    });

    test('applies generic track override payload', () async {
      await _initBloc(bloc);

      bloc.add(const CamsApplyOverride(
        trackIds: ['track-11', 'track-12'],
        isClearManagerSelectedQueues: true,
        isCutOver: true,
        reason: 'Manual deck takeover',
      ));

      await _waitUntil(() => repository.lastOverrideRequest != null);
      final request = repository.lastOverrideRequest!;

      expect(request.spaceId, 'space-1');
      expect(request.trackIds, ['track-11', 'track-12']);
      expect(request.playlistId, isNull);
      expect(request.moodId, isNull);
      expect(request.isClearManagerSelectedQueues, isTrue);
      expect(request.isCutOver, isTrue);
      expect(request.reason, 'Manual deck takeover');
    });

    test('applies generic playlist override payload', () async {
      await _initBloc(bloc);

      bloc.add(const CamsApplyOverride(
        playlistId: 'playlist-override-1',
        reason: 'Manual playlist takeover',
      ));

      await _waitUntil(() => repository.lastOverrideRequest != null);
      final request = repository.lastOverrideRequest!;

      expect(request.trackIds, isNull);
      expect(request.playlistId, 'playlist-override-1');
      expect(request.moodId, isNull);
      expect(request.isCutOver, isFalse);
      expect(request.reason, 'Manual playlist takeover');
    });

    test(
        'hydrates authoritative queue snapshot when state sync payload is partial',
        () async {
      await _initBloc(bloc);
      repository.getQueueResult = const Right([
        SpaceQueueStateItem(
          queueItemId: 'queue-1',
          trackId: 'track-1',
          trackName: 'Track One',
          position: 1,
          queueStatus: SpacePlaybackState.queueStatusPlayed,
          source: 1,
        ),
        SpaceQueueStateItem(
          queueItemId: 'queue-2',
          trackId: 'track-2',
          trackName: 'Track Two',
          position: 2,
          queueStatus: SpacePlaybackState.queueStatusPlaying,
          source: 1,
        ),
        SpaceQueueStateItem(
          queueItemId: 'queue-3',
          trackId: 'track-3',
          trackName: 'Track Three',
          position: 3,
          queueStatus: SpacePlaybackState.queueStatusPending,
          source: 1,
        ),
      ]);

      storeHubService.emitStateSync(
        const SpacePlaybackStateModel(
          spaceId: 'space-1',
          currentQueueItemId: 'queue-2',
          pendingQueueItemId: 'queue-3',
          spaceQueueItems: [
            SpaceQueueStateItem(
              queueItemId: 'queue-2',
              trackId: 'track-2',
              trackName: 'Track Two',
              position: 1,
              queueStatus: SpacePlaybackState.queueStatusPlaying,
              source: 1,
            ),
            SpaceQueueStateItem(
              queueItemId: 'queue-3',
              trackId: 'track-3',
              trackName: 'Track Three',
              position: 2,
              queueStatus: SpacePlaybackState.queueStatusPending,
              source: 1,
            ),
          ],
        ),
      );

      await _waitUntil(
        () => (bloc.state.playbackState?.spaceQueueItems.length ?? 0) == 3,
      );

      expect(repository.getQueueCallCount, greaterThanOrEqualTo(1));
      expect(
        bloc.state.playbackState?.spaceQueueItems
            .map((item) => item.queueItemId)
            .toList(),
        ['queue-1', 'queue-2', 'queue-3'],
      );
      expect(
        bloc.state.playbackState?.spaceQueueItems.first.queueStatus,
        SpacePlaybackState.queueStatusPlayed,
      );
    });

    test('rejects generic override when multiple sources are selected',
        () async {
      await _initBloc(bloc);

      bloc.add(const CamsApplyOverride(
        trackIds: ['track-1'],
        playlistId: 'playlist-1',
      ));
      await _nextTick();

      expect(repository.lastOverrideRequest, isNull);
      expect(
        bloc.state.errorMessage,
        'Select at most one override source before applying.',
      );
    });

    test('cancels override and refreshes playback state', () async {
      repository.getSpaceStateResult = const Right(
        SpacePlaybackState(
          spaceId: 'space-1',
          isManualOverride: false,
          moodName: 'Recovered',
        ),
      );
      await _initBloc(bloc);

      bloc.add(const CamsCancelOverride());
      await _waitUntil(() => repository.cancelOverrideCallCount == 1);
      await _waitUntil(() => repository.getSpaceStateCallCount >= 2);

      expect(repository.cancelOverrideCallCount, 1);
      expect(bloc.state.isOverriding, isFalse);
      expect(bloc.state.lastOverrideResponse, isNull);
    });

    test('treats pendingQueueItemId as preparing active state', () async {
      await _initBloc(bloc);

      bloc.add(
        const CamsStateSyncReceived(
          playbackState: SpacePlaybackState(
            spaceId: 'space-1',
            pendingQueueItemId: 'queue-pending-1',
          ),
        ),
      );
      await _nextTick();

      expect(bloc.state.status, CamsStatus.active);
      expect(bloc.state.isPreparing, isTrue);
      expect(bloc.state.playbackState?.isStreaming, isFalse);
      expect(bloc.state.playbackState?.pendingQueueItemId, 'queue-pending-1');
    });

    test(
        'hydrates queue snapshot from getQueue when init state has queue identity',
        () async {
      repository.getSpaceStateResult = const Right(
        SpacePlaybackState(
          spaceId: 'space-1',
          currentQueueItemId: 'queue-2',
          hlsUrl: 'https://stream.example.com/live.m3u8',
        ),
      );
      repository.getQueueResult = const Right([
        SpaceQueueStateItem(
          queueItemId: 'queue-1',
          trackId: 'track-1',
          trackName: 'Track One',
          position: 1,
          queueStatus: 1,
          source: 1,
        ),
        SpaceQueueStateItem(
          queueItemId: 'queue-2',
          trackId: 'track-2',
          trackName: 'Track Two',
          position: 2,
          queueStatus: 1,
          source: 1,
        ),
      ]);

      bloc.add(const CamsInitPlayback(spaceId: 'space-1'));
      await _waitUntil(
        () =>
            bloc.state.status != CamsStatus.initial &&
            bloc.state.status != CamsStatus.loading,
      );

      expect(repository.getQueueCallCount, greaterThanOrEqualTo(1));
      expect(bloc.state.playbackState?.spaceQueueItems, hasLength(2));
      expect(
        bloc.state.playbackState?.spaceQueueItems.last.queueItemId,
        'queue-2',
      );
    });

    test('hydrates queue snapshot on state sync when payload omits queue list',
        () async {
      await _initBloc(bloc);
      repository.getQueueResult = const Right([
        SpaceQueueStateItem(
          queueItemId: 'queue-9',
          trackId: 'track-9',
          trackName: 'Track Nine',
          position: 1,
          queueStatus: 1,
          source: 1,
        ),
      ]);

      storeHubService.emitStateSync(
        const SpacePlaybackStateModel(
          spaceId: 'space-1',
          currentQueueItemId: 'queue-9',
          hlsUrl: 'https://stream.example.com/queue-9.m3u8',
        ),
      );
      await _waitUntil(
        () =>
            (bloc.state.playbackState?.spaceQueueItems.length ?? 0) == 1 &&
            bloc.state.playbackState?.spaceQueueItems.first.queueItemId ==
                'queue-9',
      );

      expect(repository.getQueueCallCount, greaterThanOrEqualTo(1));
      expect(bloc.state.playbackState?.spaceQueueItems, hasLength(1));
      expect(
          bloc.state.playbackState?.spaceQueueItems.first.trackId, 'track-9');
    });

    test('does not optimistically mutate for skip command without seek',
        () async {
      await _initBloc(bloc);

      bloc.add(
        const CamsStateSyncReceived(
          playbackState: SpacePlaybackState(
            spaceId: 'space-1',
            currentQueueItemId: 'queue-1',
            currentTrackName: 'Track A',
            hlsUrl: 'https://stream.example.com/current.m3u8',
            seekOffsetSeconds: 42,
          ),
        ),
      );
      await _nextTick();

      final previous = bloc.state;

      bloc.add(const CamsPlaybackCommandReceived(
        spaceId: 'space-1',
        command: PlaybackCommandEnum.skipNext,
        targetTrackId: 'track-b',
      ));
      await _nextTick();

      expect(bloc.state.commandSequence, previous.commandSequence);
      expect(bloc.state.lastPlaybackCommand, previous.lastPlaybackCommand);
      expect(bloc.state.playbackState?.currentQueueItemId, 'queue-1');
      expect(bloc.state.playbackState?.currentTrackName, 'Track A');
    });

    test('waits for SpaceStateSync after skipNext and ignores command echo',
        () async {
      const playbackState = SpacePlaybackState(
        spaceId: 'space-1',
        currentQueueItemId: 'queue-1',
        currentTrackName: 'Track One',
        hlsUrl: 'https://stream.example.com/t1.m3u8',
        spaceQueueItems: [
          SpaceQueueStateItem(
            queueItemId: 'queue-1',
            trackId: 'track-1',
            trackName: 'Track One',
            position: 1,
            queueStatus: SpacePlaybackState.queueStatusPlaying,
            source: 1,
            hlsUrl: 'https://stream.example.com/t1.m3u8',
            isReadyToStream: true,
          ),
          SpaceQueueStateItem(
            queueItemId: 'queue-2',
            trackId: 'track-2',
            trackName: 'Track Two',
            position: 2,
            queueStatus: SpacePlaybackState.queueStatusPending,
            source: 1,
            hlsUrl: 'https://stream.example.com/t2.m3u8',
            isReadyToStream: true,
          ),
          SpaceQueueStateItem(
            queueItemId: 'queue-3',
            trackId: 'track-3',
            trackName: 'Track Three',
            position: 3,
            queueStatus: SpacePlaybackState.queueStatusPending,
            source: 1,
            hlsUrl: 'https://stream.example.com/t3.m3u8',
            isReadyToStream: true,
          ),
        ],
      );
      repository.getSpaceStateResult = const Right(playbackState);
      await _initBloc(bloc);
      await _waitUntil(
        () => bloc.state.playbackState?.currentQueueItemId == 'queue-1',
      );

      bloc.add(const CamsSendCommand(
        command: PlaybackCommandEnum.skipNext,
      ));
      await _waitUntil(
        () =>
            repository.lastSendCommandRequest?.command ==
            PlaybackCommandEnum.skipNext,
      );
      await _nextTick();

      expect(bloc.state.playbackState?.currentQueueItemId, 'queue-1');
      expect(bloc.state.playbackState?.currentTrackName, 'Track One');

      storeHubService.emitPlaybackCommand(const PlaybackCommandEvent(
        spaceId: 'space-1',
        command: PlaybackCommandEnum.skipNext,
      ));
      await _nextTick();

      expect(bloc.state.playbackState?.currentQueueItemId, 'queue-1');
      expect(bloc.state.playbackState?.currentTrackName, 'Track One');

      storeHubService.emitStateSync(
        const SpacePlaybackStateModel(
          spaceId: 'space-1',
          currentQueueItemId: 'queue-2',
          currentTrackName: 'Track Two',
          hlsUrl: 'https://stream.example.com/t2.m3u8',
          spaceQueueItems: [
            SpaceQueueStateItem(
              queueItemId: 'queue-1',
              trackId: 'track-1',
              trackName: 'Track One',
              position: 1,
              queueStatus: SpacePlaybackState.queueStatusPlayed,
              source: 1,
              hlsUrl: 'https://stream.example.com/t1.m3u8',
              isReadyToStream: true,
            ),
            SpaceQueueStateItem(
              queueItemId: 'queue-2',
              trackId: 'track-2',
              trackName: 'Track Two',
              position: 2,
              queueStatus: SpacePlaybackState.queueStatusPlaying,
              source: 1,
              hlsUrl: 'https://stream.example.com/t2.m3u8',
              isReadyToStream: true,
            ),
            SpaceQueueStateItem(
              queueItemId: 'queue-3',
              trackId: 'track-3',
              trackName: 'Track Three',
              position: 3,
              queueStatus: SpacePlaybackState.queueStatusPending,
              source: 1,
              hlsUrl: 'https://stream.example.com/t3.m3u8',
              isReadyToStream: true,
            ),
          ],
        ),
      );
      await _waitUntil(
        () => bloc.state.playbackState?.currentQueueItemId == 'queue-2',
      );

      expect(bloc.state.playbackState?.currentQueueItemId, 'queue-2');
      expect(bloc.state.playbackState?.currentTrackName, 'Track Two');
    });

    test(
        'single previous tap restarts current stream and quick double tap jumps back',
        () async {
      await _initBloc(bloc);

      const playbackState = SpacePlaybackState(
        spaceId: 'space-1',
        currentQueueItemId: 'queue-2',
        currentTrackName: 'Track Two',
        hlsUrl: 'https://stream.example.com/current.m3u8',
        spaceQueueItems: [
          SpaceQueueStateItem(
            queueItemId: 'queue-1',
            trackId: 'track-1',
            trackName: 'Track One',
            position: 1,
            queueStatus: SpacePlaybackState.queueStatusPlayed,
            source: 1,
          ),
          SpaceQueueStateItem(
            queueItemId: 'queue-2',
            trackId: 'track-2',
            trackName: 'Track Two',
            position: 2,
            queueStatus: SpacePlaybackState.queueStatusPlaying,
            source: 1,
          ),
        ],
      );

      bloc.add(
        const CamsStateSyncReceived(playbackState: playbackState),
      );
      await _nextTick();

      bloc.add(const CamsPreviousTapped());
      await _waitUntil(() => repository.lastSendCommandRequest != null);

      expect(
        repository.lastSendCommandRequest?.command,
        PlaybackCommandEnum.seek,
      );
      expect(
        repository.lastSendCommandRequest?.seekPositionSeconds,
        0.001,
      );

      repository.lastSendCommandRequest = null;
      bloc.add(const CamsStateSyncReceived(playbackState: playbackState));
      await _nextTick();

      bloc.add(const CamsPreviousTapped());
      await _waitUntil(() => repository.lastSendCommandRequest != null);

      expect(
        repository.lastSendCommandRequest?.command,
        PlaybackCommandEnum.skipToTrack,
      );
      expect(
        repository.lastSendCommandRequest?.targetQueueItemId,
        'queue-1',
      );
    });

    test('waits for authoritative sync for targeted previous jump', () async {
      const playbackState = SpacePlaybackState(
        spaceId: 'space-1',
        currentQueueItemId: 'queue-2',
        currentTrackName: 'Track Two',
        hlsUrl: 'https://stream.example.com/t2.m3u8',
        spaceQueueItems: [
          SpaceQueueStateItem(
            queueItemId: 'queue-1',
            trackId: 'track-1',
            trackName: 'Track One',
            position: 1,
            queueStatus: SpacePlaybackState.queueStatusPlayed,
            source: 1,
            hlsUrl: 'https://stream.example.com/t1.m3u8',
            isReadyToStream: true,
          ),
          SpaceQueueStateItem(
            queueItemId: 'queue-2',
            trackId: 'track-2',
            trackName: 'Track Two',
            position: 2,
            queueStatus: SpacePlaybackState.queueStatusPlaying,
            source: 1,
            hlsUrl: 'https://stream.example.com/t2.m3u8',
            isReadyToStream: true,
          ),
        ],
      );
      repository.getSpaceStateResult = const Right(playbackState);
      await _initBloc(bloc);
      await _waitUntil(
        () => bloc.state.playbackState?.currentQueueItemId == 'queue-2',
      );

      bloc.add(const CamsPreviousTapped());
      await _waitUntil(
        () =>
            repository.lastSendCommandRequest?.command ==
            PlaybackCommandEnum.seek,
      );
      final relaySequenceAfterRestart = bloc.state.commandSequence;
      expect(relaySequenceAfterRestart, greaterThan(0));

      repository.lastSendCommandRequest = null;
      bloc.add(const CamsPreviousTapped());
      await _waitUntil(
        () =>
            repository.lastSendCommandRequest?.command ==
            PlaybackCommandEnum.skipToTrack,
      );

      expect(
        repository.lastSendCommandRequest?.targetQueueItemId,
        'queue-1',
      );
      await _nextTick();

      expect(bloc.state.commandSequence, relaySequenceAfterRestart);
      expect(bloc.state.playbackState?.currentQueueItemId, 'queue-2');
      expect(bloc.state.playbackState?.currentTrackName, 'Track Two');

      storeHubService.emitStateSync(
        const SpacePlaybackStateModel(
          spaceId: 'space-1',
          currentQueueItemId: 'queue-2',
          currentTrackName: 'Track Two',
          hlsUrl: 'https://stream.example.com/t2.m3u8',
          spaceQueueItems: [
            SpaceQueueStateItem(
              queueItemId: 'queue-1',
              trackId: 'track-1',
              trackName: 'Track One',
              position: 1,
              queueStatus: SpacePlaybackState.queueStatusPlayed,
              source: 1,
              hlsUrl: 'https://stream.example.com/t1.m3u8',
              isReadyToStream: true,
            ),
            SpaceQueueStateItem(
              queueItemId: 'queue-2',
              trackId: 'track-2',
              trackName: 'Track Two',
              position: 2,
              queueStatus: SpacePlaybackState.queueStatusPlaying,
              source: 1,
              hlsUrl: 'https://stream.example.com/t2.m3u8',
              isReadyToStream: true,
            ),
          ],
        ),
      );
      await _nextTick();

      expect(bloc.state.playbackState?.currentQueueItemId, 'queue-2');
      expect(bloc.state.playbackState?.currentTrackName, 'Track Two');

      storeHubService.emitStateSync(
        const SpacePlaybackStateModel(
          spaceId: 'space-1',
          currentQueueItemId: 'queue-1',
          currentTrackName: 'Track One',
          hlsUrl: 'https://stream.example.com/t1.m3u8',
          spaceQueueItems: [
            SpaceQueueStateItem(
              queueItemId: 'queue-1',
              trackId: 'track-1',
              trackName: 'Track One',
              position: 1,
              queueStatus: SpacePlaybackState.queueStatusPlaying,
              source: 1,
              hlsUrl: 'https://stream.example.com/t1.m3u8',
              isReadyToStream: true,
            ),
            SpaceQueueStateItem(
              queueItemId: 'queue-2',
              trackId: 'track-2',
              trackName: 'Track Two',
              position: 2,
              queueStatus: SpacePlaybackState.queueStatusPending,
              source: 1,
              hlsUrl: 'https://stream.example.com/t2.m3u8',
              isReadyToStream: true,
            ),
          ],
        ),
      );
      await _waitUntil(
        () => bloc.state.playbackState?.currentQueueItemId == 'queue-1',
      );

      expect(bloc.state.playbackState?.currentQueueItemId, 'queue-1');
      expect(bloc.state.playbackState?.currentTrackName, 'Track One');
    });

    test('relays pause command immediately before API acknowledgement',
        () async {
      await _initBloc(bloc);

      final previous = bloc.state;
      final sendCommandCompleter = Completer<Either<Failure, void>>();
      repository.sendCommandCompleter = sendCommandCompleter;

      bloc.add(const CamsSendCommand(
        command: PlaybackCommandEnum.pause,
      ));

      await _waitUntil(
        () => bloc.state.commandSequence == previous.commandSequence + 1,
      );

      expect(bloc.state.lastPlaybackCommand, PlaybackCommandEnum.pause);
      expect(bloc.state.lastSeekPositionSeconds, isNull);
      expect(bloc.state.lastTargetQueueItemId, isNull);
      expect(bloc.state.lastTargetTrackId, isNull);

      sendCommandCompleter.complete(const Right(null));
      await _nextTick();
    });

    test('seek command clears stale target ids from command relay', () async {
      await _initBloc(bloc);

      bloc.add(
        const CamsPlaybackCommandReceived(
          spaceId: 'space-1',
          command: PlaybackCommandEnum.seek,
          seekPositionSeconds: 128,
          targetQueueItemId: 'queue-should-not-forward',
          targetTrackId: 'track-should-not-forward',
        ),
      );
      await _nextTick();

      expect(bloc.state.lastPlaybackCommand, PlaybackCommandEnum.seek);
      expect(bloc.state.lastSeekPositionSeconds, 128);
      expect(bloc.state.lastTargetQueueItemId, isNull);
      expect(bloc.state.lastTargetTrackId, isNull);
    });

    test('play stream hint clears stale legacy playlist identity', () async {
      await _initBloc(bloc);

      bloc.add(
        const CamsStateSyncReceived(
          playbackState: SpacePlaybackState(
            spaceId: 'space-1',
            currentPlaylistId: 'playlist-legacy',
            currentPlaylistName: 'Legacy Playlist',
          ),
        ),
      );
      await _nextTick();

      bloc.add(
        const CamsPlayStreamReceived(
          spaceId: 'space-1',
          hlsUrl: 'https://stream.example.com/live.m3u8',
          currentQueueItemId: 'queue-1',
          trackName: 'Track One',
        ),
      );
      await _nextTick();

      expect(bloc.state.playbackState?.currentQueueItemId, 'queue-1');
      expect(bloc.state.playbackState?.currentTrackName, 'Track One');
      expect(bloc.state.playbackState?.currentPlaylistId, isNull);
      expect(bloc.state.playbackState?.currentPlaylistName, isNull);
    });

    test('reorders queue through queue management event', () async {
      await _initBloc(bloc);

      bloc.add(
        const CamsStateSyncReceived(
          playbackState: SpacePlaybackState(
            spaceId: 'space-1',
            spaceQueueItems: [
              SpaceQueueStateItem(
                queueItemId: 'queue-1',
                trackId: 'track-1',
                position: 1,
                queueStatus: 1,
                source: 1,
              ),
              SpaceQueueStateItem(
                queueItemId: 'queue-2',
                trackId: 'track-2',
                position: 2,
                queueStatus: 1,
                source: 1,
              ),
            ],
          ),
        ),
      );
      await _nextTick();

      bloc.add(const CamsReorderQueue(queueItemIds: ['queue-2', 'queue-1']));
      await _waitUntil(() => repository.lastReorderQueueRequest != null);

      expect(
        repository.lastReorderQueueRequest?.queueItemIds,
        ['queue-2', 'queue-1'],
      );
    });

    test('removes queue items through queue management event', () async {
      await _initBloc(bloc);

      bloc.add(
        const CamsStateSyncReceived(
          playbackState: SpacePlaybackState(
            spaceId: 'space-1',
            pendingQueueItemId: 'queue-2',
            spaceQueueItems: [
              SpaceQueueStateItem(
                queueItemId: 'queue-1',
                trackId: 'track-1',
                position: 1,
                queueStatus: 1,
                source: 1,
              ),
              SpaceQueueStateItem(
                queueItemId: 'queue-2',
                trackId: 'track-2',
                position: 2,
                queueStatus: 1,
                source: 1,
              ),
            ],
          ),
        ),
      );
      await _nextTick();

      bloc.add(const CamsRemoveQueueItems(queueItemIds: ['queue-2']));
      await _waitUntil(() => repository.lastRemoveQueueItemsRequest != null);

      expect(
        repository.lastRemoveQueueItemsRequest?.queueItemIds,
        ['queue-2'],
      );
    });

    test('clears queue through queue management event', () async {
      await _initBloc(bloc);

      bloc.add(
        const CamsStateSyncReceived(
          playbackState: SpacePlaybackState(
            spaceId: 'space-1',
            pendingQueueItemId: 'queue-1',
            spaceQueueItems: [
              SpaceQueueStateItem(
                queueItemId: 'queue-1',
                trackId: 'track-1',
                position: 1,
                queueStatus: 1,
                source: 1,
              ),
            ],
          ),
        ),
      );
      await _nextTick();

      bloc.add(const CamsClearQueue());
      await _waitUntil(() => repository.clearQueueCallCount > 0);

      expect(repository.clearQueueCallCount, 1);
    });

    test('updates audio state through state/audio endpoint', () async {
      await _initBloc(bloc);

      storeHubService.emitStateSync(
        const SpacePlaybackStateModel(
          spaceId: 'space-1',
          volumePercent: 45,
          isMuted: false,
          queueEndBehavior: 0,
        ),
      );
      await _waitUntil(() => bloc.state.playbackState?.volumePercent == 45);

      bloc.add(const CamsUpdateAudioState(
        volumePercent: 82,
        isMuted: true,
        queueEndBehavior: 2,
      ));
      await _waitUntil(() => repository.lastUpdateAudioStateRequest != null);

      final request = repository.lastUpdateAudioStateRequest!;
      expect(request.spaceId, 'space-1');
      expect(request.volumePercent, 82);
      expect(request.isMuted, isTrue);
      expect(request.queueEndBehavior, 2);
      expect(bloc.state.playbackState?.volumePercent, 82);
      expect(bloc.state.playbackState?.isMuted, isTrue);
      expect(bloc.state.playbackState?.queueEndBehavior, 2);
    });

    test(
        'uses the live manager scope for scheduling updates after playback bootstrap',
        () async {
      sessionCubit.setPlaybackMode(
        store: const Store(
          id: 'store-1',
          name: 'Store 1',
          brandId: 'brand-1',
        ),
        space: const Space(
          id: 'space-1',
          name: 'Space 1',
          storeId: 'store-1',
          type: SpaceTypeEnum.hall,
          status: EntityStatusEnum.active,
        ),
        deviceId: 'device-1',
      );

      await _initBloc(bloc);

      sessionCubit.changeAppMode(AppMode.remoteControl);
      sessionCubit.changeRole(UserRole.storeManager);

      bloc.add(const CamsUpdateSchedulingState(isScheduling: false));
      await _waitUntil(
        () => repository.lastUpdateSchedulingStateRequest != null,
      );

      final request = repository.lastUpdateSchedulingStateRequest!;
      expect(request.spaceId, 'space-1');
      expect(request.isScheduling, isFalse);
      expect(request.usePlaybackDeviceScope, isFalse);
    });

    test(
        'shows a friendly runtime-status message when scheduling enable hits active-slot business rule',
        () async {
      repository.updateSchedulingStateResult = const Left(
        ValidationFailure(
          'Scheduling mode can only be activated when there is an active space scheduling slot at the current UTC time.',
          FailureKind.business,
          'BusinessRuleViolation',
          422,
        ),
      );
      await _initBloc(bloc);

      bloc.add(const CamsUpdateSchedulingState(isScheduling: true));
      await _waitUntil(() => bloc.state.errorMessage != null);

      expect(
        bloc.state.errorMessage,
        'Runtime status cannot be turned on right now because this space has no active schedule slot for the current time.',
      );
    });

    test('refreshes playback state after SignalR reconnect', () async {
      repository.getSpaceStateResult = const Right(
        SpacePlaybackState(
          spaceId: 'space-1',
          currentTrackName: 'Before reconnect',
        ),
      );
      await _initBloc(bloc);

      expect(repository.getSpaceStateCallCount, 1);
      expect(bloc.state.playbackState?.currentTrackName, 'Before reconnect');

      repository.getSpaceStateResult = const Right(
        SpacePlaybackState(
          spaceId: 'space-1',
          currentTrackName: 'After reconnect',
          hlsUrl: 'https://stream.example.com/reconnected.m3u8',
        ),
      );

      await storeHubService.disconnect();
      await _nextTick();
      await storeHubService.connect();

      await _waitUntil(
        () =>
            repository.getSpaceStateCallCount >= 2 &&
            bloc.state.playbackState?.currentTrackName == 'After reconnect',
      );

      expect(bloc.state.playbackState?.hlsUrl,
          'https://stream.example.com/reconnected.m3u8');
      expect(bloc.state.status, CamsStatus.active);
    });

    test(
        'retries remote reconcile when pending PlayStream arrives before state catches up',
        () async {
      repository.queueSpaceStateResults([
        const Right(SpacePlaybackState(spaceId: 'space-1')),
        const Right(SpacePlaybackState(spaceId: 'space-1')),
        const Right(
          SpacePlaybackState(
            spaceId: 'space-1',
            spaceQueueItems: [
              SpaceQueueStateItem(
                queueItemId: 'queue-remote-1',
                trackId: 'track-remote-1',
                trackName: 'Remote Pending Track',
                position: 1,
                queueStatus: 0,
                source: 1,
              ),
            ],
          ),
        ),
      ]);

      await _initBloc(bloc);

      storeHubService.emitPlayStream(
        const PlayStreamEvent(
          spaceId: 'space-1',
          hlsUrl: '',
          transitionType: TransitionTypeEnum.pending,
        ),
      );

      await _waitUntil(
        () => (bloc.state.playbackState?.spaceQueueItems.length ?? 0) == 1,
        timeout: const Duration(seconds: 3),
      );

      expect(repository.getSpaceStateCallCount, greaterThanOrEqualTo(3));
      expect(
        bloc.state.playbackState?.spaceQueueItems.single.queueItemId,
        'queue-remote-1',
      );
    });
  });
}

class _InMemoryLocalStorageService extends LocalStorageService {
  final Map<String, dynamic> _settings = {};

  @override
  dynamic getSetting(String key) => _settings[key];

  @override
  Future<void> saveSetting(String key, dynamic value) async {
    _settings[key] = value;
  }

  @override
  Future<void> removeSetting(String key) async {
    _settings.remove(key);
  }
}

class _FakeStoreHubService extends StoreHubService {
  _FakeStoreHubService() : super(accessTokenFactory: () => '');

  final _playStreamController = StreamController<PlayStreamEvent>.broadcast();
  final _playbackCommandController =
      StreamController<PlaybackCommandEvent>.broadcast();
  final _stateSyncController =
      StreamController<SpacePlaybackStateModel>.broadcast();
  final _stopPlaybackController = StreamController<void>.broadcast();
  final _connectionController = StreamController<ConnectionStatus>.broadcast();
  ConnectionStatus _status = ConnectionStatus.disconnected;

  @override
  Stream<PlayStreamEvent> get onPlayStream => _playStreamController.stream;

  @override
  Stream<PlaybackCommandEvent> get onPlaybackCommand =>
      _playbackCommandController.stream;

  @override
  Stream<SpacePlaybackStateModel> get onSpaceStateSync =>
      _stateSyncController.stream;

  @override
  Stream<void> get onStopPlayback => _stopPlaybackController.stream;

  @override
  Stream<ConnectionStatus> get onConnectionStatus =>
      _connectionController.stream;

  @override
  Future<void> connect() async {
    if (_status == ConnectionStatus.connected) {
      return;
    }
    _status = ConnectionStatus.connected;
    _connectionController.add(ConnectionStatus.connected);
  }

  @override
  Future<void> disconnect() async {
    if (_status == ConnectionStatus.disconnected) {
      return;
    }
    _status = ConnectionStatus.disconnected;
    _connectionController.add(ConnectionStatus.disconnected);
  }

  @override
  Future<void> joinSpace(String spaceId) async {}

  @override
  Future<void> leaveSpace(String spaceId) async {}

  @override
  Future<void> joinManagerRoom(String storeId) async {}

  @override
  Future<void> leaveManagerRoom(String storeId) async {}

  @override
  Future<void> reportPlaybackState({
    required String spaceId,
    required bool isPlaying,
    double? positionSeconds,
    String? currentHlsUrl,
  }) async {}

  void emitStateSync(SpacePlaybackStateModel playbackState) {
    _stateSyncController.add(playbackState);
  }

  void emitPlayStream(PlayStreamEvent event) {
    _playStreamController.add(event);
  }

  void emitPlaybackCommand(PlaybackCommandEvent event) {
    _playbackCommandController.add(event);
  }

  @override
  void dispose() {
    _playStreamController.close();
    _playbackCommandController.close();
    _stateSyncController.close();
    _stopPlaybackController.close();
    _connectionController.close();
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
  Either<Failure, void> queuePlaylistResult = const Right(null);
  Either<Failure, void> queueTracksResult = const Right(null);
  Either<Failure, void> sendCommandResult = const Right(null);
  Completer<Either<Failure, void>>? sendCommandCompleter;
  Either<Failure, void> cancelOverrideResult = const Right(null);
  Either<Failure, List<SpaceQueueStateItem>> getQueueResult = const Right([]);
  Either<Failure, OverrideResponse> overrideSpaceResult = const Right(
    OverrideResponse(spaceId: 'space-1'),
  );

  _QueuePlaylistRequest? lastQueuePlaylistRequest;
  _QueueTracksRequest? lastQueueTracksRequest;
  _SendPlaybackCommandRequest? lastSendCommandRequest;
  _OverrideRequest? lastOverrideRequest;
  _ReorderQueueRequest? lastReorderQueueRequest;
  _RemoveQueueItemsRequest? lastRemoveQueueItemsRequest;
  _UpdateAudioStateRequest? lastUpdateAudioStateRequest;
  _UpdateSchedulingStateRequest? lastUpdateSchedulingStateRequest;
  Either<Failure, void> updateSchedulingStateResult = const Right(null);
  int getSpaceStateCallCount = 0;
  int getQueueCallCount = 0;
  int cancelOverrideCallCount = 0;
  int clearQueueCallCount = 0;
  final List<Either<Failure, SpacePlaybackState>> _queuedGetSpaceStateResults =
      [];

  void queueSpaceStateResults(
    List<Either<Failure, SpacePlaybackState>> results,
  ) {
    _queuedGetSpaceStateResults
      ..clear()
      ..addAll(results);
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
    lastQueuePlaylistRequest = _QueuePlaylistRequest(
      spaceId: spaceId,
      playlistId: playlistId,
      mode: mode,
      isClearExistingQueue: isClearExistingQueue,
      reason: reason,
      usePlaybackDeviceScope: usePlaybackDeviceScope,
    );
    return queuePlaylistResult;
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
    lastQueueTracksRequest = _QueueTracksRequest(
      spaceId: spaceId,
      trackIds: trackIds,
      mode: mode,
      isClearExistingQueue: isClearExistingQueue,
      reason: reason,
      usePlaybackDeviceScope: usePlaybackDeviceScope,
    );
    return queueTracksResult;
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
    lastOverrideRequest = _OverrideRequest(
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
    return overrideSpaceResult;
  }

  @override
  Future<Either<Failure, SpacePlaybackState>> getSpaceState(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  }) async {
    getSpaceStateCallCount += 1;
    final result = _queuedGetSpaceStateResults.isNotEmpty
        ? _queuedGetSpaceStateResults.removeAt(0)
        : getSpaceStateResult;
    return result.fold(
      Left.new,
      (state) => Right(
          state.spaceId.isEmpty ? SpacePlaybackState(spaceId: spaceId) : state),
    );
  }

  @override
  Future<Either<Failure, void>> cancelOverride(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  }) async {
    cancelOverrideCallCount += 1;
    return cancelOverrideResult;
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
    lastSendCommandRequest = _SendPlaybackCommandRequest(
      spaceId: spaceId,
      command: command,
      seekPositionSeconds: seekPositionSeconds,
      targetQueueItemId: targetQueueItemId,
      targetTrackId: targetTrackId,
      usePlaybackDeviceScope: usePlaybackDeviceScope,
    );
    final pendingCompleter = sendCommandCompleter;
    if (pendingCompleter != null) {
      sendCommandCompleter = null;
      return pendingCompleter.future;
    }
    return sendCommandResult;
  }

  @override
  Future<Either<Failure, void>> updateAudioState({
    required String spaceId,
    int? volumePercent,
    bool? isMuted,
    int? queueEndBehavior,
    bool usePlaybackDeviceScope = false,
  }) async {
    lastUpdateAudioStateRequest = _UpdateAudioStateRequest(
      spaceId: spaceId,
      volumePercent: volumePercent,
      isMuted: isMuted,
      queueEndBehavior: queueEndBehavior,
      usePlaybackDeviceScope: usePlaybackDeviceScope,
    );
    getSpaceStateResult = getSpaceStateResult.fold(
      Left.new,
      (state) => Right(
        SpacePlaybackState(
          spaceId: state.spaceId,
          storeId: state.storeId,
          brandId: state.brandId,
          currentQueueItemId: state.currentQueueItemId,
          currentTrackName: state.currentTrackName,
          currentPlaylistId: state.currentPlaylistId,
          currentPlaylistName: state.currentPlaylistName,
          hlsUrl: state.hlsUrl,
          moodName: state.moodName,
          isManualOverride: state.isManualOverride,
          overrideMode: state.overrideMode,
          startedAtUtc: state.startedAtUtc,
          expectedEndAtUtc: state.expectedEndAtUtc,
          isPaused: state.isPaused,
          pausePositionSeconds: state.pausePositionSeconds,
          seekOffsetSeconds: state.seekOffsetSeconds,
          pendingQueueItemId: state.pendingQueueItemId,
          pendingPlaylistId: state.pendingPlaylistId,
          pendingOverrideReason: state.pendingOverrideReason,
          volumePercent: volumePercent ?? state.volumePercent,
          isMuted: isMuted ?? state.isMuted,
          queueEndBehavior: queueEndBehavior ?? state.queueEndBehavior,
          spaceQueueItems: state.spaceQueueItems,
        ),
      ),
    );
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateSchedulingState({
    required String spaceId,
    required bool isScheduling,
    bool usePlaybackDeviceScope = false,
  }) async {
    lastUpdateSchedulingStateRequest = _UpdateSchedulingStateRequest(
      spaceId: spaceId,
      isScheduling: isScheduling,
      usePlaybackDeviceScope: usePlaybackDeviceScope,
    );
    getSpaceStateResult = getSpaceStateResult.fold(
      Left.new,
      (state) => Right(state.copyWith(isScheduling: isScheduling)),
    );
    return updateSchedulingStateResult;
  }

  @override
  Future<Either<Failure, void>> reorderQueue({
    required String spaceId,
    required List<String> queueItemIds,
    bool usePlaybackDeviceScope = false,
  }) async {
    lastReorderQueueRequest = _ReorderQueueRequest(
      spaceId: spaceId,
      queueItemIds: queueItemIds,
      usePlaybackDeviceScope: usePlaybackDeviceScope,
    );
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> removeQueueItems({
    required String spaceId,
    required List<String> queueItemIds,
    bool usePlaybackDeviceScope = false,
  }) async {
    lastRemoveQueueItemsRequest = _RemoveQueueItemsRequest(
      spaceId: spaceId,
      queueItemIds: queueItemIds,
      usePlaybackDeviceScope: usePlaybackDeviceScope,
    );
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> clearQueue({
    required String spaceId,
    bool usePlaybackDeviceScope = false,
  }) async {
    clearQueueCallCount += 1;
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<SpaceQueueStateItem>>> getQueue(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  }) async {
    getQueueCallCount += 1;
    return getQueueResult;
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
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, PairDeviceInfo>>
      getPairDeviceInfoForPlaybackDevice() async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, PairCodeSnapshot>> generatePairCode(
    String spaceId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> revokePairCode(String spaceId) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> unpairDevice(String spaceId) async {
    throw UnimplementedError();
  }
}

class _QueuePlaylistRequest {
  final String spaceId;
  final String playlistId;
  final QueueInsertModeEnum mode;
  final bool isClearExistingQueue;
  final String? reason;
  final bool usePlaybackDeviceScope;

  const _QueuePlaylistRequest({
    required this.spaceId,
    required this.playlistId,
    required this.mode,
    required this.isClearExistingQueue,
    required this.reason,
    required this.usePlaybackDeviceScope,
  });
}

class _QueueTracksRequest {
  final String spaceId;
  final List<String> trackIds;
  final QueueInsertModeEnum mode;
  final bool isClearExistingQueue;
  final String? reason;
  final bool usePlaybackDeviceScope;

  const _QueueTracksRequest({
    required this.spaceId,
    required this.trackIds,
    required this.mode,
    required this.isClearExistingQueue,
    required this.reason,
    required this.usePlaybackDeviceScope,
  });
}

class _OverrideRequest {
  final String spaceId;
  final List<String>? trackIds;
  final String? playlistId;
  final String? moodId;
  final bool? isClearManagerSelectedQueues;
  final bool? isCutOver;
  final int? manualOverrideTtlSeconds;
  final String? reason;
  final bool usePlaybackDeviceScope;

  const _OverrideRequest({
    required this.spaceId,
    required this.trackIds,
    required this.playlistId,
    required this.moodId,
    required this.isClearManagerSelectedQueues,
    required this.isCutOver,
    required this.manualOverrideTtlSeconds,
    required this.reason,
    required this.usePlaybackDeviceScope,
  });
}

class _SendPlaybackCommandRequest {
  const _SendPlaybackCommandRequest({
    required this.spaceId,
    required this.command,
    required this.seekPositionSeconds,
    required this.targetQueueItemId,
    required this.targetTrackId,
    required this.usePlaybackDeviceScope,
  });

  final String spaceId;
  final PlaybackCommandEnum command;
  final double? seekPositionSeconds;
  final String? targetQueueItemId;
  final String? targetTrackId;
  final bool usePlaybackDeviceScope;
}

class _ReorderQueueRequest {
  final String spaceId;
  final List<String> queueItemIds;
  final bool usePlaybackDeviceScope;

  const _ReorderQueueRequest({
    required this.spaceId,
    required this.queueItemIds,
    required this.usePlaybackDeviceScope,
  });
}

class _RemoveQueueItemsRequest {
  final String spaceId;
  final List<String> queueItemIds;
  final bool usePlaybackDeviceScope;

  const _RemoveQueueItemsRequest({
    required this.spaceId,
    required this.queueItemIds,
    required this.usePlaybackDeviceScope,
  });
}

class _UpdateAudioStateRequest {
  final String spaceId;
  final int? volumePercent;
  final bool? isMuted;
  final int? queueEndBehavior;
  final bool usePlaybackDeviceScope;

  const _UpdateAudioStateRequest({
    required this.spaceId,
    required this.volumePercent,
    required this.isMuted,
    required this.queueEndBehavior,
    required this.usePlaybackDeviceScope,
  });
}

class _UpdateSchedulingStateRequest {
  const _UpdateSchedulingStateRequest({
    required this.spaceId,
    required this.isScheduling,
    required this.usePlaybackDeviceScope,
  });

  final String spaceId;
  final bool isScheduling;
  final bool usePlaybackDeviceScope;
}

Future<void> _nextTick() {
  return Future<void>.delayed(const Duration(milliseconds: 40));
}

Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for condition');
    }
    await _nextTick();
  }
}

Future<void> _initBloc(CamsPlaybackBloc bloc) async {
  bloc.add(const CamsInitPlayback(spaceId: 'space-1'));
  await _waitUntil(
    () =>
        bloc.state.spaceId == 'space-1' &&
        bloc.state.status != CamsStatus.initial &&
        bloc.state.status != CamsStatus.loading,
  );
}
