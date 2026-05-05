import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/user_role.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../home/domain/entities/playlist_entity.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/usecases/get_category_playlists_usecase.dart';

class CategoryDetailState extends Equatable {
  const CategoryDetailState({
    this.status = CategoryDetailStatus.initial,
    this.playlists = const [],
    this.tracks = const [],
    this.failure,
  });

  final CategoryDetailStatus status;
  final List<PlaylistEntity> playlists;
  final List<SearchResult> tracks;
  final Failure? failure;

  String? get errorMessage => failure?.message;

  @override
  List<Object?> get props => [status, playlists, tracks, failure];
}

enum CategoryDetailStatus { initial, loading, loaded, error }

class CategoryDetailCubit extends Cubit<CategoryDetailState> {
  CategoryDetailCubit({
    required GetCategoryPlaylistsUseCase getCategoryPlaylists,
    required GetCategoryTracksUseCase getCategoryTracks,
    SessionCubit? sessionCubit,
  })  : _getCategoryPlaylists = getCategoryPlaylists,
        _getCategoryTracks = getCategoryTracks,
        _sessionCubit = sessionCubit,
        super(const CategoryDetailState());

  final GetCategoryPlaylistsUseCase _getCategoryPlaylists;
  final GetCategoryTracksUseCase _getCategoryTracks;
  final SessionCubit? _sessionCubit;

  bool get _playableTracksOnly {
    final session = _sessionCubit?.state;
    if (session == null) return false;
    return session.isPlaybackDevice ||
        session.currentRole != UserRole.brandManager;
  }

  Future<void> load(String categoryId) async {
    emit(const CategoryDetailState(status: CategoryDetailStatus.loading));
    final playlistResult = await _getCategoryPlaylists(categoryId);
    final trackResult = await _getCategoryTracks(
      categoryId,
      playableTracksOnly: _playableTracksOnly,
    );

    final failure = playlistResult.fold<Failure?>(
      (failure) => failure,
      (_) => trackResult.fold<Failure?>(
        (failure) => failure,
        (_) => null,
      ),
    );
    if (failure != null) {
      emit(
        CategoryDetailState(
          status: CategoryDetailStatus.error,
          failure: failure,
        ),
      );
      return;
    }

    final playlists = playlistResult.getOrElse(() => const []);
    final tracks = trackResult.getOrElse(() => const []);
    emit(
      CategoryDetailState(
        status: CategoryDetailStatus.loaded,
        playlists: playlists,
        tracks: tracks,
      ),
    );
  }
}
