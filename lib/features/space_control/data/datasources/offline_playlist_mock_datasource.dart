import '../../domain/entities/offline_playlist.dart';

class OfflinePlaylistMockDatasource {
  /// Mock server response with available playlists
  Future<List<OfflinePlaylist>> getAvailablePlaylists() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      const OfflinePlaylist(
        id: 'playlist_energetic_1',
        moodName: 'Energetic',
        coverUrl: null,
        trackCount: 24,
        totalSizeMB: 142.5,
        downloadStatus: DownloadStatus.notDownloaded,
      ),
      const OfflinePlaylist(
        id: 'playlist_chill_1',
        moodName: 'Chill',
        coverUrl: null,
        trackCount: 18,
        totalSizeMB: 98.3,
        downloadStatus: DownloadStatus.notDownloaded,
      ),
      const OfflinePlaylist(
        id: 'playlist_focus_1',
        moodName: 'Focus',
        coverUrl: null,
        trackCount: 20,
        totalSizeMB: 115.7,
        downloadStatus: DownloadStatus.notDownloaded,
      ),
      const OfflinePlaylist(
        id: 'playlist_happy_1',
        moodName: 'Happy',
        coverUrl: null,
        trackCount: 22,
        totalSizeMB: 128.4,
        downloadStatus: DownloadStatus.notDownloaded,
      ),
      const OfflinePlaylist(
        id: 'playlist_romantic_1',
        moodName: 'Romantic',
        coverUrl: null,
        trackCount: 16,
        totalSizeMB: 89.2,
        downloadStatus: DownloadStatus.notDownloaded,
      ),
    ];
  }

  /// Mock download progress stream
  Stream<double> downloadPlaylist(String playlistId) async* {
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 500));
      yield i / 100.0;
    }
  }

  /// Mock delete operation
  Future<void> deletePlaylist(String playlistId) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
