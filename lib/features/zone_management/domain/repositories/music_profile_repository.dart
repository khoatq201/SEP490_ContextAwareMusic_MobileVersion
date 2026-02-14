import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/music_profile.dart';
import '../entities/playlist.dart';

/// Repository interface for music profile management
abstract class MusicProfileRepository {
  /// Get music profile for a specific zone
  Future<Either<Failure, MusicProfile>> getProfileByZone(String zoneId);

  /// Get a music profile by its ID
  Future<Either<Failure, MusicProfile>> getProfileById(String profileId);

  /// Update music profile configuration
  Future<Either<Failure, MusicProfile>> updateProfile(MusicProfile profile);

  /// Assign a playlist to a zone's music profile
  Future<Either<Failure, void>> assignPlaylistToZone({
    required String zoneId,
    required String playlistId,
  });

  /// Remove a playlist from a zone's music profile
  Future<Either<Failure, void>> removePlaylistFromZone({
    required String zoneId,
    required String playlistId,
  });

  /// Update mood to playlist mapping for a zone
  Future<Either<Failure, void>> updateMoodMapping({
    required String zoneId,
    required Map<String, String> moodToPlaylistMap,
  });

  /// Update volume settings for a zone
  Future<Either<Failure, void>> updateVolumeSettings({
    required String zoneId,
    required VolumeSettings volumeSettings,
  });

  /// Update schedule configuration for a zone
  Future<Either<Failure, void>> updateScheduleConfig({
    required String zoneId,
    required ScheduleConfig? scheduleConfig,
  });

  /// Enable or disable auto mood detection for a zone
  Future<Either<Failure, void>> toggleAutoMoodDetection({
    required String zoneId,
    required bool enabled,
  });

  /// Get all available playlists
  Future<Either<Failure, List<Playlist>>> getAllPlaylists();

  /// Get a specific playlist by ID
  Future<Either<Failure, Playlist>> getPlaylistById(String playlistId);

  /// Get playlists filtered by mood tags
  Future<Either<Failure, List<Playlist>>> getPlaylistsByMood(String mood);

  /// Get playlists filtered by genre
  Future<Either<Failure, List<Playlist>>> getPlaylistsByGenre(String genre);
}
