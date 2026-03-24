import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/enums/entity_status_enum.dart';
import 'package:cams_store_manager/core/enums/playback_command_enum.dart';
import 'package:cams_store_manager/core/enums/queue_insert_mode_enum.dart';
import 'package:cams_store_manager/core/enums/space_type_enum.dart';
import 'package:cams_store_manager/core/error/failures.dart';
import 'package:cams_store_manager/core/models/pagination_result.dart';
import 'package:cams_store_manager/core/services/local_storage_service.dart';
import 'package:cams_store_manager/core/session/session_cubit.dart';
import 'package:cams_store_manager/features/auth/domain/entities/user.dart';
import 'package:cams_store_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:cams_store_manager/features/auth/domain/usecases/change_password.dart';
import 'package:cams_store_manager/features/auth/domain/usecases/get_current_user.dart';
import 'package:cams_store_manager/features/auth/domain/usecases/login.dart';
import 'package:cams_store_manager/features/auth/domain/usecases/logout.dart';
import 'package:cams_store_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cams_store_manager/features/cams/data/models/override_response_model.dart';
import 'package:cams_store_manager/features/cams/data/models/space_playback_state_model.dart';
import 'package:cams_store_manager/features/cams/data/repositories/cams_repository_impl.dart';
import 'package:cams_store_manager/features/cams/data/services/store_hub_service.dart';
import 'package:cams_store_manager/features/cams/domain/entities/pair_code_snapshot.dart';
import 'package:cams_store_manager/features/cams/domain/entities/pair_device_info.dart';
import 'package:cams_store_manager/features/cams/domain/entities/space_playback_state.dart';
import 'package:cams_store_manager/features/cams/domain/entities/space_queue_state_item.dart';
import 'package:cams_store_manager/features/cams/domain/usecases/get_space_state.dart';
import 'package:cams_store_manager/features/cams/domain/usecases/pairing_usecases.dart';
import 'package:cams_store_manager/features/locations/domain/entities/location_space.dart';
import 'package:cams_store_manager/features/locations/domain/repositories/location_repository.dart';
import 'package:cams_store_manager/features/locations/domain/usecases/location_usecases.dart';
import 'package:cams_store_manager/features/locations/presentation/bloc/location_bloc.dart';
import 'package:cams_store_manager/features/locations/presentation/bloc/location_event.dart';
import 'package:cams_store_manager/features/locations/presentation/bloc/location_state.dart';
import 'package:cams_store_manager/features/playlists/data/datasources/playlist_remote_datasource.dart';
import 'package:cams_store_manager/features/playlists/data/models/api_playlist_model.dart';
import 'package:cams_store_manager/features/store_dashboard/domain/entities/store.dart';
import 'package:cams_store_manager/features/store_selection/domain/entities/store_summary.dart';
import 'package:cams_store_manager/features/store_selection/domain/repositories/store_selection_repository.dart';
import 'package:cams_store_manager/features/store_selection/domain/usecases/get_user_stores.dart';

