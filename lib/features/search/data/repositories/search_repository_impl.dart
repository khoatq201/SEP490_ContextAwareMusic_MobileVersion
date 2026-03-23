import 'package:flutter/material.dart';
import '../../../home/domain/entities/playlist_entity.dart';
import '../../../home/domain/entities/song_entity.dart';
import '../../../moods/data/datasources/mood_remote_datasource.dart';
import '../../../playlists/data/datasources/playlist_remote_datasource.dart';
import '../../../tracks/data/datasources/track_remote_datasource.dart';
import '../../domain/entities/album_entity.dart';
import '../../domain/entities/artist_entity.dart';
import '../../domain/entities/search_category.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';

/// Real implementation that delegates to Playlists, Tracks and Moods APIs.
class SearchRepositoryImpl implements SearchRepository {
  final PlaylistRemoteDataSource playlistDataSource;
  final TrackRemoteDataSource trackDataSource;
  final MoodRemoteDataSource moodDataSource;

  SearchRepositoryImpl({
    required this.playlistDataSource,
    required this.trackDataSource,
    required this.moodDataSource,
  });

  // â”€â”€â”€ Mood colour / icon map (best-effort) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const _moodColors = <String, Color>{
    'happy': Color(0xFFF97316),
    'sad': Color(0xFF3B82F6),
    'energetic': Color(0xFFEF4444),
    'calm': Color(0xFF22C55E),
    'romantic': Color(0xFFEC4899),
    'focus': Color(0xFF8B5CF6),
    'chill': Color(0xFF06B6D4),
    'party': Color(0xFFF59E0B),
  };

  static const _moodIcons = <String, IconData>{
    'happy': Icons.sentiment_very_satisfied,
    'sad': Icons.sentiment_very_dissatisfied,
    'energetic': Icons.bolt,
    'calm': Icons.spa,
    'romantic': Icons.favorite,
    'focus': Icons.psychology,
    'chill': Icons.waves,
    'party': Icons.celebration,
  };

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // Repository methods
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  @override
  Future<List<SearchCategory>> getCategories() async {
    final moods = await moodDataSource.getMoods();
    return moods.map((m) {
      final key = m.moodType?.name.toLowerCase() ?? '';
      return SearchCategory(
        id: m.id,
        name: m.name,
        color: _moodColors[key] ?? const Color(0xFF6B7280),
        icon: _moodIcons[key] ?? Icons.music_note,
      );
    }).toList();
  }

  @override
  Future<List<SearchResult>> search(String query) async {
    if (query.isEmpty) return [];

    final results = <SearchResult>[];

    // Search playlists by name
    final playlistResp = await playlistDataSource.getPlaylists(
      page: 1,
      pageSize: 10,
      search: query,
    );

    for (final p in playlistResp.items) {
      results.add(SearchResult(
        id: p.id,
        title: p.name,
        subtitle: 'PLAYLIST â€¢ ${p.moodName ?? ''}',
        imageUrl: null,
        type: SearchResultType.playlist,
      ));
    }

    // Search tracks by title / artist
    final trackResp = await trackDataSource.getTracks(
      page: 1,
      pageSize: 20,
      search: query,
    );

    for (final t in trackResp.items) {
      results.add(SearchResult(
        id: t.id,
        title: t.title,
        subtitle: t.artist ?? 'Unknown',
        imageUrl: t.coverImageUrl,
        type: SearchResultType.song,
        duration: t.formattedDuration,
        durationSeconds: t.durationSec,
        streamUrl: t.hlsUrl,
      ));
    }

    return results;
  }

  @override
  Future<List<SearchResult>> searchByType(
      String query, SearchResultType type) async {
    final all = await search(query);
    return all.where((r) => r.type == type).toList();
  }

  @override
  Future<ArtistEntity> getArtistDetail(String artistId) async {
    // No artist endpoint yet â€” search tracks by artist name
    final trackResp = await trackDataSource.getTracks(
      page: 1,
      pageSize: 20,
      search: artistId,
    );
    final songs = trackResp.items
        .map((t) => SongEntity(
              id: t.id,
              title: t.title,
              artist: t.artist ?? 'Unknown',
              duration: t.durationSec ?? 0,
              coverUrl: t.coverImageUrl,
              streamUrl: t.hlsUrl,
            ))
        .toList();

    return ArtistEntity(
      id: artistId,
      name: artistId,
      popularSongs: songs,
    );
  }

  @override
  Future<AlbumEntity> getAlbumDetail(String albumId) async {
    // No album endpoint â€” return empty placeholder
    return AlbumEntity(id: albumId, name: albumId, artistName: '');
  }

  @override
  Future<PlaylistEntity> getPlaylistDetail(String playlistId) async {
    final detail = await playlistDataSource.getPlaylistById(playlistId);
    return PlaylistEntity(
      id: detail.id,
      title: detail.name,
      description: detail.description,
      coverUrl: null,
      songs: (detail.tracks ?? [])
          .map((t) => SongEntity(
                id: t.trackId,
                title: t.title ?? 'Unknown',
                artist: t.artist ?? 'Unknown',
                duration: t.effectiveDuration,
                coverUrl: t.coverImageUrl,
              ))
          .toList(),
    );
  }

  @override
  Future<List<PlaylistEntity>> getCategoryPlaylists(String categoryId) async {
    // categoryId = moodId
    final resp = await playlistDataSource.getPlaylists(
      page: 1,
      pageSize: 20,
      moodId: categoryId,
    );

    return resp.items
        .map((p) => PlaylistEntity(
              id: p.id,
              title: p.name,
              description: p.description,
              coverUrl: null,
              songs: const [],
            ))
        .toList();
  }

  @override
  Future<List<PlaylistEntity>> getFeaturedPlaylists() async {
    // Fetch default/featured playlists
    final resp = await playlistDataSource.getPlaylists(
      page: 1,
      pageSize: 10,
      isDefault: true,
    );

    // If no defaults, just return first page of all playlists
    final items = resp.items.isNotEmpty
        ? resp.items
        : (await playlistDataSource.getPlaylists(page: 1, pageSize: 10)).items;

    return items
        .map((p) => PlaylistEntity(
              id: p.id,
              title: p.name,
              description: p.description,
              coverUrl: null,
              songs: const [],
            ))
        .toList();
  }
}

