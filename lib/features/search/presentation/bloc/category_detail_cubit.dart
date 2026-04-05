import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../home/domain/entities/playlist_entity.dart';
import '../../domain/usecases/get_category_playlists_usecase.dart';

class CategoryDetailState extends Equatable {
  const CategoryDetailState({
    this.status = CategoryDetailStatus.initial,
    this.playlists = const [],
    this.failure,
  });

  final CategoryDetailStatus status;
  final List<PlaylistEntity> playlists;
  final Failure? failure;

  String? get errorMessage => failure?.message;

  @override
  List<Object?> get props => [status, playlists, failure];
}

enum CategoryDetailStatus { initial, loading, loaded, error }

class CategoryDetailCubit extends Cubit<CategoryDetailState> {
  CategoryDetailCubit({
    required GetCategoryPlaylistsUseCase getCategoryPlaylists,
  })  : _getCategoryPlaylists = getCategoryPlaylists,
        super(const CategoryDetailState());

  final GetCategoryPlaylistsUseCase _getCategoryPlaylists;

  Future<void> load(String categoryId) async {
    emit(const CategoryDetailState(status: CategoryDetailStatus.loading));
    final result = await _getCategoryPlaylists(categoryId);
    result.fold(
      (failure) => emit(
        CategoryDetailState(
          status: CategoryDetailStatus.error,
          failure: failure,
        ),
      ),
      (playlists) => emit(
        CategoryDetailState(
          status: CategoryDetailStatus.loaded,
          playlists: playlists,
        ),
      ),
    );
  }
}
