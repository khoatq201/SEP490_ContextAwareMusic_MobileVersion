import 'package:flutter/material.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/entities/playlist_entity.dart';
import '../../domain/entities/sensor_entity.dart';
import '../../domain/entities/song_entity.dart';

/// Raw in-memory mock data source for the Home feature.
/// All methods simulate a network round-trip with a 1-second delay.
/// Replace with a real [HomeRemoteDataSource] when the API is available.
class MockHomeDataSource {
  // ── Unsplash random image helpers ────────────────────────────────────────
  static String _img(String keyword, {int seed = 1}) =>
      'https://picsum.photos/seed/${keyword}_$seed/400/400';

  // ── Sensors ──────────────────────────────────────────────────────────────
  Future<List<SensorEntity>> getSensorData() async {
    await Future.delayed(const Duration(seconds: 1));
    return const [
      SensorEntity(
        id: 'sensor-temp',
        name: 'Nhiệt độ',
        value: '32°C',
        icon: Icons.thermostat_outlined,
        accentColor: Color(0xFFF97316), // orange
        badge: 'Ổn định',
      ),
      SensorEntity(
        id: 'sensor-humidity',
        name: 'Độ ẩm',
        value: '65%',
        icon: Icons.water_drop_outlined,
        accentColor: Color(0xFF38BDF8), // sky
        badge: 'Tối ưu',
      ),
      SensorEntity(
        id: 'sensor-crowd',
        name: 'Lượng khách',
        value: 'Trung bình',
        icon: Icons.people_outline,
        accentColor: Color(0xFFA78BFA), // violet
        badge: 'Live',
      ),
      SensorEntity(
        id: 'sensor-noise',
        name: 'Tiếng ồn',
        value: '58 dB',
        icon: Icons.volume_up_outlined,
        accentColor: Color(0xFF34D399), // emerald
        badge: 'Vừa',
      ),
    ];
  }

  // ── Categories ───────────────────────────────────────────────────────────
  Future<List<CategoryEntity>> getCategories() async {
    await Future.delayed(const Duration(seconds: 1));

    // ── Shared songs pool ─────────────────────────────────────────────────
    final chill1 = SongEntity(
      id: 'song-c1',
      title: 'Chill Morning',
      artist: 'Lo-Fi Beats',
      duration: 212,
      coverUrl: _img('chill', seed: 1),
    );
    final chill2 = SongEntity(
      id: 'song-c2',
      title: 'Coffee Break',
      artist: 'Café Vibes',
      duration: 185,
      coverUrl: _img('coffee', seed: 2),
    );
    final energy1 = SongEntity(
      id: 'song-e1',
      title: 'Upbeat Rush',
      artist: 'Retail Music Co.',
      duration: 198,
      coverUrl: _img('energy', seed: 3),
    );
    final energy2 = SongEntity(
      id: 'song-e2',
      title: 'Power Hour',
      artist: 'Sport Sounds',
      duration: 230,
      coverUrl: _img('sport', seed: 4),
    );
    final pop1 = SongEntity(
      id: 'song-p1',
      title: 'Summer Pop',
      artist: 'Top Charts',
      duration: 204,
      coverUrl: _img('summer', seed: 5),
    );
    final pop2 = SongEntity(
      id: 'song-p2',
      title: 'Neon Nights',
      artist: 'Synthwave',
      duration: 245,
      coverUrl: _img('neon', seed: 6),
    );
    final focus1 = SongEntity(
      id: 'song-f1',
      title: 'Deep Focus',
      artist: 'Study Beats',
      duration: 320,
      coverUrl: _img('focus', seed: 7),
    );
    final focus2 = SongEntity(
      id: 'song-f2',
      title: 'Ambient Space',
      artist: 'Brown Noise',
      duration: 600,
      coverUrl: _img('space', seed: 8),
    );

    // ── Category 1: Top categories for you ───────────────────────────────
    final topForYou = CategoryEntity(
      id: 'cat-top',
      title: 'Top categories for you',
      playlists: [
        PlaylistEntity(
          id: 'pl-chill',
          title: 'Chill Retail',
          description: 'Âm nhạc nhẹ nhàng cho không gian mua sắm',
          coverUrl: _img('chill', seed: 10),
          songs: [chill1, chill2, focus1],
        ),
        PlaylistEntity(
          id: 'pl-energy',
          title: 'Energy Boost',
          description: 'Nhịp nhanh, tăng năng lượng cho khách hàng',
          coverUrl: _img('energy', seed: 11),
          songs: [energy1, energy2, pop1],
        ),
        PlaylistEntity(
          id: 'pl-focus',
          title: 'Deep Focus',
          description: 'Âm nhạc giúp tập trung, phù hợp khu vực làm việc',
          coverUrl: _img('focus', seed: 12),
          songs: [focus1, focus2, chill1],
        ),
        PlaylistEntity(
          id: 'pl-pop',
          title: 'Pop Hits',
          description: 'Những bài nhạc pop thịnh hành',
          coverUrl: _img('pop', seed: 13),
          songs: [pop1, pop2, energy1],
        ),
      ],
    );

    // ── Category 2: Popular today ────────────────────────────────────────
    final popularToday = CategoryEntity(
      id: 'cat-popular',
      title: 'Popular today',
      playlists: [
        PlaylistEntity(
          id: 'pl-trending',
          title: 'Trending Sounds',
          description: 'Được phát nhiều nhất hôm nay',
          coverUrl: _img('trending', seed: 20),
          songs: [pop2, energy2, chill2],
        ),
        PlaylistEntity(
          id: 'pl-morning',
          title: 'Morning Opener',
          description: 'Bắt đầu ngày mới sôi động',
          coverUrl: _img('morning', seed: 21),
          songs: [chill1, energy1, focus2],
        ),
        PlaylistEntity(
          id: 'pl-evening',
          title: 'Evening Wind Down',
          description: 'Kết thúc ngày nhẹ nhàng',
          coverUrl: _img('sunset', seed: 22),
          songs: [focus1, chill2, pop1],
        ),
      ],
    );

    return [topForYou, popularToday];
  }
}
