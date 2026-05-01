import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/error/failure_kind.dart';
import 'package:cams_store_manager/core/error/failures.dart';
import 'package:cams_store_manager/core/services/session_data_cache.dart';
import 'package:cams_store_manager/features/home/domain/entities/playlist_entity.dart';
import 'package:cams_store_manager/features/search/domain/entities/album_entity.dart';
import 'package:cams_store_manager/features/search/domain/entities/artist_entity.dart';
import 'package:cams_store_manager/features/search/domain/entities/search_category.dart';
import 'package:cams_store_manager/features/search/domain/entities/search_filter_tag.dart';
import 'package:cams_store_manager/features/search/domain/entities/search_result.dart';
import 'package:cams_store_manager/features/search/domain/repositories/search_repository.dart';
import 'package:cams_store_manager/features/search/domain/usecases/get_categories_usecase.dart';
import 'package:cams_store_manager/features/search/domain/usecases/get_featured_playlists_usecase.dart';
import 'package:cams_store_manager/features/search/domain/usecases/search_by_type_usecase.dart';
import 'package:cams_store_manager/features/search/domain/usecases/search_music_usecase.dart';
import 'package:cams_store_manager/features/search/presentation/bloc/search_bloc.dart';
import 'package:cams_store_manager/features/search/presentation/bloc/search_event.dart';
import 'package:cams_store_manager/features/search/presentation/bloc/search_state.dart';

void main() {
  group('SearchBloc', () {
    late _FakeSearchRepository repository;
    late SearchBloc bloc;

    setUp(() {
      repository = _FakeSearchRepository();
      bloc = SearchBloc(
        getCategories: GetCategoriesUseCase(repository),
        searchMusic: SearchMusicUseCase(repository),
        searchByType: SearchByTypeUseCase(repository),
        getFeaturedPlaylists: GetFeaturedPlaylistsUseCase(repository),
      );
    });

    tearDown(() async {
      await bloc.close();
    });

    test('stores structured failure when categories fail to load', () async {
      repository.categoriesResult = const Left(
        ServerFailure(
          'Failed to load categories: DioException [bad response]',
          FailureKind.server,
        ),
      );

      bloc.add(const LoadCategoriesEvent());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state.status, SearchStatus.failure);
      expect(bloc.state.failure, isNotNull);
      expect(bloc.state.failure!.kind, FailureKind.server);
    });

    test('uses typed search when a specific filter is active', () async {
      repository.searchByTypeResult = const Right([
        SearchResult(
          id: 'artist-1',
          title: 'Arctic Avenue',
          subtitle: 'Artist',
          type: SearchResultType.artist,
        ),
      ]);

      bloc.add(const FilterTagChangedEvent(SearchFilterTag.artists));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const QueryChangedEvent('arctic'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(repository.lastTypeQuery, 'arctic');
      expect(repository.lastType, SearchResultType.artist);
      expect(bloc.state.status, SearchStatus.success);
      expect(bloc.state.results, hasLength(1));
    });

    test('caches repeated query/filter results until force refresh', () async {
      await bloc.close();
      repository = _FakeSearchRepository();
      bloc = SearchBloc(
        getCategories: GetCategoriesUseCase(repository),
        searchMusic: SearchMusicUseCase(repository),
        searchByType: SearchByTypeUseCase(repository),
        getFeaturedPlaylists: GetFeaturedPlaylistsUseCase(repository),
        sessionDataCache: SessionDataCache(),
      );
      repository.searchResult = const Right([
        SearchResult(
          id: 'track-1',
          title: 'Morning Track',
          subtitle: 'Artist',
          type: SearchResultType.song,
        ),
      ]);

      bloc.add(const QueryChangedEvent('morning'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const QueryChangedEvent('morning'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const QueryChangedEvent('morning', forceRefresh: true));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(repository.searchCallCount, 2);
      expect(bloc.state.results.single.title, 'Morning Track');
    });
  });
}

class _FakeSearchRepository implements SearchRepository {
  Either<Failure, List<SearchCategory>> categoriesResult = const Right([]);
  Either<Failure, List<SearchResult>> searchResult = const Right([]);
  Either<Failure, List<SearchResult>> searchByTypeResult = const Right([]);
  Either<Failure, ArtistEntity> artistResult = const Right(
    ArtistEntity(id: 'artist-1', name: 'Artist'),
  );
  Either<Failure, AlbumEntity> albumResult = const Right(
    AlbumEntity(
      id: 'album-1',
      name: 'Album',
      artistName: 'Artist',
      coverUrl: '',
      releaseYear: 2024,
      songs: [],
    ),
  );
  Either<Failure, PlaylistEntity> playlistResult = const Right(
    PlaylistEntity(
      id: 'playlist-1',
      title: 'Playlist',
      description: '',
      songs: [],
    ),
  );
  Either<Failure, List<PlaylistEntity>> categoryPlaylistsResult = const Right(
    [],
  );
  Either<Failure, List<PlaylistEntity>> featuredResult = const Right([]);

  String? lastTypeQuery;
  SearchResultType? lastType;
  int searchCallCount = 0;

  @override
  Future<Either<Failure, AlbumEntity>> getAlbumDetail(String albumId) async =>
      albumResult;

  @override
  Future<Either<Failure, ArtistEntity>> getArtistDetail(
          String artistId) async =>
      artistResult;

  @override
  Future<Either<Failure, List<SearchCategory>>> getCategories() async =>
      categoriesResult;

  @override
  Future<Either<Failure, List<PlaylistEntity>>> getCategoryPlaylists(
    String categoryId,
  ) async =>
      categoryPlaylistsResult;

  @override
  Future<Either<Failure, List<PlaylistEntity>>> getFeaturedPlaylists() async =>
      featuredResult;

  @override
  Future<Either<Failure, PlaylistEntity>> getPlaylistDetail(
    String playlistId,
  ) async =>
      playlistResult;

  @override
  Future<Either<Failure, List<SearchResult>>> search(String query) async {
    searchCallCount += 1;
    return searchResult;
  }

  @override
  Future<Either<Failure, List<SearchResult>>> searchByType(
    String query,
    SearchResultType type,
  ) async {
    lastTypeQuery = query;
    lastType = type;
    return searchByTypeResult;
  }
}
