import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/artist_entity.dart';
import '../../domain/usecases/get_artist_detail_usecase.dart';

// ─── State ───────────────────────────────────────────────────────────────────
class ArtistDetailState extends Equatable {
  final ArtistDetailStatus status;
  final ArtistEntity? artist;
  final String? errorMessage;

  const ArtistDetailState({
    this.status = ArtistDetailStatus.initial,
    this.artist,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, artist, errorMessage];
}

enum ArtistDetailStatus { initial, loading, loaded, error }

// ─── Cubit ───────────────────────────────────────────────────────────────────
class ArtistDetailCubit extends Cubit<ArtistDetailState> {
  final GetArtistDetailUseCase _getArtistDetail;

  ArtistDetailCubit({required GetArtistDetailUseCase getArtistDetail})
      : _getArtistDetail = getArtistDetail,
        super(const ArtistDetailState());

  Future<void> load(String artistId) async {
    emit(const ArtistDetailState(status: ArtistDetailStatus.loading));
    try {
      final artist = await _getArtistDetail(artistId);
      emit(ArtistDetailState(
        status: ArtistDetailStatus.loaded,
        artist: artist,
      ));
    } catch (e) {
      emit(ArtistDetailState(
        status: ArtistDetailStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
