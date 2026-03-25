import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

import 'package:cams_store_manager/core/audio/audio_player_service.dart';
import 'package:cams_store_manager/core/audio/playback_notification_service.dart';
import 'package:cams_store_manager/core/enums/entity_status_enum.dart';
import 'package:cams_store_manager/core/enums/playback_command_enum.dart';
import 'package:cams_store_manager/core/enums/queue_insert_mode_enum.dart';
import 'package:cams_store_manager/core/enums/space_type_enum.dart';
import 'package:cams_store_manager/core/error/failures.dart';
import 'package:cams_store_manager/core/player/player_bloc.dart';
import 'package:cams_store_manager/core/player/player_state.dart' as ps;
import 'package:cams_store_manager/core/presentation/app_playback_coordinator.dart';
import 'package:cams_store_manager/core/services/local_storage_service.dart';
import 'package:cams_store_manager/core/session/session_cubit.dart';
import 'package:cams_store_manager/features/cams/data/models/override_response_model.dart';
import 'package:cams_store_manager/features/cams/data/models/space_playback_state_model.dart';
import 'package:cams_store_manager/features/cams/data/repositories/cams_repository_impl.dart';
import 'package:cams_store_manager/features/cams/data/services/store_hub_service.dart';
import 'package:cams_store_manager/features/cams/domain/entities/pair_code_snapshot.dart';
import 'package:cams_store_manager/features/cams/domain/entities/pair_device_info.dart';
import 'package:cams_store_manager/features/cams/domain/entities/space_playback_state.dart';
import 'package:cams_store_manager/features/cams/domain/entities/space_queue_state_item.dart';
import 'package:cams_store_manager/features/cams/domain/usecases/cancel_override.dart';
import 'package:cams_store_manager/features/cams/domain/usecases/get_space_state.dart';
import 'package:cams_store_manager/features/cams/domain/usecases/override_space.dart';
import 'package:cams_store_manager/features/cams/domain/usecases/queue_usecases.dart';
import 'package:cams_store_manager/features/cams/domain/usecases/send_playback_command.dart';
import 'package:cams_store_manager/features/cams/domain/usecases/update_audio_state.dart';
import 'package:cams_store_manager/features/cams/presentation/bloc/cams_playback_bloc.dart';
import 'package:cams_store_manager/features/cams/presentation/bloc/cams_playback_event.dart';
import 'package:cams_store_manager/features/moods/data/repositories/mood_repository_impl.dart';
import 'package:cams_store_manager/features/moods/domain/entities/mood.dart';
import 'package:cams_store_manager/features/moods/domain/usecases/get_moods.dart';
import 'package:cams_store_manager/features/playlists/data/datasources/playlist_remote_datasource.dart';
import 'package:cams_store_manager/features/playlists/data/models/api_playlist_model.dart';
import 'package:cams_store_manager/features/space_control/domain/entities/space.dart';
import 'package:cams_store_manager/features/store_dashboard/domain/entities/store.dart';
import 'package:cams_store_manager/injection_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppPlaybackCoordinator queue-first orchestration', () {
    late _FakeAudioPlayerService audioService;
    late _FakePlaybackNotificationService notificationService;
    late SessionCubit sessionCubit;
    late _FakeCamsRepository camsRepository;
    late _FakeMoodRepository moodRepository;
    late _FakeStoreHubService storeHubService;
    late _FakePlaylistRemoteDataSource playlistDataSource;
    late PlayerBloc playerBloc;
    late _ManualCamsPlaybackBloc camsBloc;

    setUp(() {
      audioService = _FakeAudioPlayerService();
      notificationService = _FakePlaybackNotificationService();
      sessionCubit = SessionCubit(localStorage: _InMemoryLocalStorageService());
      camsRepository = _FakeCamsRepository();
      moodRepository = _FakeMoodRepository();
      storeHubService = _FakeStoreHubService();
      playlistDataSource = _FakePlaylistRemoteDataSource();
      playerBloc = PlayerBloc(audioPlayerService: audioService);
      camsBloc = _ManualCamsPlaybackBloc(
        getSpaceState: GetSpaceState(camsRepository),
        overrideSpace: OverrideSpace(camsRepository),
        cancelOverride: CancelOverride(camsRepository),
        sendPlaybackCommand: SendPlaybackCommand(camsRepository),
        queueTracks: QueueTracks(camsRepository),
        queuePlaylist: QueuePlaylist(camsRepository),
        reorderQueue: ReorderQueue(camsRepository),
        removeQueueItems: RemoveQueueItems(camsRepository),
        clearQueue: ClearQueue(camsRepository),
        getSpaceQueue: GetSpaceQueue(camsRepository),
        updateAudioState: UpdateAudioState(camsRepository),
        getMoods: GetMoods(moodRepository),
        storeHubService: storeHubService,
        sessionCubit: sessionCubit,
      );

      if (sl.isRegistered<PlaylistRemoteDataSource>()) {
        sl.unregister<PlaylistRemoteDataSource>();
      }
      sl.registerSingleton<PlaylistRemoteDataSource>(playlistDataSource);

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
    });

    tearDown(() async {
      if (sl.isRegistered<PlaylistRemoteDataSource>()) {
        sl.unregister<PlaylistRemoteDataSource>();
      }
      await playerBloc.close();
      await camsBloc.close();
      await sessionCubit.close();
      await audioService.dispose();
      notificationService.dispose();
      storeHubService.dispose();
    });

    testWidgets(
        'hydrates player queue from spaceQueueItems and currentQueueItemId',
        (tester) async {
      addTearDown(() async {
        await _disposeHarness(tester);
      });
      const playbackState = SpacePlaybackState(
        spaceId: 'space-1',
        storeId: 'store-1',
        hlsUrl: 'https://stream.example.com/live.m3u8',
        currentQueueItemId: 'queue-2',
        currentTrackName: 'Track Two',
        volumePercent: 70,
        isMuted: false,
        spaceQueueItems: [
          SpaceQueueStateItem(
            queueItemId: 'queue-1',
            trackId: 'track-1',
            trackName: 'Track One',
            position: 1,
            queueStatus: 2,
            source: 1,
            hlsUrl: 'https://stream.example.com/t1.m3u8',
            isReadyToStream: true,
          ),
          SpaceQueueStateItem(
            queueItemId: 'queue-2',
            trackId: 'track-2',
            trackName: 'Track Two',
            position: 2,
            queueStatus: 1,
            source: 1,
            hlsUrl: 'https://stream.example.com/t2.m3u8',
            isReadyToStream: true,
          ),
        ],
      );

      await _pumpCoordinator(
          tester, notificationService, sessionCubit, playerBloc, camsBloc);
      camsBloc.seed(playbackState);
      await tester.pump();

      await _waitUntil(tester, () => playerBloc.state.queue.length == 2);

      expect(playerBloc.state.isSyncedCamsPlayback, isTrue);
      expect(playerBloc.state.playlistId, isNull);
      expect(playerBloc.state.currentTrackId, 'track-2');
      expect(playerBloc.state.currentQueueItemId, 'queue-2');
      expect(playerBloc.state.queue.first.id, 'track-1');
      expect(playerBloc.state.queue.last.id, 'track-2');
      expect(audioService.lastSetVolume, closeTo(0.7, 0.0001));
    });

    testWidgets(
        'keeps queue-first HLS playback synthetic when queue snapshot is empty',
        (tester) async {
      addTearDown(() async {
        await _disposeHarness(tester);
      });
      const playbackState = SpacePlaybackState(
        spaceId: 'space-1',
        storeId: 'store-1',
        currentPlaylistId: 'playlist-legacy',
        currentPlaylistName: 'Legacy Playlist',
        hlsUrl: 'https://stream.example.com/legacy.m3u8',
        seekOffsetSeconds: 45,
      );

      await _pumpCoordinator(
          tester, notificationService, sessionCubit, playerBloc, camsBloc);
      camsBloc.seed(playbackState);
      await tester.pump();

      await _waitUntil(
          tester,
          () =>
              playerBloc.state.isSyncedCamsPlayback &&
              playerBloc.state.currentTrack != null);

      expect(playlistDataSource.getPlaylistByIdCallCount, 0);
      expect(playerBloc.state.playlistId, isNull);
      expect(playerBloc.state.queue, isEmpty);
      expect(playerBloc.state.currentTrack?.id, 'space-1');
      expect(playerBloc.state.currentTrack?.title, 'Legacy Playlist');
    });

    testWidgets(
        'applies volume and mute updates from state sync to player audio',
        (tester) async {
      addTearDown(() async {
        await _disposeHarness(tester);
      });
      const initialPlaybackState = SpacePlaybackState(
        spaceId: 'space-1',
        storeId: 'store-1',
        hlsUrl: 'https://stream.example.com/live.m3u8',
        currentQueueItemId: 'queue-1',
        volumePercent: 60,
        isMuted: false,
        spaceQueueItems: [
          SpaceQueueStateItem(
            queueItemId: 'queue-1',
            trackId: 'track-1',
            trackName: 'Track One',
            position: 1,
            queueStatus: 1,
            source: 1,
          ),
        ],
      );
      const mutedPlaybackState = SpacePlaybackState(
        spaceId: 'space-1',
        storeId: 'store-1',
        hlsUrl: 'https://stream.example.com/live.m3u8',
        currentQueueItemId: 'queue-1',
        volumePercent: 60,
        isMuted: true,
        spaceQueueItems: [
          SpaceQueueStateItem(
            queueItemId: 'queue-1',
            trackId: 'track-1',
            trackName: 'Track One',
            position: 1,
            queueStatus: 1,
            source: 1,
          ),
        ],
      );

      await _pumpCoordinator(
          tester, notificationService, sessionCubit, playerBloc, camsBloc);
      camsBloc.seed(initialPlaybackState);
      await tester.pump();
      await _waitUntil(tester, () => audioService.lastSetVolume != null);
      expect(audioService.lastSetVolume, closeTo(0.6, 0.0001));

      camsBloc.seed(mutedPlaybackState);
      await tester.pump();

      await _waitUntil(tester, () => audioService.lastSetVolume == 0.0);
      expect(playerBloc.state.currentQueueItemId, 'queue-1');
    });

    testWidgets('does not stop player when sync is pending next queue item',
        (tester) async {
      addTearDown(() async {
        await _disposeHarness(tester);
      });
      const streamingPlaybackState = SpacePlaybackState(
        spaceId: 'space-1',
        storeId: 'store-1',
        hlsUrl: 'https://stream.example.com/live.m3u8',
        currentQueueItemId: 'queue-1',
        currentTrackName: 'Track One',
        volumePercent: 100,
        isMuted: false,
        spaceQueueItems: [
          SpaceQueueStateItem(
            queueItemId: 'queue-1',
            trackId: 'track-1',
            trackName: 'Track One',
            position: 1,
            queueStatus: 1,
            source: 1,
          ),
        ],
      );
      const pendingPlaybackState = SpacePlaybackState(
        spaceId: 'space-1',
        storeId: 'store-1',
        pendingQueueItemId: 'queue-2',
      );

      await _pumpCoordinator(
          tester, notificationService, sessionCubit, playerBloc, camsBloc);
      camsBloc.seed(streamingPlaybackState);
      await tester.pump();
      await _waitUntil(tester, () => playerBloc.state.isSyncedCamsPlayback);
      final hlsBeforePending = playerBloc.state.hlsUrl;

      camsBloc.seed(pendingPlaybackState);
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 120));

      expect(playerBloc.state.isSyncedCamsPlayback, isTrue);
      expect(playerBloc.state.hlsUrl, hlsBeforePending);
    });
  });
}

