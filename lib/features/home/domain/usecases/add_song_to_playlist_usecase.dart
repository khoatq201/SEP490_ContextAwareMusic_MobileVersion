import '../entities/playlist_entity.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AddSongToPlaylistUseCase
//
// Domain-layer stub — wire this to a PlaylistRepository when backend is ready.
//
// Wiring checklist:
//   1. Create PlaylistRepository interface in domain/repositories/.
//   2. Implement it in data/repositories/ (API + local cache).
//   3. Register in injection_container.dart.
//   4. Uncomment the constructor and replace the throw below with the
//      repository call.
// ─────────────────────────────────────────────────────────────────────────────
class AddSongToPlaylistUseCase {
  // TODO: inject PlaylistRepository
  // final PlaylistRepository _repository;
  // const AddSongToPlaylistUseCase(this._repository);

  /// Adds the song identified by [songId] to the playlist identified by
  /// [playlistId].
  ///
  /// Returns the updated [PlaylistEntity] on success.
  /// Throws on failure (network error, not found, etc.).
  Future<PlaylistEntity> call({
    required String songId,
    required String playlistId,
  }) async {
    assert(songId.isNotEmpty, 'songId must not be empty');
    assert(playlistId.isNotEmpty, 'playlistId must not be empty');

    // TODO: replace with repository call:
    //   return _repository.addSongToPlaylist(
    //     songId: songId, playlistId: playlistId);
    throw UnimplementedError(
      'AddSongToPlaylistUseCase is not yet wired to a repository.\n'
      'See lib/features/home/domain/usecases/add_song_to_playlist_usecase.dart',
    );
  }
}
