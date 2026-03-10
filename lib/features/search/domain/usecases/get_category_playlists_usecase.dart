import '../../../home/domain/entities/playlist_entity.dart';
import '../repositories/search_repository.dart';

class GetCategoryPlaylistsUseCase {
  final SearchRepository repository;
  GetCategoryPlaylistsUseCase(this.repository);

  Future<List<PlaylistEntity>> call(String categoryId) =>
      repository.getCategoryPlaylists(categoryId);
}
