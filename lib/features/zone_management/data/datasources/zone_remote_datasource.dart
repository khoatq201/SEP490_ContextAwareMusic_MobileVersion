import '../models/zone_model.dart';
import '../models/music_profile_model.dart';
import '../models/playlist_model.dart';
import '../models/speaker_model.dart';

/// Abstract interface for zone management data source.
/// Both [ZoneMockDataSource] and [ZoneRemoteDataSourceImpl] implement this.
abstract class ZoneRemoteDataSource {
  /// Get all zones for a specific space
  Future<List<ZoneModel>> getZonesBySpace(String spaceId);

  /// Get music profile for a specific zone
  Future<MusicProfileModel> getMusicProfileByZone(String zoneId);

  /// Get all available playlists
  Future<List<PlaylistModel>> getAllPlaylists();

  /// Get a specific playlist by ID
  Future<PlaylistModel> getPlaylistById(String playlistId);

  /// Get all speakers for a zone
  Future<List<SpeakerModel>> getSpeakersByZone(String zoneId);

  /// Create a new zone
  Future<ZoneModel> createZone(ZoneModel zone);

  /// Update an existing zone
  Future<ZoneModel> updateZone(ZoneModel zone);

  /// Delete a zone
  Future<void> deleteZone(String zoneId);

  /// Update speaker volume via API/MQTT
  Future<void> updateSpeakerVolume({
    required String speakerId,
    required int volume,
  });

  /// Sync music playback across multiple zones
  Future<void> syncZonesMusic(List<String> zoneIds);

  /// Unsync zones
  Future<void> unsyncZones(List<String> zoneIds);

  /// Update music profile configuration
  Future<void> updateMusicProfile(MusicProfileModel profile);

  /// Assign a playlist to a zone
  Future<void> assignPlaylistToZone({
    required String zoneId,
    required String playlistId,
  });

  /// Remove a playlist from a zone
  Future<void> removePlaylistFromZone({
    required String zoneId,
    required String playlistId,
  });

  /// Update mood to playlist mapping
  Future<void> updateMoodMapping({
    required String zoneId,
    required Map<String, String> moodToPlaylistMap,
  });

  /// Update volume settings for a zone
  Future<void> updateVolumeSettings({
    required String zoneId,
    required Map<String, dynamic> volumeSettingsJson,
  });

  /// Update schedule config for a zone
  Future<void> updateScheduleConfig({
    required String zoneId,
    required Map<String, dynamic>? scheduleConfigJson,
  });

  /// Toggle auto mood detection for a zone
  Future<void> toggleAutoMoodDetection({
    required String zoneId,
    required bool enabled,
  });
}
