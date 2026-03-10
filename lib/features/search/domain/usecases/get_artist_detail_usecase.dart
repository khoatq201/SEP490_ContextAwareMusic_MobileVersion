import '../entities/artist_entity.dart';
import '../repositories/search_repository.dart';

class GetArtistDetailUseCase {
  final SearchRepository repository;
  GetArtistDetailUseCase(this.repository);

  Future<ArtistEntity> call(String artistId) =>
      repository.getArtistDetail(artistId);
}
