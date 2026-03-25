import '../../playlists/data/datasources/playlist_remote_datasource.dart';

Future<String?> createLibraryPlaylist({
  required PlaylistRemoteDataSource playlistDataSource,
  required String name,
  required String storeId,
  int listPageSize = 50,
}) async {
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    return null;
  }

  final mutationResult = await playlistDataSource.createPlaylist(
    PlaylistMutationRequest(
      name: trimmedName,
      storeId: storeId,
    ),
  );

  final createdId = mutationResult.id?.trim();
  if (createdId != null && createdId.isNotEmpty) {
    return createdId;
  }

  final playlists = await playlistDataSource.getPlaylists(
    page: 1,
    pageSize: listPageSize,
  );

  final normalizedTarget = trimmedName.toLowerCase();
  for (final playlist in playlists.items) {
    if (playlist.name.trim().toLowerCase() == normalizedTarget) {
      return playlist.id;
    }
  }

  return null;
}
