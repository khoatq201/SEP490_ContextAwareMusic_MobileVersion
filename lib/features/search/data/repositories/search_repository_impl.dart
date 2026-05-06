import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/enums/entity_status_enum.dart';
import '../../../home/domain/entities/playlist_entity.dart';
import '../../../home/domain/entities/song_entity.dart';
import '../../../moods/data/datasources/mood_remote_datasource.dart';
import '../../../playlists/data/models/api_playlist_model.dart';
import '../../../playlists/data/datasources/playlist_remote_datasource.dart';
import '../../../playlists/domain/entities/api_playlist.dart';
import '../../../tracks/data/models/api_track_model.dart';
import '../../../tracks/data/datasources/track_remote_datasource.dart';
import '../../../tracks/domain/entities/track_copyright_clearance_status.dart';
import '../../../tracks/domain/entities/track_filter.dart';
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
  Future<Either<Failure, List<SearchResult>>> search(
    String query, {
    bool playableTracksOnly = false,
  }) async {
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
      final playlistDetailsById = await _loadPlaylistDetails(
        playlistResp.items,
      );

      _addPlaylistResults(results, playlistResp.items, playlistDetailsById);
      final hasPlaylistHit = playlistResp.items.any(
        (playlist) => _matchesPlaylistQuery(playlist, normalizedQuery),
      );

      final trackResp = await trackDataSource.getTracks(
        filter: _trackSearchFilter(
          page: 1,
          pageSize: 20,
          search: query,
          playableTracksOnly: playableTracksOnly,
        ),
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
        final fallbackPlaylistDetailsById = await _loadPlaylistDetails(
          fallbackPlaylists,
        );

        _addPlaylistResults(
          results,
          fallbackPlaylists,
          fallbackPlaylistDetailsById,
        );
      }

      if (!hasTrackHit || matchingArtistTracks.isEmpty) {
        final fallbackTrackResp = await trackDataSource.getTracks(
          filter: _trackSearchFilter(
            page: 1,
            pageSize: _fallbackTrackSearchPageSize,
            playableTracksOnly: playableTracksOnly,
          ),
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
    SearchResultType type, {
    bool playableTracksOnly = false,
  }) async {
    final result = await search(
      query,
      playableTracksOnly: playableTracksOnly,
    );
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
              brandId: track.brandId,
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
          brandId: detail.brandId,
          title: detail.name,
          description: detail.description,
          coverUrl: null,
          songs: (detail.tracks ?? [])
              .map(
                (track) => SongEntity(
                  id: track.trackId,
                  brandId: track.brandId,
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
      final detailsById = await _loadPlaylistDetails(resp.items);

      return Right(
        resp.items
            .map(
              (playlist) => _playlistEntityFromApi(
                playlist,
                detailsById[playlist.id],
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
  Future<Either<Failure, List<SearchResult>>> getCategoryTracks(
    String categoryId, {
    bool playableTracksOnly = false,
  }) async {
    try {
      final resp = await trackDataSource.getTracks(
        filter: _trackSearchFilter(
          page: 1,
          pageSize: 20,
          moodId: categoryId,
          playableTracksOnly: playableTracksOnly,
        ),
      );

      final results = <String, SearchResult>{};
      _addTrackResults(results, resp.items);
      return Right(results.values.toList(growable: false));
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not load tracks for this category.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<SearchResult>>> getGenreTracks(
    String genre, {
    bool playableTracksOnly = false,
  }) async {
    try {
      final resp = await trackDataSource.getTracks(
        filter: _trackSearchFilter(
          page: 1,
          pageSize: 20,
          genre: genre,
          playableTracksOnly: playableTracksOnly,
        ),
      );

      final results = <String, SearchResult>{};
      _addTrackResults(results, resp.items);
      return Right(results.values.toList(growable: false));
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not load tracks for this genre.',
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
      final detailsById = await _loadPlaylistDetails(items);

      return Right(
        items
            .map(
              (playlist) => _playlistEntityFromApi(
                playlist,
                detailsById[playlist.id],
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
    Map<String, ApiPlaylist> detailsById,
  ) {
    for (final playlist in playlists) {
      final coverUrls = _trackCoverUrlsFromPlaylist(detailsById[playlist.id]);
      final key = 'playlist:${playlist.id}';
      results.putIfAbsent(
        key,
        () => SearchResult(
          id: playlist.id,
          brandId: playlist.brandId,
          title: playlist.name,
          subtitle: 'PLAYLIST - ${playlist.moodName ?? ''}',
          imageUrl: null,
          playlistCoverUrls: coverUrls,
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
          brandId: track.brandId,
          title: track.title,
          subtitle: track.artist ?? 'Unknown',
          imageUrl: track.coverImageUrl,
          type: SearchResultType.song,
          duration: track.formattedDuration,
          durationSeconds: track.durationSec,
          streamUrl: track.hlsUrl,
          copyrightClearanceStatus: track.copyrightClearanceStatus,
          trackStatus: track.status,
        ),
      );
    }
  }

  TrackFilter _trackSearchFilter({
    required int page,
    required int pageSize,
    String? search,
    String? moodId,
    String? genre,
    required bool playableTracksOnly,
  }) {
    return TrackFilter(
      page: page,
      pageSize: pageSize,
      search: search,
      moodId: moodId,
      genre: genre,
      status: playableTracksOnly ? EntityStatusEnum.active : null,
      copyrightClearanceStatuses: playableTracksOnly
          ? const [
              TrackCopyrightClearanceStatus.notApplicable,
              TrackCopyrightClearanceStatus.cleared,
            ]
          : null,
    );
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
          brandId: track.brandId,
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

  Future<Map<String, ApiPlaylist>> _loadPlaylistDetails(
    List<ApiPlaylist> playlists,
  ) async {
    final entries = await Future.wait(
      playlists.map((playlist) async {
        try {
          final detail = await playlistDataSource.getPlaylistById(playlist.id);
          return MapEntry(playlist.id, detail);
        } catch (_) {
          return null;
        }
      }),
    );

    return {
      for (final entry in entries)
        if (entry != null) entry.key: entry.value,
    };
  }

  PlaylistEntity _playlistEntityFromApi(
    ApiPlaylist playlist,
    ApiPlaylist? detail,
  ) {
    return PlaylistEntity(
      id: playlist.id,
      brandId: playlist.brandId,
      title: playlist.name,
      description: playlist.description,
      coverUrl: null,
      songs: _songsFromPlaylistDetail(detail),
      overrideTrackCount: playlist.trackCount,
    );
  }

  List<SongEntity> _songsFromPlaylistDetail(ApiPlaylist? detail) {
    final tracks = detail?.tracks;
    if (tracks == null || tracks.isEmpty) return const [];
    return tracks
        .map(
          (track) => SongEntity(
            id: track.trackId,
            brandId: track.brandId,
            title: track.title ?? 'Unknown',
            artist: track.artist ?? 'Unknown',
            duration: track.effectiveDuration,
            coverUrl: track.coverImageUrl,
            streamUrl: track.hlsUrl,
          ),
        )
        .toList(growable: false);
  }

  List<String> _trackCoverUrlsFromPlaylist(ApiPlaylist? detail) {
    final tracks = detail?.tracks;
    if (tracks == null || tracks.isEmpty) return const [];
    return tracks
        .map((track) => track.coverImageUrl?.trim())
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
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
