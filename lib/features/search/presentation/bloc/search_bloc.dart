import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/search_filter_tag.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_featured_playlists_usecase.dart';
import '../../domain/usecases/search_by_type_usecase.dart';
import '../../domain/usecases/search_music_usecase.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({
    required GetCategoriesUseCase getCategories,
    required SearchMusicUseCase searchMusic,
    required SearchByTypeUseCase searchByType,
    required GetFeaturedPlaylistsUseCase getFeaturedPlaylists,
  })  : _getCategories = getCategories,
        _searchMusic = searchMusic,
        _searchByType = searchByType,
        _getFeaturedPlaylists = getFeaturedPlaylists,
        super(const SearchState()) {
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<QueryChangedEvent>(_onQueryChanged);
    on<ClearSearchEvent>(_onClearSearch);
    on<FilterTagChangedEvent>(_onFilterTagChanged);
    on<LoadFeaturedEvent>(_onLoadFeatured);
  }

  final GetCategoriesUseCase _getCategories;
  final SearchMusicUseCase _searchMusic;
  final SearchByTypeUseCase _searchByType;
  final GetFeaturedPlaylistsUseCase _getFeaturedPlaylists;

  Future<void> _onLoadCategories(
    LoadCategoriesEvent event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(status: SearchStatus.loading, clearFailure: true));

    final result = await _getCategories();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SearchStatus.failure,
          failure: failure,
        ),
      ),
      (categories) => emit(
        state.copyWith(
          status: SearchStatus.success,
          categories: categories,
          clearFailure: true,
        ),
      ),
    );
  }

  Future<void> _onQueryChanged(
    QueryChangedEvent event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(
        state.copyWith(
          query: '',
          results: const [],
          status: SearchStatus.initial,
          clearFailure: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        query: query,
        status: SearchStatus.loading,
        clearFailure: true,
      ),
    );

    final tag = state.activeTag;
    final typeMap = {
      SearchFilterTag.playlists: SearchResultType.playlist,
      SearchFilterTag.artists: SearchResultType.artist,
      SearchFilterTag.songs: SearchResultType.song,
      SearchFilterTag.albums: SearchResultType.album,
      SearchFilterTag.categories: SearchResultType.category,
    };

    final result =
        tag == SearchFilterTag.all || tag == SearchFilterTag.featuring
            ? await _searchMusic(query)
            : await _searchByType(query, typeMap[tag]!);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SearchStatus.failure,
          failure: failure,
          results: const [],
          query: query,
        ),
      ),
      (results) => emit(
        state.copyWith(
          status: SearchStatus.success,
          results: results,
          query: query,
          clearFailure: true,
        ),
      ),
    );
  }

  void _onClearSearch(ClearSearchEvent event, Emitter<SearchState> emit) {
    emit(
      state.copyWith(
        query: '',
        results: const [],
        activeTag: SearchFilterTag.all,
        status: SearchStatus.initial,
        clearFailure: true,
      ),
    );
  }

  Future<void> _onFilterTagChanged(
    FilterTagChangedEvent event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(activeTag: event.tag));

    if (state.query.isNotEmpty) {
      add(QueryChangedEvent(state.query));
    }

    if (event.tag == SearchFilterTag.featuring &&
        state.featuredPlaylists.isEmpty) {
      add(const LoadFeaturedEvent());
    }
  }

  Future<void> _onLoadFeatured(
    LoadFeaturedEvent event,
    Emitter<SearchState> emit,
  ) async {
    final result = await _getFeaturedPlaylists();
    result.fold(
      (_) {},
      (featured) => emit(state.copyWith(featuredPlaylists: featured)),
    );
  }
}
