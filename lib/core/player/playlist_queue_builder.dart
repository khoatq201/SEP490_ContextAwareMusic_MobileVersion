import '../../features/playlists/domain/entities/api_playlist.dart';
import '../../features/space_control/domain/entities/track.dart';

List<Track> buildPlaylistQueue(ApiPlaylist playlist) {
  final playlistTracks = playlist.tracks ?? const [];
  if (playlistTracks.isEmpty) return const [];

  final totalDurationSeconds = playlist.resolvedTotalDurationSeconds;

  return List<Track>.generate(playlistTracks.length, (index) {
    final playlistTrack = playlistTracks[index];
    final currentOffset = playlistTrack.seekOffsetSeconds;
    final nextOffset = index < playlistTracks.length - 1
        ? playlistTracks[index + 1].seekOffsetSeconds
        : null;

    int? resolvedDuration;
    if (nextOffset != null && nextOffset > currentOffset) {
      resolvedDuration = nextOffset - currentOffset;
    } else if (index == playlistTracks.length - 1 &&
        totalDurationSeconds != null &&
        totalDurationSeconds > currentOffset) {
      resolvedDuration = totalDurationSeconds - currentOffset;
    }

    final fallbackDuration = playlistTrack.effectiveDuration;
    final duration = (resolvedDuration != null && resolvedDuration > 0)
        ? resolvedDuration
        : (fallbackDuration > 0 ? fallbackDuration : null);

    return Track(
      id: playlistTrack.trackId,
      title: playlistTrack.title ?? 'Unknown Track',
      artist: playlistTrack.artist ?? 'Unknown Artist',
      fileUrl: '',
      moodTags: const [],
      duration: duration,
      albumArt: playlistTrack.coverImageUrl,
      seekOffsetSeconds: currentOffset,
    );
  });
}
