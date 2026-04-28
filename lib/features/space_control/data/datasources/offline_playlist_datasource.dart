import '../../domain/entities/offline_playlist.dart';

/// Abstract interface for offline playlist data source.
/// Both [OfflinePlaylistMockDatasource] and [OfflinePlaylistRemoteDataSourceImpl]
/// implement this interface.
abstract class OfflinePlaylistDataSource {
  /// Fetches available playlists from server
  Future<List<OfflinePlaylist>> getAvailablePlaylists();

  /// Downloads a playlist, returning a stream of progress (0.0 to 1.0)
  Stream<double> downloadPlaylist(String playlistId);

  /// Deletes a locally stored playlist
  Future<void> deletePlaylist(String playlistId);
}
