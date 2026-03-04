import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/zone_model.dart';
import '../models/music_profile_model.dart';
import '../models/playlist_model.dart';
import '../models/speaker_model.dart';
import 'zone_remote_datasource.dart';

/// Real API implementation of [ZoneRemoteDataSource].
/// Calls actual backend endpoints.
class ZoneRemoteDataSourceImpl implements ZoneRemoteDataSource {
  final DioClient dioClient;

  ZoneRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<ZoneModel>> getZonesBySpace(String spaceId) async {
    try {
      final response = await dioClient.get(
        '${ApiConstants.getSpaceDetailEndpoint.replaceFirst('{spaceId}', spaceId)}/zones',
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return (data['data'] as List)
            .map((json) => ZoneModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return (data as List)
          .map((json) => ZoneModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch zones: $e');
    }
  }

  @override
  Future<MusicProfileModel> getMusicProfileByZone(String zoneId) async {
    try {
      final response = await dioClient.get('/api/zones/$zoneId/music-profile');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return MusicProfileModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return MusicProfileModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException('Failed to fetch music profile: $e');
    }
  }

  @override
  Future<List<PlaylistModel>> getAllPlaylists() async {
    try {
      final response = await dioClient.get('/api/playlists');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return (data['data'] as List)
            .map((json) => PlaylistModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return (data as List)
          .map((json) => PlaylistModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch playlists: $e');
    }
  }

  @override
  Future<PlaylistModel> getPlaylistById(String playlistId) async {
    try {
      final endpoint = ApiConstants.getPlaylistEndpoint
          .replaceFirst('{playlistId}', playlistId);
      final response = await dioClient.get(endpoint);
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return PlaylistModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return PlaylistModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException('Failed to fetch playlist: $e');
    }
  }

  @override
  Future<List<SpeakerModel>> getSpeakersByZone(String zoneId) async {
    try {
      final response = await dioClient.get('/api/zones/$zoneId/speakers');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return (data['data'] as List)
            .map((json) => SpeakerModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return (data as List)
          .map((json) => SpeakerModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch speakers: $e');
    }
  }

  @override
  Future<ZoneModel> createZone(ZoneModel zone) async {
    try {
      final response = await dioClient.post(
        '/api/spaces/${zone.spaceId}/zones',
        data: zone.toJson(),
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return ZoneModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return ZoneModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException('Failed to create zone: $e');
    }
  }

  @override
  Future<ZoneModel> updateZone(ZoneModel zone) async {
    try {
      final response = await dioClient.put(
        '/api/zones/${zone.id}',
        data: zone.toJson(),
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return ZoneModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return ZoneModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException('Failed to update zone: $e');
    }
  }

  @override
  Future<void> deleteZone(String zoneId) async {
    try {
      await dioClient.delete('/api/zones/$zoneId');
    } catch (e) {
      throw ServerException('Failed to delete zone: $e');
    }
  }

  @override
  Future<void> updateSpeakerVolume({
    required String speakerId,
    required int volume,
  }) async {
    try {
      await dioClient.put(
        '/api/speakers/$speakerId/volume',
        data: {'volume': volume},
      );
    } catch (e) {
      throw ServerException('Failed to update speaker volume: $e');
    }
  }

  @override
  Future<void> syncZonesMusic(List<String> zoneIds) async {
    try {
      await dioClient.post(
        '/api/zones/sync',
        data: {'zoneIds': zoneIds},
      );
    } catch (e) {
      throw ServerException('Failed to sync zones music: $e');
    }
  }

  @override
  Future<void> unsyncZones(List<String> zoneIds) async {
    try {
      await dioClient.post(
        '/api/zones/unsync',
        data: {'zoneIds': zoneIds},
      );
    } catch (e) {
      throw ServerException('Failed to unsync zones: $e');
    }
  }

  @override
  Future<void> updateMusicProfile(MusicProfileModel profile) async {
    try {
      await dioClient.put(
        '/api/music-profiles/${profile.id}',
        data: profile.toJson(),
      );
    } catch (e) {
      throw ServerException('Failed to update music profile: $e');
    }
  }

  @override
  Future<void> assignPlaylistToZone({
    required String zoneId,
    required String playlistId,
  }) async {
    try {
      await dioClient.post(
        '/api/zones/$zoneId/playlists',
        data: {'playlistId': playlistId},
      );
    } catch (e) {
      throw ServerException('Failed to assign playlist to zone: $e');
    }
  }

  @override
  Future<void> removePlaylistFromZone({
    required String zoneId,
    required String playlistId,
  }) async {
    try {
      await dioClient.delete('/api/zones/$zoneId/playlists/$playlistId');
    } catch (e) {
      throw ServerException('Failed to remove playlist from zone: $e');
    }
  }

  @override
  Future<void> updateMoodMapping({
    required String zoneId,
    required Map<String, String> moodToPlaylistMap,
  }) async {
    try {
      await dioClient.put(
        '/api/zones/$zoneId/mood-mapping',
        data: {'moodToPlaylistMap': moodToPlaylistMap},
      );
    } catch (e) {
      throw ServerException('Failed to update mood mapping: $e');
    }
  }

  @override
  Future<void> updateVolumeSettings({
    required String zoneId,
    required Map<String, dynamic> volumeSettingsJson,
  }) async {
    try {
      await dioClient.put(
        '/api/zones/$zoneId/volume-settings',
        data: volumeSettingsJson,
      );
    } catch (e) {
      throw ServerException('Failed to update volume settings: $e');
    }
  }

  @override
  Future<void> updateScheduleConfig({
    required String zoneId,
    required Map<String, dynamic>? scheduleConfigJson,
  }) async {
    try {
      await dioClient.put(
        '/api/zones/$zoneId/schedule-config',
        data: scheduleConfigJson ?? {},
      );
    } catch (e) {
      throw ServerException('Failed to update schedule config: $e');
    }
  }

  @override
  Future<void> toggleAutoMoodDetection({
    required String zoneId,
    required bool enabled,
  }) async {
    try {
      await dioClient.put(
        '/api/zones/$zoneId/auto-mood-detection',
        data: {'enabled': enabled},
      );
    } catch (e) {
      throw ServerException('Failed to toggle auto mood detection: $e');
    }
  }
}
