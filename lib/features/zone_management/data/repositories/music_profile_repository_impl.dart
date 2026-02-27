import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/music_profile.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/repositories/music_profile_repository.dart';
import '../datasources/zone_mock_datasource.dart';

class MusicProfileRepositoryImpl implements MusicProfileRepository {
  final ZoneMockDataSource mockDataSource;

  MusicProfileRepositoryImpl({required this.mockDataSource});

  @override
  Future<Either<Failure, MusicProfile>> getProfileByZone(String zoneId) async {
    try {
      final profile = await mockDataSource.getMusicProfileByZone(zoneId);
      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('Failed to fetch music profile: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, MusicProfile>> getProfileById(String profileId) async {
    try {
      // For MVP, use zone ID as profile lookup
      final profile = await mockDataSource.getMusicProfileByZone(profileId);
      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('Failed to fetch music profile: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, MusicProfile>> updateProfile(
      MusicProfile profile) async {
    try {
      // Mock implementation - in production would call API
      await Future.delayed(const Duration(milliseconds: 500));
      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('Failed to update music profile: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> assignPlaylistToZone({
    required String zoneId,
    required String playlistId,
  }) async {
    try {
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 400));
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to assign playlist: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> removePlaylistFromZone({
    required String zoneId,
    required String playlistId,
  }) async {
    try {
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 400));
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to remove playlist: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateMoodMapping({
    required String zoneId,
    required Map<String, String> moodToPlaylistMap,
  }) async {
    try {
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 400));
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('Failed to update mood mapping: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateVolumeSettings({
    required String zoneId,
    required VolumeSettings volumeSettings,
  }) async {
    try {
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 300));
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('Failed to update volume settings: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateScheduleConfig({
    required String zoneId,
    required ScheduleConfig? scheduleConfig,
  }) async {
    try {
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 400));
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('Failed to update schedule config: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleAutoMoodDetection({
    required String zoneId,
    required bool enabled,
  }) async {
    try {
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 300));
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(
          'Failed to toggle auto mood detection: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Playlist>>> getAllPlaylists() async {
    try {
      final playlists = await mockDataSource.getAllPlaylists();
      return Right(playlists);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch playlists: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Playlist>> getPlaylistById(String playlistId) async {
    try {
      final playlist = await mockDataSource.getPlaylistById(playlistId);
      return Right(playlist);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch playlist: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Playlist>>> getPlaylistsByMood(
      String mood) async {
    try {
      final allPlaylists = await mockDataSource.getAllPlaylists();
      final filtered = allPlaylists
          .where((p) => p.moodTags.contains(mood.toLowerCase()))
          .toList();
      return Right(filtered);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch playlists: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Playlist>>> getPlaylistsByGenre(
      String genre) async {
    try {
      final allPlaylists = await mockDataSource.getAllPlaylists();
      final filtered = allPlaylists
          .where((p) => p.genre.toLowerCase() == genre.toLowerCase())
          .toList();
      return Right(filtered);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch playlists: ${e.toString()}'));
    }
  }
}
