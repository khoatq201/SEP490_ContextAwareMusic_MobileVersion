import '../models/space_playback_state_model.dart';
import '../models/override_response_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/enums/playback_command_enum.dart';

abstract class CamsRemoteDataSource {
  /// Override Space music — DirectPlaylist or MoodOverride.
  /// Exactly one of [playlistId] or [moodId] must be provided.
  Future<OverrideResponseModel> overrideSpace({
    required String spaceId,
    String? playlistId,
    String? moodId,
    String? reason,
  });

  /// Cancel active override — AI scheduling resumes.
  Future<void> cancelOverride(String spaceId);

  /// Send playback command (Pause/Resume/Seek/Skip).
  Future<void> sendPlaybackCommand({
    required String spaceId,
    required PlaybackCommandEnum command,
    double? seekPositionSeconds,
    String? targetTrackId,
  });

  /// Get current playback state of a Space.
  Future<SpacePlaybackStateModel> getSpaceState(String spaceId);
}

class CamsRemoteDataSourceImpl implements CamsRemoteDataSource {
  final DioClient dioClient;

  CamsRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<OverrideResponseModel> overrideSpace({
    required String spaceId,
    String? playlistId,
    String? moodId,
    String? reason,
  }) async {
    try {
      final response = await dioClient.post(
        ApiConstants.camsOverride(spaceId),
        data: {
          if (playlistId != null) 'playlistId': playlistId,
          if (moodId != null) 'moodId': moodId,
          if (reason != null) 'reason': reason,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final model = OverrideResponseModel.fromApiResponse(data);
        if (model != null) return model;
      }
      throw ServerException('Invalid override response');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to override space: $e');
    }
  }

  @override
  Future<void> cancelOverride(String spaceId) async {
    try {
      await dioClient.delete(ApiConstants.camsCancelOverride(spaceId));
    } catch (e) {
      throw ServerException('Failed to cancel override: $e');
    }
  }

  @override
  Future<void> sendPlaybackCommand({
    required String spaceId,
    required PlaybackCommandEnum command,
    double? seekPositionSeconds,
    String? targetTrackId,
  }) async {
    try {
      await dioClient.post(
        ApiConstants.camsPlayback(spaceId),
        data: {
          'command': command.value,
          if (seekPositionSeconds != null)
            'seekPositionSeconds': seekPositionSeconds,
          if (targetTrackId != null) 'targetTrackId': targetTrackId,
        },
      );
    } catch (e) {
      throw ServerException('Failed to send playback command: $e');
    }
  }

  @override
  Future<SpacePlaybackStateModel> getSpaceState(String spaceId) async {
    try {
      final response = await dioClient.get(
        ApiConstants.camsState(spaceId),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final model = SpacePlaybackStateModel.fromApiResponse(data);
        if (model != null) return model;
      }
      throw ServerException('Invalid space state response');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to get space state: $e');
    }
  }
}
