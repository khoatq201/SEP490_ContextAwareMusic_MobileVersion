import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/pagination_result.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../cams/data/services/store_hub_service.dart';
import '../../../cams/domain/entities/pair_code_snapshot.dart';
import '../../../cams/domain/entities/pair_device_info.dart';
import '../../../cams/domain/entities/space_playback_state.dart';
import '../../../cams/domain/usecases/get_space_state.dart';
import '../../../cams/domain/usecases/pairing_usecases.dart';
import '../../../playlists/data/datasources/playlist_remote_datasource.dart';
import '../../../playlists/domain/entities/api_playlist.dart';
import '../../../playlists/domain/entities/playlist_track_item.dart';
import '../../../store_selection/domain/entities/store_summary.dart';
import '../../../store_selection/domain/usecases/get_user_stores.dart';
import '../../domain/entities/location_space.dart';
import '../../domain/usecases/location_usecases.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final SessionCubit sessionCubit;
  final AuthBloc authBloc;
  final GetPairedSpace getPairedSpace;
  final GetSpacesForStore getSpacesForStore;
  final GetSpacesForBrand getSpacesForBrand;
  final GetSpaceState getSpaceState;
  final GetPairDeviceInfoForManager getPairDeviceInfoForManager;
  final GetPairDeviceInfoForPlaybackDevice getPairDeviceInfoForPlaybackDevice;
  final GeneratePairCode generatePairCode;
  final RevokePairCode revokePairCode;
  final UnpairPlaybackDevice unpairPlaybackDevice;
  final PlaylistRemoteDataSource playlistDataSource;
  final GetUserStores getUserStores;
  final StoreHubService storeHubService;

  final Map<String, ApiPlaylist> _playlistCache = <String, ApiPlaylist>{};
  StreamSubscription<SpacePlaybackState>? _stateSyncSub;
  StreamSubscription<ConnectionStatus>? _connectionSub;
  String? _joinedManagerStoreId;

  LocationBloc({
    required this.sessionCubit,
    required this.authBloc,
    required this.getPairedSpace,
    required this.getSpacesForStore,
    required this.getSpacesForBrand,
    required this.getSpaceState,
    required this.getPairDeviceInfoForManager,
    required this.getPairDeviceInfoForPlaybackDevice,
    required this.generatePairCode,
    required this.revokePairCode,
    required this.unpairPlaybackDevice,
    required this.playlistDataSource,
    required this.getUserStores,
    required this.storeHubService,
  }) : super(const LocationState()) {
    on<LoadLocationsRequested>(_onLoadLocationsRequested);
    on<LocationSelectedStoreChanged>(_onSelectedStoreChanged);
    on<LocationGeneratePairCodeRequested>(_onGeneratePairCodeRequested);
    on<LocationRevokePairCodeRequested>(_onRevokePairCodeRequested);
    on<LocationUnpairDeviceRequested>(_onUnpairDeviceRequested);
    on<LocationPlaybackStateSynced>(_onPlaybackStateSynced);

    _subscribeToHub();
  }

  bool get _isBrandScopedUser {
    final user = authBloc.state.user;
    return user?.isBrandManager == true || user?.isSystemAdmin == true;
  }

  Future<void> _onLoadLocationsRequested(
    LoadLocationsRequested event,
    Emitter<LocationState> emit,
  ) async {
    emit(state.copyWith(
      status: LocationStatus.loading,
      clearError: true,
    ));

    final session = sessionCubit.state;
    debugPrint(
      '[LocationBloc] isBrandScopedUser=$_isBrandScopedUser, isPlaybackDevice=${session.isPlaybackDevice}',
    );

    if (session.isPlaybackDevice) {
      await _loadPlaybackDeviceLocation(emit);
      return;
    }

    if (_isBrandScopedUser) {
      await _loadBrandLocations(emit);
      return;
    }

    await _loadStoreLocations(emit);
  }

  Future<void> _loadPlaybackDeviceLocation(Emitter<LocationState> emit) async {
    final session = sessionCubit.state;
    if (session.currentSpace == null || session.currentStore == null) {
      emit(state.copyWith(
        status: LocationStatus.failure,
        errorMessage: 'Device not properly paired',
      ));
      return;
    }

    final result = await getPairedSpace(
      session.currentSpace!.id,
      session.currentStore!.id,
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        status: LocationStatus.failure,
        errorMessage: failure.message,
      )),
      (space) async {
        final enriched = await _enrichSpaces(
          [space],
          storeNamesById: {
            session.currentStore!.id: session.currentStore!.name,
          },
          usePlaybackDeviceScope: true,
          includeManagerPairInfo: false,
        );

        PairDeviceInfo? pairInfo;
        final pairInfoResult = await getPairDeviceInfoForPlaybackDevice();
        pairInfoResult.fold(
          (_) => null,
          (value) => pairInfo = value,
        );

        final resolvedSpace = (enriched.isNotEmpty ? enriched.first : space)
            .copyWith(pairDeviceInfo: pairInfo);

        emit(state.copyWith(
          status: LocationStatus.success,
          pairedSpace: resolvedSpace,
          storeNamesById: {
            session.currentStore!.id: session.currentStore!.name,
          },
          selectedStoreId: session.currentStore!.id,
        ));
      },
    );
  }

  Future<void> _loadBrandLocations(Emitter<LocationState> emit) async {
    final storesResult = await getUserStores();
    final stores = storesResult.fold<List<StoreSummary>>(
      (_) => const [],
      (items) => items,
    );
    final storeNamesById = {
      for (final store in stores) store.id: store.name,
    };
    final storeIdsForBrand = stores.map((store) => store.id).toList();

    if (storeIdsForBrand.isEmpty) {
      emit(state.copyWith(
        status: LocationStatus.failure,
        errorMessage: 'No stores available for this brand',
      ));
      return;
    }

    final result = await getSpacesForBrand(
      storeIdsForBrand,
      page: 1,
      pageSize: 50,
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        status: LocationStatus.failure,
        errorMessage: failure.message,
      )),
      (brandSpacesMap) async {
        final enriched = await _enrichBrandSpaces(
          brandSpacesMap,
          storeNamesById: storeNamesById,
        );
        final selectedStoreId = _resolveSelectedStoreId(
          availableStoreIds: enriched.keys.toList(),
          currentStoreId: sessionCubit.state.currentStore?.id,
        );

        emit(state.copyWith(
          status: LocationStatus.success,
          brandSpaces: enriched,
          storeNamesById: storeNamesById,
          selectedStoreId: selectedStoreId,
        ));

        await _syncManagerRoomForStore(selectedStoreId);
      },
    );
  }

  Future<void> _loadStoreLocations(Emitter<LocationState> emit) async {
    final session = sessionCubit.state;
    if (session.currentStore == null) {
      emit(state.copyWith(
        status: LocationStatus.failure,
        errorMessage: 'No store selected',
      ));
      return;
    }

    final result = await getSpacesForStore(
      session.currentStore!.id,
      page: 1,
      pageSize: 50,
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        status: LocationStatus.failure,
        errorMessage: failure.message,
      )),
      (spacesPagination) async {
        final enrichedItems = await _enrichSpaces(
          spacesPagination.items,
          storeNamesById: {
            session.currentStore!.id: session.currentStore!.name,
          },
        );

        emit(state.copyWith(
          status: LocationStatus.success,
          storeSpaces: PaginationResult<LocationSpace>(
            currentPage: spacesPagination.currentPage,
            pageSize: spacesPagination.pageSize,
            totalItems: spacesPagination.totalItems,
            totalPages: spacesPagination.totalPages,
            hasPrevious: spacesPagination.hasPrevious,
            hasNext: spacesPagination.hasNext,
            items: enrichedItems,
          ),
          storeNamesById: {
            session.currentStore!.id: session.currentStore!.name,
          },
          selectedStoreId: session.currentStore!.id,
        ));

        await _syncManagerRoomForStore(session.currentStore!.id);
      },
    );
  }

  Future<void> _onSelectedStoreChanged(
    LocationSelectedStoreChanged event,
    Emitter<LocationState> emit,
  ) async {
    if (event.storeId == state.selectedStoreId) return;
    emit(state.copyWith(selectedStoreId: event.storeId));
    await _syncManagerRoomForStore(event.storeId);
  }

  Future<void> _onGeneratePairCodeRequested(
    LocationGeneratePairCodeRequested event,
    Emitter<LocationState> emit,
  ) async {
    emit(_withSpaceBusy(state, event.spaceId, true));

    final result = await generatePairCode(event.spaceId);
    await result.fold(
      (failure) async {
        emit(_withSpaceBusy(
          state.copyWith(errorMessage: failure.message),
          event.spaceId,
          false,
        ));
      },
      (snapshot) async {
        var nextState = _replaceSpaceInState(
          state,
          event.spaceId,
          (space) => space.copyWith(
            activePairCode: snapshot,
            clearPairDeviceInfo: false,
          ),
        );
        nextState = _withSpaceBusy(nextState, event.spaceId, false);
        emit(nextState);

        await _refreshPairInfoForSpace(
          spaceId: event.spaceId,
          emit: emit,
          activePairCode: snapshot,
        );
      },
    );
  }

  Future<void> _onRevokePairCodeRequested(
    LocationRevokePairCodeRequested event,
    Emitter<LocationState> emit,
  ) async {
    emit(_withSpaceBusy(state, event.spaceId, true));

    final result = await revokePairCode(event.spaceId);
    await result.fold(
      (failure) async {
        emit(_withSpaceBusy(
          state.copyWith(errorMessage: failure.message),
          event.spaceId,
          false,
        ));
      },
      (_) async {
        var nextState = _replaceSpaceInState(
          state,
          event.spaceId,
          (space) => space.copyWith(clearActivePairCode: true),
        );
        nextState = _withSpaceBusy(nextState, event.spaceId, false);
        emit(nextState);

        await _refreshPairInfoForSpace(
          spaceId: event.spaceId,
          emit: emit,
        );
      },
    );
  }

  Future<void> _onUnpairDeviceRequested(
    LocationUnpairDeviceRequested event,
    Emitter<LocationState> emit,
  ) async {
    emit(_withSpaceBusy(state, event.spaceId, true));

    final result = await unpairPlaybackDevice(event.spaceId);
    await result.fold(
      (failure) async {
        emit(_withSpaceBusy(
          state.copyWith(errorMessage: failure.message),
          event.spaceId,
          false,
        ));
      },
      (_) async {
        emit(
          _withSpaceBusy(
            _replaceSpaceInState(
              state,
              event.spaceId,
              (space) => space.copyWith(
                clearPairDeviceInfo: true,
                clearActivePairCode: true,
              ),
            ),
            event.spaceId,
            false,
          ),
        );

        await _refreshPairInfoForSpace(
          spaceId: event.spaceId,
          emit: emit,
        );
      },
    );
  }

  Future<void> _onPlaybackStateSynced(
    LocationPlaybackStateSynced event,
    Emitter<LocationState> emit,
  ) async {
    final currentStoreId =
        state.selectedStoreId ?? sessionCubit.state.currentStore?.id;
    if (currentStoreId == null ||
        event.playbackState.storeId == null ||
        event.playbackState.storeId != currentStoreId) {
      return;
    }

    final currentSpace = _findSpaceById(event.playbackState.spaceId);
    if (currentSpace == null) return;

    await _warmPlaylistCache(
      {
        if (event.playbackState.currentPlaylistId != null &&
            event.playbackState.currentPlaylistId!.isNotEmpty)
          event.playbackState.currentPlaylistId!,
      },
    );

    final updatedSpace = _applyPlaybackSnapshot(
      currentSpace,
      event.playbackState,
      _playlistCache,
    );

    emit(_replaceSpaceInState(
      state,
      currentSpace.id,
      (_) => updatedSpace,
    ));
  }

  void _subscribeToHub() {
    _stateSyncSub?.cancel();
    _connectionSub?.cancel();

    _stateSyncSub = storeHubService.onSpaceStateSync.listen((playbackState) {
      add(LocationPlaybackStateSynced(playbackState));
    });

    _connectionSub = storeHubService.onConnectionStatus.listen((status) {
      if (status == ConnectionStatus.connected &&
          _joinedManagerStoreId != null &&
          !sessionCubit.state.isPlaybackDevice) {
        add(const LoadLocationsRequested());
      }
    });
  }

  Future<void> _syncManagerRoomForStore(String? storeId) async {
    if (sessionCubit.state.isPlaybackDevice ||
        storeId == null ||
        storeId.isEmpty) {
      return;
    }

    try {
      await storeHubService.connect();
      if (_joinedManagerStoreId != null && _joinedManagerStoreId != storeId) {
        await storeHubService.leaveManagerRoom(_joinedManagerStoreId!);
      }
      if (_joinedManagerStoreId != storeId) {
        await storeHubService.joinManagerRoom(storeId);
        _joinedManagerStoreId = storeId;
      }
    } catch (_) {
      // Best effort only; screen can still work from REST snapshots.
    }
  }

  Future<Map<String, PaginationResult<LocationSpace>>> _enrichBrandSpaces(
    Map<String, PaginationResult<LocationSpace>> brandSpacesMap, {
    Map<String, String> storeNamesById = const {},
  }) async {
    final allSpaces =
        brandSpacesMap.values.expand((page) => page.items).toList();
    final enrichedSpaces = await _enrichSpaces(
      allSpaces,
      storeNamesById: storeNamesById,
    );
    final enrichedById = {for (final space in enrichedSpaces) space.id: space};

    return brandSpacesMap.map((storeId, pagination) {
      return MapEntry(
        storeId,
        PaginationResult<LocationSpace>(
          currentPage: pagination.currentPage,
          pageSize: pagination.pageSize,
          totalItems: pagination.totalItems,
          totalPages: pagination.totalPages,
          hasPrevious: pagination.hasPrevious,
          hasNext: pagination.hasNext,
          items: pagination.items
              .map((space) => enrichedById[space.id] ?? space)
              .toList(),
        ),
      );
    });
  }

  Future<List<LocationSpace>> _enrichSpaces(
    List<LocationSpace> spaces, {
    Map<String, String> storeNamesById = const {},
    bool usePlaybackDeviceScope = false,
    bool includeManagerPairInfo = true,
  }) async {
    if (spaces.isEmpty) return spaces;

    final playbackEntries = await Future.wait(
      spaces.map((space) async {
        final result = await getSpaceState(
          space.id,
          usePlaybackDeviceScope: usePlaybackDeviceScope,
        );
        return result.fold<MapEntry<String, SpacePlaybackState?>>(
          (_) => MapEntry(space.id, null),
          (playbackState) => MapEntry(space.id, playbackState),
        );
      }),
    );

    final playbackBySpaceId = {
      for (final entry in playbackEntries) entry.key: entry.value,
    };

    final pairEntries = includeManagerPairInfo
        ? await Future.wait(
            spaces.map((space) async {
              final result = await getPairDeviceInfoForManager(space.id);
              return result.fold<MapEntry<String, PairDeviceInfo?>>(
                (_) => MapEntry(space.id, null),
                (pairInfo) => MapEntry(space.id, pairInfo),
              );
            }),
          )
        : const <MapEntry<String, PairDeviceInfo?>>[];

    final pairInfoBySpaceId = {
      for (final entry in pairEntries) entry.key: entry.value,
    };

    await _warmPlaylistCache(
      playbackBySpaceId.values
          .whereType<SpacePlaybackState>()
          .map((state) => state.currentPlaylistId)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet(),
    );

    return spaces.map((space) {
      final baseSpace = storeNamesById.containsKey(space.storeId)
          ? space.copyWith(storeName: storeNamesById[space.storeId])
          : space;
      final updated = _applyPlaybackSnapshot(
        baseSpace,
        playbackBySpaceId[space.id],
        _playlistCache,
      );
      return updated.copyWith(pairDeviceInfo: pairInfoBySpaceId[space.id]);
    }).toList();
  }

  Future<void> _warmPlaylistCache(Set<String> playlistIds) async {
    final missingIds =
        playlistIds.where((id) => !_playlistCache.containsKey(id));
    final playlistEntries = await Future.wait(
      missingIds.map((playlistId) async {
        try {
          final playlist = await playlistDataSource.getPlaylistById(playlistId);
          return MapEntry<String, ApiPlaylist?>(playlistId, playlist);
        } catch (_) {
          return MapEntry<String, ApiPlaylist?>(playlistId, null);
        }
      }),
    );

    for (final entry in playlistEntries) {
      if (entry.value != null) {
        _playlistCache[entry.key] = entry.value!;
      }
    }
  }

  LocationSpace _applyPlaybackSnapshot(
    LocationSpace space,
    SpacePlaybackState? playbackState,
    Map<String, ApiPlaylist> playlistCache,
  ) {
    if (playbackState == null) return space;
    if (!playbackState.isStreaming && !playbackState.hasPendingPlayback) {
      return space.copyWith(
        currentPlaylistId: playbackState.currentPlaylistId,
        currentPlaylistName:
            playbackState.currentTrackName ?? playbackState.currentPlaylistName,
        currentMoodName: playbackState.moodName,
        clearCurrentPlaylistId: playbackState.currentPlaylistId == null,
        clearCurrentPlaylistName: (playbackState.currentTrackName ??
                playbackState.currentPlaylistName) ==
            null,
        clearCurrentMoodName: playbackState.moodName == null,
        clearCurrentTrackName: true,
        clearCurrentTrackArtist: true,
      );
    }

    final playlist = playbackState.currentPlaylistId != null
        ? playlistCache[playbackState.currentPlaylistId!]
        : null;
    final currentTrack = _resolveCurrentTrack(
      playlist,
      playbackState.effectiveSeekOffset,
    );

    return space.copyWith(
      currentPlaylistId:
          playbackState.currentPlaylistId ?? space.currentPlaylistId,
      currentPlaylistName: playbackState.currentTrackName ??
          playbackState.currentPlaylistName ??
          playlist?.name ??
          space.currentPlaylistName,
      currentMoodName:
          playbackState.moodName ?? playlist?.moodName ?? space.currentMoodName,
      currentTrackName: playbackState.currentTrackName ?? currentTrack?.title,
      currentTrackArtist: currentTrack?.artist,
    );
  }

  PlaylistTrackItem? _resolveCurrentTrack(
    ApiPlaylist? playlist,
    double? seekOffsetSeconds,
  ) {
    final tracks = playlist?.tracks;
    if (tracks == null || tracks.isEmpty) return null;
    if (seekOffsetSeconds == null) return tracks.first;

    var activeTrack = tracks.first;
    for (final track in tracks) {
      if (track.seekOffsetSeconds <= seekOffsetSeconds) {
        activeTrack = track;
      } else {
        break;
      }
    }
    return activeTrack;
  }

  String? _resolveSelectedStoreId({
    required List<String> availableStoreIds,
    String? currentStoreId,
  }) {
    if (availableStoreIds.isEmpty) return null;
    if (state.selectedStoreId != null &&
        availableStoreIds.contains(state.selectedStoreId)) {
      return state.selectedStoreId;
    }
    if (currentStoreId != null && availableStoreIds.contains(currentStoreId)) {
      return currentStoreId;
    }
    return availableStoreIds.first;
  }

  Future<void> _refreshPairInfoForSpace({
    required String spaceId,
    required Emitter<LocationState> emit,
    PairCodeSnapshot? activePairCode,
  }) async {
    final result = await getPairDeviceInfoForManager(spaceId);
    result.fold(
      (_) => null,
      (pairInfo) {
        emit(_replaceSpaceInState(
          state,
          spaceId,
          (space) => space.copyWith(
            pairDeviceInfo: pairInfo,
            activePairCode: pairInfo.isPaired ? null : activePairCode,
            clearActivePairCode: pairInfo.isPaired,
          ),
        ));
      },
    );
  }

  LocationState _withSpaceBusy(
    LocationState current,
    String spaceId,
    bool isBusy,
  ) {
    final busyIds = current.busySpaceIds.toSet();
    if (isBusy) {
      busyIds.add(spaceId);
    } else {
      busyIds.remove(spaceId);
    }
    return current.copyWith(busySpaceIds: busyIds.toList(), clearError: true);
  }

  LocationSpace? _findSpaceById(String spaceId) {
    if (state.pairedSpace?.id == spaceId) {
      return state.pairedSpace;
    }

    final storeMatch = state.storeSpaces?.items
        .cast<LocationSpace?>()
        .firstWhere((space) => space?.id == spaceId, orElse: () => null);
    if (storeMatch != null) return storeMatch;

    if (state.brandSpaces != null) {
      for (final page in state.brandSpaces!.values) {
        final match = page.items
            .cast<LocationSpace?>()
            .firstWhere((space) => space?.id == spaceId, orElse: () => null);
        if (match != null) return match;
      }
    }
    return null;
  }

  LocationState _replaceSpaceInState(
    LocationState current,
    String spaceId,
    LocationSpace Function(LocationSpace space) mapper,
  ) {
    final pairedSpace = current.pairedSpace?.id == spaceId
        ? mapper(current.pairedSpace!)
        : current.pairedSpace;

    final storeSpaces = current.storeSpaces == null
        ? null
        : PaginationResult<LocationSpace>(
            currentPage: current.storeSpaces!.currentPage,
            pageSize: current.storeSpaces!.pageSize,
            totalItems: current.storeSpaces!.totalItems,
            totalPages: current.storeSpaces!.totalPages,
            hasPrevious: current.storeSpaces!.hasPrevious,
            hasNext: current.storeSpaces!.hasNext,
            items: current.storeSpaces!.items
                .map((space) => space.id == spaceId ? mapper(space) : space)
                .toList(),
          );

    final brandSpaces = current.brandSpaces == null
        ? null
        : current.brandSpaces!.map((storeId, page) {
            return MapEntry(
              storeId,
              PaginationResult<LocationSpace>(
                currentPage: page.currentPage,
                pageSize: page.pageSize,
                totalItems: page.totalItems,
                totalPages: page.totalPages,
                hasPrevious: page.hasPrevious,
                hasNext: page.hasNext,
                items: page.items
                    .map((space) => space.id == spaceId ? mapper(space) : space)
                    .toList(),
              ),
            );
          });

    return current.copyWith(
      pairedSpace: pairedSpace,
      storeSpaces: storeSpaces,
      brandSpaces: brandSpaces,
    );
  }

  @override
  Future<void> close() async {
    await _stateSyncSub?.cancel();
    await _connectionSub?.cancel();
    await storeHubService.disconnect();
    storeHubService.dispose();
    return super.close();
  }
}