// =============================================================================
// MOCK DATA — commented out for reference / fallback.
// Uncomment and use SearchMockRepositoryImpl if you need offline testing
// without a running backend.
// =============================================================================

// /// Mock implementation of [SearchRepository] with hardcoded data.
// /// Useful for UI development, demos, and offline testing.
// class SearchMockRepositoryImpl implements SearchRepository {
//
//   // ─── Mock song pool (reusable across playlists, albums, search) ─────────
//   static const _mockSongs = [
//     SongEntity(
//         id: 's1',
//         title: 'Attention',
//         artist: 'Charlie Puth',
//         duration: 211,
//         coverUrl: 'https://picsum.photos/seed/attention/200'),
//     SongEntity(
//         id: 's2',
//         title: 'We Don\'t Talk Anymore',
//         artist: 'Charlie Puth, Selena Gomez',
//         duration: 217,
//         coverUrl: 'https://picsum.photos/seed/wdta/200'),
//     SongEntity(
//         id: 's3',
//         title: 'See You Again',
//         artist: 'Wiz Khalifa ft. Charlie Puth',
//         duration: 237,
//         coverUrl: 'https://picsum.photos/seed/sya/200'),
//     SongEntity(
//         id: 's4',
//         title: 'Cha Cha Cha',
//         artist: 'Käärijä',
//         duration: 178,
//         coverUrl: 'https://picsum.photos/seed/chacha/200'),
//     SongEntity(
//         id: 's5',
//         title: 'CHA CHA',
//         artist: 'Francis, Sobel',
//         duration: 195,
//         coverUrl: 'https://picsum.photos/seed/chacha2/200'),
//     SongEntity(
//         id: 's6',
//         title: 'Cha Cha',
//         artist: 'Freddie Dredd',
//         duration: 143,
//         coverUrl: 'https://picsum.photos/seed/chacha3/200'),
//     SongEntity(
//         id: 's7',
//         title: 'Bongo Cha Cha Cha',
//         artist: 'Goodboys',
//         duration: 162,
//         coverUrl: 'https://picsum.photos/seed/bongo/200'),
//     SongEntity(
//         id: 's8',
//         title: 'Transcendental Cha Cha Cha',
//         artist: 'Tom Cardy',
//         duration: 198,
//         coverUrl: 'https://picsum.photos/seed/trans/200'),
//     SongEntity(
//         id: 's9',
//         title: 'Non, je ne regrette rien',
//         artist: 'Édith Piaf',
//         duration: 142,
//         coverUrl: 'https://picsum.photos/seed/piaf/200'),
//     SongEntity(
//         id: 's10',
//         title: 'Place des grands hommes',
//         artist: 'Patrick Bruel',
//         duration: 268,
//         coverUrl: 'https://picsum.photos/seed/bruel/200'),
//     SongEntity(
//         id: 's11',
//         title: 'Et si tu n\'existais pas',
//         artist: 'Joe Dassin',
//         duration: 206,
//         coverUrl: 'https://picsum.photos/seed/dassin/200'),
//     SongEntity(
//         id: 's12',
//         title: 'Light Switch',
//         artist: 'Charlie Puth',
//         duration: 189,
//         coverUrl: 'https://picsum.photos/seed/lightswitch/200'),
//   ];
//
//   // ─── Mock categories (browsable moods / genres) ─────────────────────────
//   static final List<SearchCategory> _mockCategories = [
//     const SearchCategory(
//         id: 'charts',    name: 'Charts',     color: Color(0xFF1A1A2E), icon: Icons.bar_chart),
//     const SearchCategory(
//         id: 'classical', name: 'Classical',  color: Color(0xFF795548), icon: Icons.queue_music),
//     const SearchCategory(
//         id: 'mainstream',name: 'Mainstream', color: Color(0xFF2196F3), icon: Icons.trending_up),
//     const SearchCategory(
//         id: 'jazz',      name: 'Jazz',       color: Color(0xFF9C27B0), icon: Icons.piano),
//     const SearchCategory(
//         id: 'pop',       name: 'Pop',        color: Color(0xFFE91E63), icon: Icons.music_note),
//     const SearchCategory(
//         id: 'chill',     name: 'Chill',      color: Color(0xFF2196F3), icon: Icons.waves),
//     const SearchCategory(
//         id: 'workout',   name: 'Workout',    color: Color(0xFFFF5722), icon: Icons.fitness_center),
//     const SearchCategory(
//         id: 'focus',     name: 'Focus',      color: Color(0xFF4CAF50), icon: Icons.psychology),
//     const SearchCategory(
//         id: 'rock',      name: 'Rock',       color: Color(0xFF607D8B), icon: Icons.electric_bolt),
//     const SearchCategory(
//         id: 'electronic',name: 'Electronic', color: Color(0xFF00BCD4), icon: Icons.graphic_eq),
//   ];
//
//   // ─── Mock artists (for artist detail pages) ────────────────────────────
//   static final _mockArtists = <String, ArtistEntity>{
//     'artist-charlie': ArtistEntity(
//       id: 'artist-charlie',
//       name: 'Charlie Puth',
//       imageUrl: 'https://picsum.photos/seed/charlie/400',
//       bio: 'Charles Otto Puth Jr. is an American singer, songwriter, and record producer.',
//       popularSongs: [_mockSongs[0], _mockSongs[1], _mockSongs[2], _mockSongs[11]],
//       albums: [
//         AlbumEntity(
//           id: 'album-voicenotes', name: 'Voicenotes', artistName: 'Charlie Puth',
//           coverUrl: 'https://picsum.photos/seed/voicenotes/300', releaseYear: 2018,
//           songs: [_mockSongs[0], _mockSongs[1]],
//         ),
//         AlbumEntity(
//           id: 'album-charlie', name: 'Charlie', artistName: 'Charlie Puth',
//           coverUrl: 'https://picsum.photos/seed/charliealbum/300', releaseYear: 2022,
//           songs: [_mockSongs[11]],
//         ),
//       ],
//     ),
//     'artist-calvin': const ArtistEntity(id: 'artist-calvin', name: 'Calvin Harris',
//         imageUrl: 'https://picsum.photos/seed/calvin/400'),
//     'artist-charli': const ArtistEntity(id: 'artist-charli', name: 'Charli XCX',
//         imageUrl: 'https://picsum.photos/seed/charli/400'),
//     'artist-chase':  const ArtistEntity(id: 'artist-chase',  name: 'Chase Atlantic',
//         imageUrl: 'https://picsum.photos/seed/chase/400'),
//     'artist-chance': const ArtistEntity(id: 'artist-chance', name: 'Chance Peña',
//         imageUrl: 'https://picsum.photos/seed/chance/400'),
//     'artist-tate':   const ArtistEntity(id: 'artist-tate',   name: 'Tate McRae',
//         imageUrl: 'https://picsum.photos/seed/tate/400'),
//   };
//
//   // ─── Mock albums ───────────────────────────────────────────────────────
//   static final _mockAlbums = <AlbumEntity>[
//     AlbumEntity(id: 'album-chacha',  name: 'Cha Cha Cha',       artistName: 'Käärijä',
//         coverUrl: 'https://picsum.photos/seed/chachaalbum/300',  releaseYear: 2023, songs: [_mockSongs[3]]),
//     AlbumEntity(id: 'album-chacha2', name: 'Cha Cha',           artistName: 'Freddie Dredd',
//         coverUrl: 'https://picsum.photos/seed/chachaalbum2/300', releaseYear: 2019, songs: [_mockSongs[5]]),
//     AlbumEntity(id: 'album-voicenotes', name: 'Voicenotes',     artistName: 'Charlie Puth',
//         coverUrl: 'https://picsum.photos/seed/voicenotes/300',   releaseYear: 2018, songs: [_mockSongs[0], _mockSongs[1]]),
//     AlbumEntity(id: 'album-bongo',   name: 'Bongo Cha Cha Cha', artistName: 'Goodboys',
//         coverUrl: 'https://picsum.photos/seed/bongoalbum/300',   releaseYear: 2021, songs: [_mockSongs[6]]),
//   ];
//
//   // ─── Mock playlists (for featured / category detail) ───────────────────
//   static final _mockPlaylists = <PlaylistEntity>[
//     PlaylistEntity(id: 'pl-chansons', title: 'Chansons à la Carte',
//         description: 'Timeless French tunes that pair perfectly with candlelight.',
//         coverUrl: 'https://picsum.photos/seed/chansons/300',
//         songs: [_mockSongs[8], _mockSongs[9], _mockSongs[10]]),
//     PlaylistEntity(id: 'pl-chanson-fr', title: 'Chanson Française',
//         description: 'Les plus grandes mélodies de la chanson française.',
//         coverUrl: 'https://picsum.photos/seed/chansonf/300',
//         songs: [_mockSongs[9], _mockSongs[10]]),
//     PlaylistEntity(id: 'pl-chanson-acoustic', title: 'Chanson acoustique joyeuse',
//         description: 'Chanson pop française acoustique pour une ambiance légère.',
//         coverUrl: 'https://picsum.photos/seed/acoustic/300',
//         songs: [_mockSongs[8]]),
//     PlaylistEntity(id: 'pl-charleston', title: 'Charleston Dance Studio',
//         description: 'Upbeat swing from the 20s.',
//         coverUrl: 'https://picsum.photos/seed/charleston/300', songs: const []),
//     PlaylistEntity(id: 'pl-best-charlie', title: 'Best of Charlie Puth',
//         description: 'All the biggest hits from Charlie Puth.',
//         coverUrl: 'https://picsum.photos/seed/bestcharlie/300',
//         songs: [_mockSongs[0], _mockSongs[1], _mockSongs[2], _mockSongs[11]]),
//   ];
//
//   // ═══════════════════════════════════════════════════════════════════════════
//   // Repository methods
//   // ═══════════════════════════════════════════════════════════════════════════
//
//   @override
//   Future<List<SearchCategory>> getCategories() async {
//     await Future.delayed(const Duration(milliseconds: 300));
//     return _mockCategories;
//   }
//
//   @override
//   Future<List<SearchResult>> search(String query) async {
//     await Future.delayed(const Duration(milliseconds: 400));
//     if (query.isEmpty) return [];
//     final q = query.toLowerCase();
//     final results = <SearchResult>[];
//
//     for (final artist in _mockArtists.values) {
//       if (artist.name.toLowerCase().contains(q)) {
//         results.add(SearchResult(id: artist.id, title: artist.name,
//             subtitle: 'ARTIST', imageUrl: artist.imageUrl, type: SearchResultType.artist));
//       }
//     }
//     for (final pl in _mockPlaylists) {
//       if (pl.title.toLowerCase().contains(q)) {
//         results.add(SearchResult(id: pl.id, title: pl.title,
//             subtitle: 'PLAYLIST • ${pl.description ?? ''}', imageUrl: pl.coverUrl,
//             type: SearchResultType.playlist));
//       }
//     }
//     for (final song in _mockSongs) {
//       if (song.title.toLowerCase().contains(q) || song.artist.toLowerCase().contains(q)) {
//         results.add(SearchResult(id: song.id, title: song.title,
//             subtitle: song.artist, imageUrl: song.coverUrl,
//             type: SearchResultType.song, duration: song.formattedDuration));
//       }
//     }
//     for (final album in _mockAlbums) {
//       if (album.name.toLowerCase().contains(q) || album.artistName.toLowerCase().contains(q)) {
//         results.add(SearchResult(id: album.id, title: album.name,
//             subtitle: '${album.artistName} • ${album.releaseYear ?? ''}',
//             imageUrl: album.coverUrl, type: SearchResultType.album));
//       }
//     }
//     for (final cat in _mockCategories) {
//       if (cat.name.toLowerCase().contains(q)) {
//         results.add(SearchResult(id: cat.id, title: cat.name,
//             subtitle: 'CATEGORY', imageUrl: cat.imageUrl, type: SearchResultType.category));
//       }
//     }
//     return results;
//   }
//
//   @override
//   Future<List<SearchResult>> searchByType(String query, SearchResultType type) async {
//     final all = await search(query);
//     return all.where((r) => r.type == type).toList();
//   }
//
//   @override
//   Future<ArtistEntity> getArtistDetail(String artistId) async {
//     await Future.delayed(const Duration(milliseconds: 300));
//     return _mockArtists[artistId] ?? const ArtistEntity(id: 'unknown', name: 'Unknown Artist');
//   }
//
//   @override
//   Future<AlbumEntity> getAlbumDetail(String albumId) async {
//     await Future.delayed(const Duration(milliseconds: 300));
//     return _mockAlbums.firstWhere((a) => a.id == albumId,
//         orElse: () => const AlbumEntity(id: 'unknown', name: 'Unknown', artistName: ''));
//   }
//
//   @override
//   Future<PlaylistEntity> getPlaylistDetail(String playlistId) async {
//     await Future.delayed(const Duration(milliseconds: 300));
//     return _mockPlaylists.firstWhere((p) => p.id == playlistId,
//         orElse: () => const PlaylistEntity(id: 'unknown', title: 'Unknown'));
//   }
//
//   @override
//   Future<List<PlaylistEntity>> getCategoryPlaylists(String categoryId) async {
//     await Future.delayed(const Duration(milliseconds: 300));
//     return _mockPlaylists.take(3).toList();
//   }
//
//   @override
//   Future<List<PlaylistEntity>> getFeaturedPlaylists() async {
//     await Future.delayed(const Duration(milliseconds: 300));
//     return [_mockPlaylists[4], _mockPlaylists[0]];
//   }
// }
