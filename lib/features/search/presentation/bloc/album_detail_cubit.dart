import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/album_entity.dart';
import '../../domain/usecases/get_album_detail_usecase.dart';

// ─── State ───────────────────────────────────────────────────────────────────
class AlbumDetailState extends Equatable {
  final AlbumDetailStatus status;
  final AlbumEntity? album;
  final String? errorMessage;

  const AlbumDetailState({
    this.status = AlbumDetailStatus.initial,
    this.album,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, album, errorMessage];
}

enum AlbumDetailStatus { initial, loading, loaded, error }

// ─── Cubit ───────────────────────────────────────────────────────────────────
class AlbumDetailCubit extends Cubit<AlbumDetailState> {
  final GetAlbumDetailUseCase _getAlbumDetail;

  AlbumDetailCubit({required GetAlbumDetailUseCase getAlbumDetail})
      : _getAlbumDetail = getAlbumDetail,
        super(const AlbumDetailState());

  Future<void> load(String albumId) async {
    emit(const AlbumDetailState(status: AlbumDetailStatus.loading));
    try {
      final album = await _getAlbumDetail(albumId);
      emit(AlbumDetailState(
        status: AlbumDetailStatus.loaded,
        album: album,
      ));
    } catch (e) {
      emit(AlbumDetailState(
        status: AlbumDetailStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
