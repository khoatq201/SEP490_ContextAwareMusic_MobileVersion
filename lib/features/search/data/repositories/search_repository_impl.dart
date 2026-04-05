import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
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

class SearchRepositoryImpl implements SearchRepository {
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
      final results = <SearchResult>[];
      final playlistResp = await playlistDataSource.getPlaylists(
        page: 1,
        pageSize: 10,
        search: query,
      );

      for (final playlist in playlistResp.items) {
        results.add(
          SearchResult(
            id: playlist.id,
            title: playlist.name,
            subtitle: 'PLAYLIST - ${playlist.moodName ?? ''}',
            imageUrl: null,
            type: SearchResultType.playlist,
          ),
        );
      }

      final trackResp = await trackDataSource.getTracks(
        page: 1,
        pageSize: 20,
        search: query,
      );

      for (final track in trackResp.items) {
        results.add(
          SearchResult(
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

      return Right(results);
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
}
