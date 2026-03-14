import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/pagination_result.dart';
import '../../../cams/domain/entities/space_playback_state.dart';
import '../../../cams/domain/usecases/get_space_state.dart';
import '../../../playlists/data/datasources/playlist_remote_datasource.dart';
import '../../../playlists/domain/entities/api_playlist.dart';
import '../../../playlists/domain/entities/playlist_track_item.dart';
import '../../../store_selection/domain/entities/store_summary.dart';
import '../../../store_selection/domain/usecases/get_user_stores.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
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
  final PlaylistRemoteDataSource playlistDataSource;
  final GetUserStores getUserStores;

  LocationBloc({
    required this.sessionCubit,
    required this.authBloc,
    required this.getPairedSpace,
    required this.getSpacesForStore,
    required this.getSpacesForBrand,
    required this.getSpaceState,
    required this.playlistDataSource,
    required this.getUserStores,
  }) : super(const LocationState()) {
    on<LoadLocationsRequested>(_onLoadLocationsRequested);
  }

  bool get _isBrandScopedUser {
    final user = authBloc.state.user;
    return user?.isBrandManager == true || user?.isSystemAdmin == true;
  }

  Future<void> _onLoadLocationsRequested(
    LoadLocationsRequested event,
    Emitter<LocationState> emit,
  ) async {
    emit(state.copyWith(status: LocationStatus.loading));

    final session = sessionCubit.state;
    debugPrint(
        '[LocationBloc] isBrandScopedUser=$_isBrandScopedUser, isPlaybackDevice=${session.isPlaybackDevice}');

    // 1. Playback Device Mode
    if (session.isPlaybackDevice) {
      if (session.currentSpace == null || session.currentStore == null) {
        emit(state.copyWith(
            status: LocationStatus.failure,
            errorMessage: 'Device not properly paired'));
        return;
      }
      final result = await getPairedSpace(
          session.currentSpace!.id, session.currentStore!.id);
      await result.fold(
        (failure) async => emit(state.copyWith(
            status: LocationStatus.failure, errorMessage: failure.message)),
        (space) async {
          final enriched = await _enrichSpaces(
            [space],
            storeNamesById: {
              session.currentStore!.id: session.currentStore!.name,
            },
          );
          emit(state.copyWith(
            status: LocationStatus.success,
            pairedSpace: enriched.isNotEmpty ? enriched.first : space,
            storeNamesById: {
              session.currentStore!.id: session.currentStore!.name,
            },
          ));
        },
      );
      return;
    }

    // 2. Brand Manager / Admin → show ALL stores with spaces
    if (_isBrandScopedUser) {
      final storesResult = await getUserStores();
      final stores = storesResult.fold<List<StoreSummary>>(
        (_) => const [],
        (stores) => stores,
      );
      final storeNamesById = {
        for (final store in stores) store.id: store.name,
      };
      final storeIdsForBrand = stores.map((store) => store.id).toList();
      debugPrint(
          '[LocationBloc] brandManager branch: storeIds=$storeIdsForBrand');
      if (storeIdsForBrand.isEmpty) {
        emit(state.copyWith(
            status: LocationStatus.failure,
            errorMessage: 'No stores available for this brand'));
        return;
      }
      final result = await getSpacesForBrand(storeIdsForBrand,
          page: 1, pageSize: 50); // Get first 50 per store
      await result.fold(
        (failure) async => emit(state.copyWith(
            status: LocationStatus.failure, errorMessage: failure.message)),
        (brandSpacesMap) async {
          final enriched = await _enrichBrandSpaces(
            brandSpacesMap,
            storeNamesById: storeNamesById,
          );
          emit(state.copyWith(
            status: LocationStatus.success,
            brandSpaces: enriched,
            storeNamesById: storeNamesById,
          ));
        },
      );
      return;
    }

    // 3. Store Manager → show spaces for the selected store
    if (session.currentStore == null) {
      emit(state.copyWith(
          status: LocationStatus.failure, errorMessage: 'No store selected'));
      return;
    }
    final result = await getSpacesForStore(session.currentStore!.id,
        page: 1, pageSize: 50); // Get first 50
    await result.fold(
      (failure) async => emit(state.copyWith(
          status: LocationStatus.failure, errorMessage: failure.message)),
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
        ));
      },
    );
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
    final enrichedById = {
      for (final space in enrichedSpaces) space.id: space,
    };

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
  }) async {
    if (spaces.isEmpty) return spaces;

    final playbackEntries = await Future.wait(
      spaces.map((space) async {
        final result = await getSpaceState(space.id);
        return result.fold<MapEntry<String, SpacePlaybackState?>>(
          (_) => MapEntry(space.id, null),
          (playbackState) => MapEntry(space.id, playbackState),
        );
      }),
    );

    final playbackBySpaceId = {
      for (final entry in playbackEntries) entry.key: entry.value,
    };

    final playlistIds = playbackBySpaceId.values
        .whereType<SpacePlaybackState>()
        .map((state) => state.currentPlaylistId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    final playlistEntries = await Future.wait(
      playlistIds.map((playlistId) async {
        try {
          final playlist = await playlistDataSource.getPlaylistById(playlistId);
          return MapEntry<String, ApiPlaylist?>(playlistId, playlist);
        } catch (_) {
          return MapEntry<String, ApiPlaylist?>(playlistId, null);
        }
      }),
    );

    final playlistCache = <String, ApiPlaylist>{
      for (final entry in playlistEntries)
        if (entry.value != null) entry.key: entry.value!,
    };

    return spaces
        .map((space) => _applyPlaybackSnapshot(
              storeNamesById.containsKey(space.storeId)
                  ? space.copyWith(storeName: storeNamesById[space.storeId])
                  : space,
              playbackBySpaceId[space.id],
              playlistCache,
            ))
        .toList();
  }

  LocationSpace _applyPlaybackSnapshot(
    LocationSpace space,
    SpacePlaybackState? playbackState,
    Map<String, ApiPlaylist> playlistCache,
  ) {
    if (playbackState == null) return space;

    final playlist = playbackState.currentPlaylistId != null
        ? playlistCache[playbackState.currentPlaylistId!]
        : null;
    final currentTrack = _resolveCurrentTrack(
      playlist,
      playbackState.seekOffsetSeconds,
    );

    return space.copyWith(
      currentPlaylistId:
          playbackState.currentPlaylistId ?? space.currentPlaylistId,
      currentPlaylistName: playbackState.currentPlaylistName ??
          playlist?.name ??
          space.currentPlaylistName,
      currentMoodName:
          playbackState.moodName ?? playlist?.moodName ?? space.currentMoodName,
      currentTrackName: currentTrack?.title ?? space.currentTrackName,
      currentTrackArtist: currentTrack?.artist ?? space.currentTrackArtist,
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
}