Future<void> _pumpCoordinator(
  WidgetTester tester,
  _FakePlaybackNotificationService notificationService,
  SessionCubit sessionCubit,
  PlayerBloc playerBloc,
  CamsPlaybackBloc camsBloc,
) async {
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PlaybackNotificationService>.value(
          value: notificationService,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: sessionCubit),
          BlocProvider<PlayerBloc>.value(value: playerBloc),
          BlocProvider<CamsPlaybackBloc>.value(value: camsBloc),
        ],
        child: const MaterialApp(
          home: AppPlaybackCoordinator(
            child: SizedBox.shrink(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 40));
}

Future<void> _disposeHarness(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

ApiPlaylistModel _buildLegacyPlaylist(String playlistId) {
  return ApiPlaylistModel.fromDetailJson({
    'id': playlistId,
    'name': 'Legacy Playlist',
    'status': 1,
    'trackCount': 2,
    'totalDurationSeconds': 300,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    'tracks': const [
      {
        'trackId': 'track-legacy-1',
        'title': 'Legacy One',
        'artist': 'Legacy Artist',
        'seekOffsetSeconds': 0,
        'durationSeconds': 150,
      },
      {
        'trackId': 'track-legacy-2',
        'title': 'Legacy Two',
        'artist': 'Legacy Artist',
        'seekOffsetSeconds': 150,
        'durationSeconds': 150,
      },
    ],
  });
}

Future<void> _waitUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for condition');
    }
    await tester.pump(const Duration(milliseconds: 40));
  }
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

