import '../../../home/domain/entities/playlist_entity.dart';
import '../repositories/search_repository.dart';

class GetFeaturedPlaylistsUseCase {
  final SearchRepository repository;
  GetFeaturedPlaylistsUseCase(this.repository);

  Future<List<PlaylistEntity>> call() => repository.getFeaturedPlaylists();
}
