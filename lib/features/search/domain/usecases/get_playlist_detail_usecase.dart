import '../../../home/domain/entities/playlist_entity.dart';
import '../repositories/search_repository.dart';

class GetPlaylistDetailUseCase {
  final SearchRepository repository;
  GetPlaylistDetailUseCase(this.repository);

  Future<PlaylistEntity> call(String playlistId) =>
      repository.getPlaylistDetail(playlistId);
}