class _FakePlaybackNotificationService implements PlaybackNotificationService {
  final _commandsController =
      StreamController<PlaybackNotificationCommand>.broadcast();

  ps.PlayerState lastState = const ps.PlayerState();
  bool? lastEnabled;
  int syncCalls = 0;
  int clearCalls = 0;

  @override
  Stream<PlaybackNotificationCommand> get commands =>
      _commandsController.stream;

  @override
  void syncPlayerState(
    ps.PlayerState playerState, {
    required bool enabled,
  }) {
    lastState = playerState;
    lastEnabled = enabled;
    syncCalls += 1;
  }

  @override
  Future<void> clear() async {
    clearCalls += 1;
  }

  @override
  Future<void> dispose() async {
    await _commandsController.close();
  }
}

class _FakeAudioPlayerService extends AudioPlayerService {
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _processingController = StreamController<ProcessingState>.broadcast();
  final _playerStateController = StreamController<PlayerState>.broadcast();

  String? _loadedUrl;
  Duration _position = Duration.zero;
  ProcessingState _processingState = ProcessingState.idle;
  double? lastSetVolume;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Stream<ProcessingState> get processingStateStream =>
      _processingController.stream;

  @override
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  @override
  Duration get position => _position;

  @override
  Duration get bufferedPosition => Duration.zero;

