import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/album_entity.dart';
import '../../domain/usecases/get_album_detail_usecase.dart';

class AlbumDetailState extends Equatable {
  const AlbumDetailState({
    this.status = AlbumDetailStatus.initial,
    this.album,
    this.failure,
  });

  final AlbumDetailStatus status;
  final AlbumEntity? album;
  final Failure? failure;

  String? get errorMessage => failure?.message;

  @override
  List<Object?> get props => [status, album, failure];
}

enum AlbumDetailStatus { initial, loading, loaded, error }

class AlbumDetailCubit extends Cubit<AlbumDetailState> {
  AlbumDetailCubit({required GetAlbumDetailUseCase getAlbumDetail})
      : _getAlbumDetail = getAlbumDetail,
        super(const AlbumDetailState());

  final GetAlbumDetailUseCase _getAlbumDetail;

  Future<void> load(String albumId) async {
    emit(const AlbumDetailState(status: AlbumDetailStatus.loading));
    final result = await _getAlbumDetail(albumId);
    result.fold(
      (failure) => emit(
        AlbumDetailState(
          status: AlbumDetailStatus.error,
          failure: failure,
        ),
      ),
      (album) => emit(
        AlbumDetailState(
          status: AlbumDetailStatus.loaded,
          album: album,
        ),
      ),
    );
  }
}
