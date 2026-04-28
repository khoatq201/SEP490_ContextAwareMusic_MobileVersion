import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../home/domain/entities/playlist_entity.dart';
import '../../../home/domain/entities/song_entity.dart';
import '../../../moods/data/datasources/mood_remote_datasource.dart';
import '../../../playlists/data/models/api_playlist_model.dart';
import '../../../playlists/data/datasources/playlist_remote_datasource.dart';
import '../../../tracks/data/models/api_track_model.dart';
import '../../../tracks/data/datasources/track_remote_datasource.dart';
import '../../domain/entities/album_entity.dart';
import '../../domain/entities/artist_entity.dart';
import '../../domain/entities/search_category.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  static const int _fallbackPlaylistSearchPageSize = 100;
  static const int _fallbackTrackSearchPageSize = 100;

  SearchRepositoryImpl({
    required this.playlistDataSource,
    required this.trackDataSource,
    required this.moodDataSource,
  });

  final PlaylistRemoteDataSource playlistDataSource;
  final TrackRemoteDataSource trackDataSource;
  final MoodRemoteDataSource moodDataSource;

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

  @override
  Future<Either<Failure, List<SearchCategory>>> getCategories() async {
    try {
      final moods = await moodDataSource.getMoods();
      return Right(
        moods.map((m) {
          final key = m.moodType?.name.toLowerCase() ?? '';
          return SearchCategory(
            id: m.id,
            name: m.name,
            color: _moodColors[key] ?? const Color(0xFF6B7280),
            icon: _moodIcons[key] ?? Icons.music_note,
          );
        }).toList(),
      );
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not load categories right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<SearchResult>>> search(String query) async {
    if (query.isEmpty) {
      return const Right(<SearchResult>[]);
    }

    try {
      final results = <String, SearchResult>{};
      final normalizedQuery = _normalizeSearchText(query);
      final playlistResp = await playlistDataSource.getPlaylists(
        page: 1,
        pageSize: 10,
        search: query,
      );

      _addPlaylistResults(results, playlistResp.items);
      final hasPlaylistHit = playlistResp.items.any(
        (playlist) => _matchesPlaylistQuery(playlist, normalizedQuery),
      );

      final trackResp = await trackDataSource.getTracks(
        page: 1,
        pageSize: 20,
        search: query,
      );

      _addTrackResults(results, trackResp.items);
      final matchingArtistTracks = trackResp.items
          .where(
              (track) => _matchesNormalizedQuery(track.artist, normalizedQuery))
          .toList(growable: false);
      final hasTrackHit = trackResp.items.any(
        (track) => _matchesTrackQuery(track, normalizedQuery),
      );
      _addArtistResults(
        results,
        matchingArtistTracks,
      );

      if (!hasPlaylistHit) {
        final fallbackPlaylistResp = await playlistDataSource.getPlaylists(
          page: 1,
          pageSize: _fallbackPlaylistSearchPageSize,
        );

        final fallbackPlaylists = fallbackPlaylistResp.items
            .where(
                (playlist) => _matchesPlaylistQuery(playlist, normalizedQuery))
            .toList(growable: false);

        _addPlaylistResults(results, fallbackPlaylists);
      }

      if (!hasTrackHit || matchingArtistTracks.isEmpty) {
        final fallbackTrackResp = await trackDataSource.getTracks(
          page: 1,
          pageSize: _fallbackTrackSearchPageSize,
        );
        final fallbackTracks = fallbackTrackResp.items
            .where((track) => _matchesTrackQuery(track, normalizedQuery))
            .toList(growable: false);
        final fallbackArtistTracks = fallbackTrackResp.items
            .where((track) =>
                _matchesNormalizedQuery(track.artist, normalizedQuery))
            .toList(growable: false);

        _addTrackResults(results, fallbackTracks);
        _addArtistResults(results, fallbackArtistTracks);
      }

      return Right(results.values.toList(growable: false));
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Search is unavailable right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<SearchResult>>> searchByType(
    String query,
    SearchResultType type,
  ) async {
    final result = await search(query);
    return result.map(
      (items) => items.where((item) => item.type == type).toList(),
    );
  }

  @override
  Future<Either<Failure, ArtistEntity>> getArtistDetail(String artistId) async {
    try {
      final trackResp = await trackDataSource.getTracks(
        page: 1,
        pageSize: 20,
        search: artistId,
      );
      final songs = trackResp.items
          .map(
            (track) => SongEntity(
              id: track.id,
              title: track.title,
              artist: track.artist ?? 'Unknown',
              duration: track.durationSec ?? 0,
              coverUrl: track.coverImageUrl,
              streamUrl: track.hlsUrl,
            ),
          )
          .toList();

      return Right(
        ArtistEntity(
          id: artistId,
          name: artistId,
          popularSongs: songs,
        ),
      );
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not load this artist right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, AlbumEntity>> getAlbumDetail(String albumId) async {
    try {
      return Right(AlbumEntity(id: albumId, name: albumId, artistName: ''));
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not load this album right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, PlaylistEntity>> getPlaylistDetail(
    String playlistId,
  ) async {
    try {
      final detail = await playlistDataSource.getPlaylistById(playlistId);
      return Right(
        PlaylistEntity(
          id: detail.id,
          title: detail.name,
          description: detail.description,
          coverUrl: null,
          songs: (detail.tracks ?? [])
              .map(
                (track) => SongEntity(
                  id: track.trackId,
                  title: track.title ?? 'Unknown',
                  artist: track.artist ?? 'Unknown',
                  duration: track.effectiveDuration,
                  coverUrl: track.coverImageUrl,
                ),
              )
              .toList(),
        ),
      );
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not load this playlist right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<PlaylistEntity>>> getCategoryPlaylists(
    String categoryId,
  ) async {
    try {
      final resp = await playlistDataSource.getPlaylists(
        page: 1,
        pageSize: 20,
        moodId: categoryId,
      );

      return Right(
        resp.items
            .map(
              (playlist) => PlaylistEntity(
                id: playlist.id,
                title: playlist.name,
                description: playlist.description,
                coverUrl: null,
                songs: const [],
              ),
            )
            .toList(),
      );
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not load playlists for this category.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<PlaylistEntity>>> getFeaturedPlaylists() async {
    try {
      final resp = await playlistDataSource.getPlaylists(
        page: 1,
        pageSize: 10,
        isDefault: true,
      );

      final items = resp.items.isNotEmpty
          ? resp.items
          : (await playlistDataSource.getPlaylists(page: 1, pageSize: 10))
              .items;

      return Right(
        items
            .map(
              (playlist) => PlaylistEntity(
                id: playlist.id,
                title: playlist.name,
                description: playlist.description,
                coverUrl: null,
                songs: const [],
              ),
            )
            .toList(),
      );
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Featured playlists are unavailable right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  void _addPlaylistResults(
    Map<String, SearchResult> results,
    List<ApiPlaylistModel> playlists,
  ) {
    for (final playlist in playlists) {
      final key = 'playlist:${playlist.id}';
      results.putIfAbsent(
        key,
        () => SearchResult(
          id: playlist.id,
          title: playlist.name,
          subtitle: 'PLAYLIST - ${playlist.moodName ?? ''}',
          imageUrl: null,
          type: SearchResultType.playlist,
        ),
      );
    }
  }

  void _addTrackResults(
    Map<String, SearchResult> results,
    List<ApiTrackModel> tracks,
  ) {
    for (final track in tracks) {
      final key = 'track:${track.id}';
      results.putIfAbsent(
        key,
        () => SearchResult(
          id: track.id,
          title: track.title,
          subtitle: track.artist ?? 'Unknown',
          imageUrl: track.coverImageUrl,
          type: SearchResultType.song,
          duration: track.formattedDuration,
          durationSeconds: track.durationSec,
          streamUrl: track.hlsUrl,
        ),
      );
    }
  }

  void _addArtistResults(
    Map<String, SearchResult> results,
    List<ApiTrackModel> tracks,
  ) {
    final uniqueArtists = <String>{};
    for (final track in tracks) {
      final artist = track.artist?.trim();
      if (artist == null || artist.isEmpty) continue;
      final normalizedArtist = _normalizeSearchText(artist);
      if (!uniqueArtists.add(normalizedArtist)) continue;
      final key = 'artist:$normalizedArtist';
      results.putIfAbsent(
        key,
        () => SearchResult(
          id: artist,
          title: artist,
          subtitle: 'Artist',
          imageUrl: track.coverImageUrl,
          type: SearchResultType.artist,
        ),
      );
    }
  }

  bool _matchesPlaylistQuery(
      ApiPlaylistModel playlist, String normalizedQuery) {
    final haystack = [
      playlist.name,
      playlist.description,
      playlist.moodName,
    ].whereType<String>().join(' ');
    return _matchesNormalizedQuery(haystack, normalizedQuery);
  }

  bool _matchesTrackQuery(ApiTrackModel track, String normalizedQuery) {
    final haystack = [
      track.title,
      track.artist,
      track.genre,
      track.moodName,
    ].whereType<String>().join(' ');
    return _matchesNormalizedQuery(haystack, normalizedQuery);
  }

  bool _matchesNormalizedQuery(String? source, String normalizedQuery) {
    if (source == null || source.trim().isEmpty || normalizedQuery.isEmpty) {
      return false;
    }
    return _normalizeSearchText(source).contains(normalizedQuery);
  }

  String _normalizeSearchText(String input) {
    const replacements = {
      'à': 'a',
      'á': 'a',
      'ả': 'a',
      'ã': 'a',
      'ạ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'ặ': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ậ': 'a',
      'è': 'e',
      'é': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ẹ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ệ': 'e',
      'ì': 'i',
      'í': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ị': 'i',
      'ò': 'o',
      'ó': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ọ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ộ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ợ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ụ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ự': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'ỵ': 'y',
      'đ': 'd',
    };
    final buffer = StringBuffer();
    for (final rune in input.trim().toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(replacements[char] ?? char);
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
