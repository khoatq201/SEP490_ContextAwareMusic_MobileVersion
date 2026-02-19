import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/search_music_usecase.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final GetCategoriesUseCase _getCategories;
  final SearchMusicUseCase _searchMusic;

  SearchBloc({
    required GetCategoriesUseCase getCategories,
    required SearchMusicUseCase searchMusic,
  })  : _getCategories = getCategories,
        _searchMusic = searchMusic,
        super(const SearchState()) {
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<QueryChangedEvent>(_onQueryChanged);
    on<ClearSearchEvent>(_onClearSearch);
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
      final results = await _searchMusic(q);
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
    emit(state.copyWith(query: '', results: []));
  }
}
