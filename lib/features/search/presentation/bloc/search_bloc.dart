import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/session_data_cache.dart';
import '../../../home/domain/entities/playlist_entity.dart';
import '../../domain/entities/search_filter_tag.dart';
import '../../domain/entities/search_category.dart';
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
    SessionDataCache? sessionDataCache,
  })  : _getCategories = getCategories,
        _searchMusic = searchMusic,
        _searchByType = searchByType,
        _getFeaturedPlaylists = getFeaturedPlaylists,
        _sessionDataCache = sessionDataCache,
        super(const SearchState()) {
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<QueryChangedEvent>(_onQueryChanged);
    on<ClearSearchEvent>(_onClearSearch);
    on<FilterTagChangedEvent>(_onFilterTagChanged);
    on<LoadFeaturedEvent>(_onLoadFeatured);
    on<RefreshSearchEvent>(_onRefreshSearch);
  }

  final GetCategoriesUseCase _getCategories;
  final SearchMusicUseCase _searchMusic;
  final SearchByTypeUseCase _searchByType;
  final GetFeaturedPlaylistsUseCase _getFeaturedPlaylists;
  final SessionDataCache? _sessionDataCache;
  int _querySequence = 0;

  Future<void> _onLoadCategories(
    LoadCategoriesEvent event,
    Emitter<SearchState> emit,
  ) async {
    if (!event.forceRefresh) {
      final cached =
          _sessionDataCache?.get<List<SearchCategory>>('search.categories');
      if (cached != null) {
        emit(state.copyWith(
          status: SearchStatus.success,
          categories: cached,
          clearFailure: true,
        ));
        return;
      }
    }

    emit(state.copyWith(status: SearchStatus.loading, clearFailure: true));

    final result = await _getCategories();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SearchStatus.failure,
          failure: failure,
        ),
      ),
      (categories) {
        _sessionDataCache?.put('search.categories', categories);
        emit(
          state.copyWith(
            status: SearchStatus.success,
            categories: categories,
            clearFailure: true,
          ),
        );
      },
    );
  }

  Future<void> _onQueryChanged(
    QueryChangedEvent event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();
    final sequence = ++_querySequence;
    if (event.debounce) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (sequence != _querySequence) return;
    }

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
    final cacheKey = 'search.results.${tag.name}.$query';
    if (!event.forceRefresh) {
      final cached = _sessionDataCache?.get<List<SearchResult>>(cacheKey);
      if (cached != null) {
        emit(
          state.copyWith(
            status: SearchStatus.success,
            results: cached,
            query: query,
            clearFailure: true,
          ),
        );
        return;
      }
    }

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
      (results) {
        _sessionDataCache?.put(cacheKey, results);
        emit(
          state.copyWith(
            status: SearchStatus.success,
            results: results,
            query: query,
            clearFailure: true,
          ),
        );
      },
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
    if (!event.forceRefresh) {
      final cached = _sessionDataCache
          ?.get<List<PlaylistEntity>>('search.featuredPlaylists');
      if (cached != null) {
        emit(state.copyWith(featuredPlaylists: cached));
        return;
      }
    }

    final result = await _getFeaturedPlaylists();
    result.fold(
      (_) {},
      (featured) {
        _sessionDataCache?.put('search.featuredPlaylists', featured);
        emit(state.copyWith(featuredPlaylists: featured));
      },
    );
  }

  void _onRefreshSearch(
    RefreshSearchEvent event,
    Emitter<SearchState> emit,
  ) {
    add(const LoadCategoriesEvent(forceRefresh: true));
    if (state.query.isNotEmpty) {
      add(QueryChangedEvent(state.query, forceRefresh: true));
      return;
    }
    if (state.activeTag == SearchFilterTag.featuring) {
      add(const LoadFeaturedEvent(forceRefresh: true));
    }
  }
}
