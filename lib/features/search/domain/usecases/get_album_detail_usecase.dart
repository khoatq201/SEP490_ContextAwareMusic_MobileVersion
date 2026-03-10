import '../entities/album_entity.dart';
import '../repositories/search_repository.dart';

class GetAlbumDetailUseCase {
  final SearchRepository repository;
  GetAlbumDetailUseCase(this.repository);

  Future<AlbumEntity> call(String albumId) =>
      repository.getAlbumDetail(albumId);
}
