import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/offline_playlist.dart';

abstract class OfflinePlaylistRepository {
  /// Fetches available playlists from server
  Future<Either<Failure, List<OfflinePlaylist>>> getAvailablePlaylists();

  /// Triggers download process for a playlist
  /// Returns a stream of download progress updates
  Stream<Either<Failure, double>> downloadPlaylist(String playlistId);

  /// Deletes a locally stored playlist to free up space
  Future<Either<Failure, void>> deleteLocalPlaylist(String playlistId);

  /// Gets all downloaded playlists from local storage
  Future<Either<Failure, List<OfflinePlaylist>>> getDownloadedPlaylists();
}