void main() {
  group('LocationBloc queue-first playback mapping', () {
    late SessionCubit sessionCubit;
    late AuthBloc authBloc;
    late _FakeLocationRepository locationRepository;
    late _FakeCamsRepository camsRepository;
    late _FakeStoreSelectionRepository storeSelectionRepository;
    late _FakePlaylistRemoteDataSource playlistDataSource;
    late _FakeStoreHubService storeHubService;
    late LocationBloc bloc;

    setUp(() {
      sessionCubit = SessionCubit(localStorage: _InMemoryLocalStorageService());
      sessionCubit.changeStore(const Store(
        id: 'store-1',
        name: 'Store One',
        brandId: 'brand-1',
      ));

      authBloc = AuthBloc(
        login: Login(_FakeAuthRepository()),
        logout: Logout(_FakeAuthRepository()),
        getCurrentUser: GetCurrentUser(_FakeAuthRepository()),
        changePassword: ChangePassword(_FakeAuthRepository()),
        sessionCubit: sessionCubit,
      );

      locationRepository = _FakeLocationRepository(
        spacesByStoreId: {
          'store-1': const [
            LocationSpace(
              id: 'space-1',
              name: 'Space One',
              storeId: 'store-1',
              type: SpaceTypeEnum.hall,
              status: EntityStatusEnum.active,
            ),
          ],
        },
      );
      camsRepository = _FakeCamsRepository(
        spaceStateBySpaceId: {
          'space-1': const SpacePlaybackState(
            spaceId: 'space-1',
            storeId: 'store-1',
          ),
        },
      );
      storeSelectionRepository = _FakeStoreSelectionRepository();
      playlistDataSource = _FakePlaylistRemoteDataSource();
      storeHubService = _FakeStoreHubService();

      bloc = LocationBloc(
        sessionCubit: sessionCubit,
        authBloc: authBloc,
        getPairedSpace: GetPairedSpace(locationRepository),
        getSpacesForStore: GetSpacesForStore(locationRepository),
        getSpacesForBrand: GetSpacesForBrand(locationRepository),
        getSpaceState: GetSpaceState(camsRepository),
        getPairDeviceInfoForManager:
            GetPairDeviceInfoForManager(camsRepository),
        getPairDeviceInfoForPlaybackDevice:
            GetPairDeviceInfoForPlaybackDevice(camsRepository),
        generatePairCode: GeneratePairCode(camsRepository),
        revokePairCode: RevokePairCode(camsRepository),
        unpairPlaybackDevice: UnpairPlaybackDevice(camsRepository),
        playlistDataSource: playlistDataSource,
        getUserStores: GetUserStores(storeSelectionRepository),
        storeHubService: storeHubService,
      );
    });

    tearDown(() async {
      await bloc.close();
      await authBloc.close();
      await sessionCubit.close();
      storeHubService.dispose();
    });

    test('maps current track from queue item id when syncing playback state',
        () async {
      bloc.add(const LoadLocationsRequested());
      await _waitUntil(() => bloc.state.status == LocationStatus.success);

      bloc.add(
        const LocationPlaybackStateSynced(
          SpacePlaybackState(
            spaceId: 'space-1',
            storeId: 'store-1',
            currentQueueItemId: 'queue-1',
            hlsUrl: 'https://stream.example.com/live.m3u8',
            spaceQueueItems: [
              SpaceQueueStateItem(
                queueItemId: 'queue-1',
                trackId: 'track-1',
                trackName: 'Queue Track',
                position: 1,
                queueStatus: 1,
                source: 1,
              ),
            ],
          ),
        ),
      );

      await _waitUntil(
        () => _firstStoreSpace(bloc).currentTrackName == 'Queue Track',
      );

      final updated = _firstStoreSpace(bloc);
      expect(updated.currentTrackName, 'Queue Track');
      expect(updated.currentPlaylistName, 'Queue Track');
      expect(updated.hasActivePlayback, isTrue);
      expect(updated.hasLivePlayback, isTrue);
    });

    test('falls back to queueStatus=playing when currentQueueItemId is missing',
        () async {
      bloc.add(const LoadLocationsRequested());
      await _waitUntil(() => bloc.state.status == LocationStatus.success);

      bloc.add(
        const LocationPlaybackStateSynced(
          SpacePlaybackState(
            spaceId: 'space-1',
            storeId: 'store-1',
            hlsUrl: 'https://stream.example.com/live.m3u8',
            spaceQueueItems: [
              SpaceQueueStateItem(
                queueItemId: 'queue-2',
                trackId: 'track-2',
                trackName: 'Fallback Queue Track',
                position: 2,
                queueStatus: 1,
                source: 1,
              ),
            ],
          ),
        ),
      );

      await _waitUntil(
        () => _firstStoreSpace(bloc).currentTrackName == 'Fallback Queue Track',
      );

      final updated = _firstStoreSpace(bloc);
      expect(updated.currentTrackName, 'Fallback Queue Track');
      expect(updated.currentPlaylistName, 'Fallback Queue Track');
      expect(updated.hasActivePlayback, isTrue);
    });
  });
}

LocationSpace _firstStoreSpace(LocationBloc bloc) {
  final spaces = bloc.state.storeSpaces?.items;
  expect(spaces, isNotNull);
  expect(spaces, isNotEmpty);
  return spaces!.first;
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

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    return const Left(CacheFailure('no auth in unit test'));
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    return const Right(false);
  }

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    return const Left(ServerFailure('not used in this test'));
  }

  @override
  Future<Either<Failure, void>> logout() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, User>> refreshToken() async {
    return const Left(ServerFailure('not used in this test'));
  }
}

