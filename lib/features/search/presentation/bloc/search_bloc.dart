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
  final GetCategoriesUseCase _getCategories;
  final SearchMusicUseCase _searchMusic;
  final SearchByTypeUseCase _searchByType;
  final GetFeaturedPlaylistsUseCase _getFeaturedPlaylists;

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

  Future<void> _onLoadCategories(
    LoadCategoriesEvent event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(status: SearchStatus.loading));
    try {
      final cats = await _getCategories();
      emit(state.copyWith(status: SearchStatus.success, categories: cats));
    } catch (e) {
      emit(state.copyWith(
        status: SearchStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onQueryChanged(
    QueryChangedEvent event,
    Emitter<SearchState> emit,
  ) async {
    final q = event.query.trim();
    if (q.isEmpty) {
      emit(state.copyWith(query: '', results: []));
      return;
    }
    emit(state.copyWith(query: q, status: SearchStatus.loading));
    try {
      final tag = state.activeTag;
      List<SearchResult> results;

      if (tag == SearchFilterTag.all || tag == SearchFilterTag.featuring) {
        results = await _searchMusic(q);
      } else {
        final typeMap = {
          SearchFilterTag.playlists: SearchResultType.playlist,
          SearchFilterTag.artists: SearchResultType.artist,
          SearchFilterTag.songs: SearchResultType.song,
          SearchFilterTag.albums: SearchResultType.album,
          SearchFilterTag.categories: SearchResultType.category,
        };
        results = await _searchByType(q, typeMap[tag]!);
      }

      emit(state.copyWith(
        status: SearchStatus.success,
        results: results,
        query: q,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SearchStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onClearSearch(ClearSearchEvent event, Emitter<SearchState> emit) {
    emit(state.copyWith(
      query: '',
      results: [],
      activeTag: SearchFilterTag.all,
    ));
  }

  Future<void> _onFilterTagChanged(
    FilterTagChangedEvent event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(activeTag: event.tag));

    // If there is a current query, re-search with the new filter
    if (state.query.isNotEmpty) {
      add(QueryChangedEvent(state.query));
    }
    // If switching to "Featuring" with no query, load featured playlists
    if (event.tag == SearchFilterTag.featuring &&
        state.featuredPlaylists.isEmpty) {
      add(const LoadFeaturedEvent());
    }
  }

  Future<void> _onLoadFeatured(
    LoadFeaturedEvent event,
    Emitter<SearchState> emit,
  ) async {
    try {
      final featured = await _getFeaturedPlaylists();
      emit(state.copyWith(featuredPlaylists: featured));
    } catch (_) {
      // Silently fail — featured is non-critical
    }
  }
}
