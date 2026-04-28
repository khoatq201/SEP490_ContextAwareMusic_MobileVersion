import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/artist_entity.dart';
import '../../domain/usecases/get_artist_detail_usecase.dart';

class ArtistDetailState extends Equatable {
  const ArtistDetailState({
    this.status = ArtistDetailStatus.initial,
    this.artist,
    this.failure,
  });

  final ArtistDetailStatus status;
  final ArtistEntity? artist;
  final Failure? failure;

  String? get errorMessage => failure?.message;

  @override
  List<Object?> get props => [status, artist, failure];
}

enum ArtistDetailStatus { initial, loading, loaded, error }

class ArtistDetailCubit extends Cubit<ArtistDetailState> {
  ArtistDetailCubit({required GetArtistDetailUseCase getArtistDetail})
      : _getArtistDetail = getArtistDetail,
        super(const ArtistDetailState());

  final GetArtistDetailUseCase _getArtistDetail;

  Future<void> load(String artistId) async {
    emit(const ArtistDetailState(status: ArtistDetailStatus.loading));
    final result = await _getArtistDetail(artistId);
    result.fold(
      (failure) => emit(
        ArtistDetailState(
          status: ArtistDetailStatus.error,
          failure: failure,
        ),
      ),
      (artist) => emit(
        ArtistDetailState(
          status: ArtistDetailStatus.loaded,
          artist: artist,
        ),
      ),
    );
  }
}
