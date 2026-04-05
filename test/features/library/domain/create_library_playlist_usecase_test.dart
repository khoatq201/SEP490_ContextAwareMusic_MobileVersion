import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/library/domain/create_library_playlist_usecase.dart';
import 'package:cams_store_manager/features/playlists/data/datasources/playlist_remote_datasource.dart';
import 'package:cams_store_manager/features/playlists/data/models/api_playlist_model.dart';

void main() {
  group('createLibraryPlaylist', () {
    late _FakePlaylistRemoteDataSource dataSource;

    setUp(() {
      dataSource = _FakePlaylistRemoteDataSource();
    });

    test('returns null when name is empty after trim', () async {
      final result = await createLibraryPlaylist(
        playlistDataSource: dataSource,
        name: '   ',
        storeId: 'store-1',
      );

      expect(result, isNull);
      expect(dataSource.createCalls, 0);
      expect(dataSource.getPlaylistsCalls, 0);
    });

    test('uses id from mutation response when available', () async {
      dataSource.createResult = const PlaylistMutationResult(
        isSuccess: true,
        id: 'playlist-1',
      );

      final result = await createLibraryPlaylist(
        playlistDataSource: dataSource,
        name: 'Morning Vibes',
        storeId: 'store-1',
      );

      expect(result, 'playlist-1');
      expect(dataSource.createCalls, 1);
      expect(dataSource.getPlaylistsCalls, 0);
      expect(dataSource.lastCreateRequest?.toJson(), {
        'name': 'Morning Vibes',
        'storeId': 'store-1',
      });
    });

    test('falls back to refreshed playlist list when mutation has no id',
        () async {
      dataSource.createResult = const PlaylistMutationResult(
        isSuccess: true,
      );
      dataSource.playlists = [
        ApiPlaylistModel.fromJson(const {
          'id': 'playlist-2',
          'name': '  Morning Vibes  ',
          'createdAt': '2026-03-25T08:00:00Z',
        }),
      ];

      final result = await createLibraryPlaylist(
        playlistDataSource: dataSource,
        name: 'morning vibes',
        storeId: 'store-1',
      );

      expect(result, 'playlist-2');
      expect(dataSource.createCalls, 1);
      expect(dataSource.getPlaylistsCalls, 1);
      expect(dataSource.lastSearch, 'morning vibes');
      expect(dataSource.lastStoreId, 'store-1');
    });

    test('returns null when fallback list cannot find created playlist',
        () async {
      dataSource.createResult = const PlaylistMutationResult(
        isSuccess: true,
      );
      dataSource.playlists = [
        ApiPlaylistModel.fromJson(const {
          'id': 'playlist-3',
          'name': 'Evening Chill',
          'createdAt': '2026-03-25T08:00:00Z',
        }),
      ];

      final result = await createLibraryPlaylist(
        playlistDataSource: dataSource,
        name: 'Morning Vibes',
        storeId: 'store-1',
      );

      expect(result, isNull);
      expect(dataSource.createCalls, 1);
      expect(dataSource.getPlaylistsCalls, 1);
    });

    test('passes optional create fields supported by PlaylistRequest',
        () async {
      dataSource.createResult = const PlaylistMutationResult(
        isSuccess: true,
        id: 'playlist-4',
      );

      final result = await createLibraryPlaylist(
        playlistDataSource: dataSource,
        name: '  Morning Vibes  ',
        storeId: ' store-1 ',
        description: '  Soft background music  ',
        moodId: ' mood-relax ',
        isDefault: true,
        trackIds: const ['track-1', ' track-2 ', 'track-1', ' '],
      );

      expect(result, 'playlist-4');
      expect(dataSource.lastCreateRequest?.toJson(), {
        'name': 'Morning Vibes',
        'storeId': 'store-1',
        'moodId': 'mood-relax',
        'description': 'Soft background music',
        'isDefault': true,
        'trackIds': ['track-1', 'track-2'],
      });
    });
  });
}

class _FakePlaylistRemoteDataSource implements PlaylistRemoteDataSource {
  int createCalls = 0;
  int getPlaylistsCalls = 0;
  PlaylistMutationRequest? lastCreateRequest;
  String? lastSearch;
  String? lastStoreId;
  PlaylistMutationResult createResult =
      const PlaylistMutationResult(isSuccess: true);
  List<ApiPlaylistModel> playlists = const [];

  @override
  Future<PlaylistMutationResult> createPlaylist(
    PlaylistMutationRequest request,
  ) async {
    createCalls += 1;
    lastCreateRequest = request;
    return createResult;
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
    bool? isDefault,
    DateTime? createdFrom,
    DateTime? createdTo,
  }) async {
    getPlaylistsCalls += 1;
    lastSearch = search;
    lastStoreId = storeId;
    return PlaylistListResponse(
      items: playlists,
      currentPage: 1,
      totalPages: 1,
      totalItems: playlists.length,
      hasNext: false,
      hasPrevious: false,
    );
  }

  @override
  Future<ApiPlaylistModel> getPlaylistById(String playlistId) async {
    throw UnimplementedError();
  }

  @override
  Future<PlaylistMutationResult> updatePlaylist(
    String playlistId,
    PlaylistMutationRequest request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<PlaylistMutationResult> deletePlaylist(String playlistId) async {
    throw UnimplementedError();
  }

  @override
  Future<PlaylistMutationResult> togglePlaylistStatus(String playlistId) async {
    throw UnimplementedError();
  }

  @override
  Future<PlaylistMutationResult> addTracksToPlaylist({
    required String playlistId,
    required List<String> trackIds,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<PlaylistMutationResult> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    throw UnimplementedError();
  }
}