class _FakeLocationRepository implements LocationRepository {
  _FakeLocationRepository({
    required this.spacesByStoreId,
  });

  final Map<String, List<LocationSpace>> spacesByStoreId;

  @override
  Future<Either<Failure, LocationSpace>> getPairedSpace(
    String spaceId,
    String storeId,
  ) async {
    final spaces = spacesByStoreId[storeId] ?? const [];
    for (final space in spaces) {
      if (space.id == spaceId) return Right(space);
    }
    return const Left(ServerFailure('Space not found'));
  }

  @override
  Future<Either<Failure, Map<String, PaginationResult<LocationSpace>>>>
      getSpacesForBrand(
    List<String> storeIds, {
    int page = 1,
    int pageSize = 10,
  }) async {
    final map = <String, PaginationResult<LocationSpace>>{};
    for (final storeId in storeIds) {
      final spaces = spacesByStoreId[storeId] ?? const [];
      map[storeId] = PaginationResult<LocationSpace>(
        currentPage: 1,
        pageSize: spaces.length,
        totalItems: spaces.length,
        totalPages: 1,
        hasPrevious: false,
        hasNext: false,
        items: spaces,
      );
    }
    return Right(map);
  }

  @override
  Future<Either<Failure, PaginationResult<LocationSpace>>> getSpacesForStore(
    String storeId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    final spaces = spacesByStoreId[storeId] ?? const [];
    return Right(
      PaginationResult<LocationSpace>(
        currentPage: 1,
        pageSize: spaces.length,
        totalItems: spaces.length,
        totalPages: 1,
        hasPrevious: false,
        hasNext: false,
        items: spaces,
      ),
    );
  }
}

class _FakeStoreSelectionRepository implements StoreSelectionRepository {
  @override
  Future<Either<Failure, List<StoreSummary>>> getUserStores() async {
    return const Right([]);
  }
}

class _FakePlaylistRemoteDataSource implements PlaylistRemoteDataSource {
  @override
  Future<void> addTracksToPlaylist({
    required String playlistId,
    required List<String> trackIds,
  }) async {}

  @override
  Future<ApiPlaylistModel> getPlaylistById(String playlistId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    return ApiPlaylistModel.fromDetailJson({
      'id': playlistId,
      'name': 'Playlist $playlistId',
      'status': 1,
      'trackCount': 0,
      'createdAt': now,
      'tracks': const [],
    });
  }

  @override
  Future<PlaylistListResponse> getPlaylists({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? storeId,
    String? moodId,
    bool? isDynamic,
    bool? isDefault,
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
  Future<void> joinManagerRoom(String storeId) async {}

  @override
  Future<void> leaveManagerRoom(String storeId) async {}

  @override
  Future<void> joinSpace(String spaceId) async {}

  @override
  Future<void> leaveSpace(String spaceId) async {}

  @override
  void dispose() {
    _playStreamController.close();
    _playbackCommandController.close();
    _stateSyncController.close();
    _stopPlaybackController.close();
    _connectionController.close();
  }
}

class _FakeCamsRepository implements CamsRepository {
  _FakeCamsRepository({
    required this.spaceStateBySpaceId,
  });

  final Map<String, SpacePlaybackState> spaceStateBySpaceId;

  @override
  Future<Either<Failure, SpacePlaybackState>> getSpaceState(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  }) async {
    final state = spaceStateBySpaceId[spaceId];
    if (state == null) {
      return Right(SpacePlaybackState(spaceId: spaceId));
    }
    return Right(state);
  }

  @override
  Future<Either<Failure, PairDeviceInfo>> getPairDeviceInfoForManager(
    String spaceId,
  ) async {
    return const Left(ServerFailure('No paired device'));
  }

  @override
  Future<Either<Failure, PairDeviceInfo>>
      getPairDeviceInfoForPlaybackDevice() async {
    return const Left(ServerFailure('No paired device'));
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
  Future<Either<Failure, List<SpaceQueueStateItem>>> getQueue(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  }) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, SpacePlaybackState>>
      getSpaceStateForPlaybackDevice() async {
    return const Left(ServerFailure('not used in this test'));
  }
}
