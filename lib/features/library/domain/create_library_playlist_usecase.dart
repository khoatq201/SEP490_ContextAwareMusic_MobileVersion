import '../../playlists/data/datasources/playlist_remote_datasource.dart';

Future<String?> createLibraryPlaylist({
  required PlaylistRemoteDataSource playlistDataSource,
  required String name,
  String? storeId,
  String? brandId,
  String? description,
  String? moodId,
  bool? isDefault,
  List<String>? trackIds,
  bool createBrandWide = false,
  int listPageSize = 50,
}) async {
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    return null;
  }

  final trimmedStoreId = _trimOrNull(storeId);
  final trimmedBrandId = _trimOrNull(brandId);
  final normalizedDescription = _trimOrNull(description);
  final normalizedMoodId = _trimOrNull(moodId);
  final normalizedTrackIds = _normalizeTrackIds(trackIds);

  final mutationResult = await playlistDataSource.createPlaylist(
    PlaylistMutationRequest(
      name: trimmedName,
      storeId: trimmedStoreId,
      description: normalizedDescription,
      moodId: normalizedMoodId,
      isDefault: isDefault,
      trackIds: normalizedTrackIds,
      explicitBrandWide: createBrandWide,
    ),
  );

  final createdId = mutationResult.id?.trim();
  if (createdId != null && createdId.isNotEmpty) {
    return createdId;
  }

  final playlists = await playlistDataSource.getPlaylists(
    page: 1,
    pageSize: listPageSize,
    brandId: createBrandWide ? trimmedBrandId : null,
    storeId: createBrandWide ? null : trimmedStoreId,
    search: trimmedName,
  );

  final normalizedTarget = trimmedName.toLowerCase();
  for (final playlist in playlists.items) {
    if (playlist.name.trim().toLowerCase() == normalizedTarget) {
      return playlist.id;
    }
  }

  return null;
}

String? _trimOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

List<String>? _normalizeTrackIds(List<String>? values) {
  if (values == null) {
    return null;
  }

  final normalized = <String>[];
  final seen = <String>{};
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) {
      continue;
    }
    normalized.add(trimmed);
  }

  return normalized.isEmpty ? null : normalized;
}