  @override
  ProcessingState get processingState => _processingState;

  @override
  String? get loadedUrl => _loadedUrl;

  @override
  Future<Duration?> loadUrl(String url) async {
    _loadedUrl = url;
    _processingState = ProcessingState.ready;
    return null;
  }

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {
    _loadedUrl = null;
    _position = Duration.zero;
  }

  @override
  Future<void> seek(Duration position) async {
    _position = position;
  }

  @override
  Future<void> setVolume(double volume) async {
    lastSetVolume = volume;
  }

  @override
  Future<void> dispose() async {
    await _positionController.close();
    await _durationController.close();
    await _processingController.close();
    await _playerStateController.close();
  }
}

class _FakeMoodRepository implements MoodRepository {
  @override
  Future<Either<Failure, List<Mood>>> getMoods() async {
    return const Right([]);
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
    _connectionController.add(ConnectionStatus.connected);
  }

  @override
  Future<void> disconnect() async {
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

  @override
  void dispose() {
    _playStreamController.close();
    _playbackCommandController.close();
    _stateSyncController.close();
    _stopPlaybackController.close();
    _connectionController.close();
  }
}

class _FakePlaylistRemoteDataSource implements PlaylistRemoteDataSource {
  final Map<String, ApiPlaylistModel> playlistById = {};
  int getPlaylistByIdCallCount = 0;

  @override
  Future<PlaylistMutationResult> addTracksToPlaylist({
    required String playlistId,
    required List<String> trackIds,
  }) async {
    return const PlaylistMutationResult(isSuccess: true);
  }

