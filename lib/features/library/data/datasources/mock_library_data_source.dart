import '../../../home/domain/entities/playlist_entity.dart';
import '../../../home/domain/entities/song_entity.dart';

/// Provides mock data for the Library feature.
/// Replace with real repository calls when the backend is ready.
class MockLibraryDataSource {
  // ── Saved (liked) playlists ────────────────────────────────────────────────
  static List<PlaylistEntity> getSavedPlaylists() => [
        const PlaylistEntity(
          id: 'lib-1',
          title: 'Chill Retail Vibes',
          description: 'Âm nhạc thư giãn cho giờ thấp điểm',
          coverUrl: 'https://picsum.photos/seed/chill_lib/400/400',
          isDownloaded: true,
          songs: _chillSongs,
        ),
        const PlaylistEntity(
          id: 'lib-2',
          title: 'Energy Rush',
          description: 'Bật lên khi cửa hàng đông khách',
          coverUrl: 'https://picsum.photos/seed/energy_lib/400/400',
          isDownloaded: true,
          songs: _energySongs,
        ),
        const PlaylistEntity(
          id: 'lib-3',
          title: 'Deep Work Focus',
          description: 'Nhạc tập trung cho ca tối',
          coverUrl: 'https://picsum.photos/seed/focus_lib/400/400',
          isDownloaded: false,
          songs: _focusSongs,
        ),
        const PlaylistEntity(
          id: 'lib-4',
          title: 'Weekend Brunch',
          description: 'Nhạc nhẹ cho buổi sáng cuối tuần',
          coverUrl: 'https://picsum.photos/seed/brunch_lib/400/400',
          isDownloaded: false,
          songs: _brunchSongs,
        ),
        const PlaylistEntity(
          id: 'lib-5',
          title: 'Late Night Jazz',
          description: 'Jazz tinh tế cho giờ đóng cửa',
          coverUrl: 'https://picsum.photos/seed/jazz_lib/400/400',
          isDownloaded: false,
          songs: [],
        ),
      ];

  // ── Blocked songs (blacklist) ──────────────────────────────────────────────
  static List<SongEntity> getBlockedSongs() => [
        const SongEntity(
          id: 'blocked-1',
          title: 'Offensive Track A',
          artist: 'Unknown Artist',
          duration: 214,
          coverUrl: 'https://picsum.photos/seed/blocked_1/400/400',
        ),
        const SongEntity(
          id: 'blocked-2',
          title: 'Too Loud For Store',
          artist: 'Heavy Metal Band',
          duration: 183,
          coverUrl: 'https://picsum.photos/seed/blocked_2/400/400',
        ),
        const SongEntity(
          id: 'blocked-3',
          title: 'Explicit Content',
          artist: 'Rap Artist XYZ',
          duration: 256,
          coverUrl: 'https://picsum.photos/seed/blocked_3/400/400',
        ),
      ];

  // ── Mock song lists ────────────────────────────────────────────────────────
  static const _chillSongs = [
    SongEntity(
        id: 'cs-1',
        title: 'Ocean Breeze',
        artist: 'Lo-Fi Beats',
        duration: 210),
    SongEntity(
        id: 'cs-2', title: 'Sunday Mood', artist: 'ChillHop', duration: 198),
    SongEntity(
        id: 'cs-3',
        title: 'Afternoon Rain',
        artist: 'Ambient Waves',
        duration: 245),
  ];

  static const _energySongs = [
    SongEntity(
        id: 'es-1', title: 'Peak Hour', artist: 'Electro Drive', duration: 175),
    SongEntity(id: 'es-2', title: 'Rush', artist: 'Upbeat Co.', duration: 188),
  ];

  static const _focusSongs = [
    SongEntity(
        id: 'fs-1', title: 'Deep Blue', artist: 'Focus Lab', duration: 320),
    SongEntity(
        id: 'fs-2', title: 'Flow State', artist: 'Study Beats', duration: 290),
    SongEntity(
        id: 'fs-3', title: 'The Zone', artist: 'Ambient Works', duration: 355),
    SongEntity(
        id: 'fs-4',
        title: 'Clear Mind',
        artist: 'Mindful Audio',
        duration: 270),
  ];

  static const _brunchSongs = [
    SongEntity(
        id: 'br-1',
        title: 'Good Morning',
        artist: 'Acoustic Trio',
        duration: 195),
    SongEntity(
        id: 'br-2',
        title: 'Bossa Light',
        artist: 'Café Ensemble',
        duration: 212),
  ];
}
