import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../home/domain/entities/playlist_entity.dart';
import '../../domain/usecases/get_category_playlists_usecase.dart';

// ─── State ───────────────────────────────────────────────────────────────────
class CategoryDetailState extends Equatable {
  final CategoryDetailStatus status;
  final List<PlaylistEntity> playlists;
  final String? errorMessage;

  const CategoryDetailState({
    this.status = CategoryDetailStatus.initial,
    this.playlists = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, playlists, errorMessage];
}

enum CategoryDetailStatus { initial, loading, loaded, error }

// ─── Cubit ───────────────────────────────────────────────────────────────────
class CategoryDetailCubit extends Cubit<CategoryDetailState> {
  final GetCategoryPlaylistsUseCase _getCategoryPlaylists;

  CategoryDetailCubit(
      {required GetCategoryPlaylistsUseCase getCategoryPlaylists})
      : _getCategoryPlaylists = getCategoryPlaylists,
        super(const CategoryDetailState());

  Future<void> load(String categoryId) async {
    emit(const CategoryDetailState(status: CategoryDetailStatus.loading));
    try {
      final playlists = await _getCategoryPlaylists(categoryId);
      emit(CategoryDetailState(
        status: CategoryDetailStatus.loaded,
        playlists: playlists,
      ));
    } catch (e) {
      emit(CategoryDetailState(
        status: CategoryDetailStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