  @override
  Future<ApiPlaylistModel> getPlaylistById(String playlistId) async {
    getPlaylistByIdCallCount += 1;
    final playlist = playlistById[playlistId];
    if (playlist != null) return playlist;

    return _buildLegacyPlaylist(playlistId);
  }

  @override
  Future<PlaylistListResponse> getPlaylists({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? sortBy,
    bool? isAscending,
    int? status,
    String? brandId,
    String? storeId,
    String? moodId,
    bool? isDynamic,
    bool? isDefault,
    DateTime? createdFrom,
    DateTime? createdTo,
  }) async {
    return PlaylistListResponse(
      items: const [],
      currentPage: 1,
      totalPages: 1,
      totalItems: 0,
      hasNext: false,
      hasPrevious: false,
    );
  }

  @override
  Future<PlaylistMutationResult> createPlaylist(
    PlaylistMutationRequest request,
  ) async {
    return const PlaylistMutationResult(isSuccess: true);
  }

  @override
  Future<PlaylistMutationResult> updatePlaylist(
    String playlistId,
    PlaylistMutationRequest request,
  ) async {
    return const PlaylistMutationResult(isSuccess: true);
  }

  @override
  Future<PlaylistMutationResult> deletePlaylist(String playlistId) async {
    return const PlaylistMutationResult(isSuccess: true);
  }

  @override
  Future<PlaylistMutationResult> togglePlaylistStatus(String playlistId) async {
    return const PlaylistMutationResult(isSuccess: true);
  }

  @override
  Future<PlaylistMutationResult> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    return const PlaylistMutationResult(isSuccess: true);
  }

  @override
  Future<PlaylistMutationResult> retranscodePlaylist(String playlistId) async {
    return const PlaylistMutationResult(isSuccess: true);
  }
}

class _ManualCamsPlaybackBloc extends CamsPlaybackBloc {
  _ManualCamsPlaybackBloc({
    required super.getSpaceState,
    required super.overrideSpace,
    required super.cancelOverride,
    required super.sendPlaybackCommand,
    required super.queueTracks,
    required super.queuePlaylist,
    required super.reorderQueue,
    required super.removeQueueItems,
    required super.clearQueue,
    required super.getSpaceQueue,
    required super.updateAudioState,
    required super.getMoods,
    required super.storeHubService,
    required super.sessionCubit,
  });

  void seed(SpacePlaybackState playbackState) {
    emit(
      state.copyWith(
        spaceId: playbackState.spaceId,
        playbackState: playbackState,
      ),
    );
  }

  @override
  void add(CamsPlaybackEvent event) {
    // Ignore coordinator-triggered events in this harness.
  }
}

class _FakeCamsRepository implements CamsRepository {
  Either<Failure, SpacePlaybackState> getSpaceStateResult =
      const Right(SpacePlaybackState(spaceId: 'space-1'));

  @override
  Future<Either<Failure, SpacePlaybackState>> getSpaceState(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  }) async {
    return getSpaceStateResult.fold(
      Left.new,
      (state) => Right(
        state.spaceId.isEmpty ? SpacePlaybackState(spaceId: spaceId) : state,
      ),
    );
  }

  @override
  Future<Either<Failure, SpacePlaybackState>>
      getSpaceStateForPlaybackDevice() async {
    return getSpaceState('', usePlaybackDeviceScope: true);
  }

  @override
  Future<Either<Failure, List<SpaceQueueStateItem>>> getQueue(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  }) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, OverrideResponse>> overrideSpace({
    required String spaceId,
    List<String>? trackIds,
    String? playlistId,
    String? moodId,
    bool? isClearManagerSelectedQueues,
    String? reason,
    bool usePlaybackDeviceScope = false,
  }) async {
    return Right(OverrideResponse(spaceId: spaceId));
  }

  @override
  Future<Either<Failure, void>> cancelOverride(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> sendPlaybackCommand({
    required String spaceId,
    required PlaybackCommandEnum command,
    double? seekPositionSeconds,
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
