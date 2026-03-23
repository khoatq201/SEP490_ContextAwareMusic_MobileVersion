import '../models/space_playback_state_model.dart';
import '../models/override_response_model.dart';
import '../models/pair_code_snapshot_model.dart';
import '../models/pair_device_info_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/enums/playback_command_enum.dart';
import 'package:dio/dio.dart';

abstract class CamsRemoteDataSource {
  /// Override Space music — DirectPlaylist or MoodOverride.
  /// Exactly one of [playlistId] or [moodId] must be provided.
  Future<OverrideResponseModel> overrideSpace({
    required String spaceId,
    String? playlistId,
    String? moodId,
    String? reason,
    bool usePlaybackDeviceScope = false,
  });

  /// Cancel active override — AI scheduling resumes.
  Future<void> cancelOverride(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  });

  /// Send playback command (Pause/Resume/Seek/Skip).
  Future<void> sendPlaybackCommand({
    required String spaceId,
    required PlaybackCommandEnum command,
    double? seekPositionSeconds,
    String? targetTrackId,
    bool usePlaybackDeviceScope = false,
  });

  /// Get current playback state of a Space.
  Future<SpacePlaybackStateModel> getSpaceState(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  });

  Future<SpacePlaybackStateModel> getSpaceStateForPlaybackDevice();

  Future<PairDeviceInfoModel> getPairDeviceInfoForManager(String spaceId);

  Future<PairDeviceInfoModel> getPairDeviceInfoForPlaybackDevice();

  Future<PairCodeSnapshotModel> generatePairCode(String spaceId);

  Future<void> revokePairCode(String spaceId);

  Future<void> unpairDevice(String spaceId);
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
    bool usePlaybackDeviceScope = false,
  }) async {
    try {
      final response = await dioClient.post(
        usePlaybackDeviceScope
            ? '/api/cams/spaces/override'
            : ApiConstants.camsOverride(spaceId),
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
  Future<void> cancelOverride(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  }) async {
    try {
      await dioClient.delete(
        usePlaybackDeviceScope
            ? '/api/cams/spaces/override'
            : ApiConstants.camsCancelOverride(spaceId),
      );
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
    bool usePlaybackDeviceScope = false,
  }) async {
    final payload = {
      'command': command.value,
      if (seekPositionSeconds != null) 'seekPositionSeconds': seekPositionSeconds,
      if (targetTrackId != null) 'targetTrackId': targetTrackId,
    };

    final managerScopedPath =
        spaceId.isEmpty ? null : ApiConstants.camsPlayback(spaceId);
    const playbackScopedPath = '/api/cams/spaces/playback';
    final primaryPath = usePlaybackDeviceScope
        ? playbackScopedPath
        : (managerScopedPath ?? playbackScopedPath);
    final fallbackPath = usePlaybackDeviceScope
        ? managerScopedPath
        : playbackScopedPath;

    try {
      await dioClient.post(primaryPath, data: payload);
      return;
    } on DioException catch (e) {
      final canFallback = fallbackPath != null &&
          fallbackPath != primaryPath &&
          _isScopeFallbackStatusCode(e.response?.statusCode);
      if (canFallback) {
        try {
          await dioClient.post(fallbackPath, data: payload);
          return;
        } catch (_) {
          // Fall through to the common error below with primary exception.
        }
      }
      throw ServerException('Failed to send playback command: $e');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to send playback command: $e');
    }
  }

  @override
  Future<SpacePlaybackStateModel> getSpaceState(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  }) async {
    final managerScopedPath =
        spaceId.isEmpty ? null : ApiConstants.camsState(spaceId);
    const playbackScopedPath = ApiConstants.camsCurrentDeviceState;
    final primaryPath = usePlaybackDeviceScope
        ? playbackScopedPath
        : (managerScopedPath ?? playbackScopedPath);
    final fallbackPath = usePlaybackDeviceScope
        ? managerScopedPath
        : playbackScopedPath;

    try {
      return await _fetchSpaceStateByPath(primaryPath);
    } on DioException catch (e) {
      final canFallback = fallbackPath != null &&
          fallbackPath != primaryPath &&
          _isScopeFallbackStatusCode(e.response?.statusCode);
      if (canFallback) {
        try {
          return await _fetchSpaceStateByPath(fallbackPath);
        } catch (_) {
          // Fall through to the common error message below.
        }
      }
      throw ServerException('Failed to get space state: $e');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to get space state: $e');
    }
  }

  bool _isScopeFallbackStatusCode(int? statusCode) {
    return statusCode == 401 || statusCode == 403 || statusCode == 404;
  }

  Future<SpacePlaybackStateModel> _fetchSpaceStateByPath(String path) async {
    final response = await dioClient.get(path);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final model = SpacePlaybackStateModel.fromApiResponse(data);
      if (model != null) return model;
    }
    throw ServerException('Invalid space state response');
  }

  @override
  Future<SpacePlaybackStateModel> getSpaceStateForPlaybackDevice() {
    return getSpaceState('', usePlaybackDeviceScope: true);
  }

  @override
  Future<PairDeviceInfoModel> getPairDeviceInfoForManager(
      String spaceId) async {
    try {
      final response =
          await dioClient.get(ApiConstants.camsPairDevice(spaceId));
      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['isSuccess'] == true &&
          data['data'] is Map<String, dynamic>) {
        return PairDeviceInfoModel.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }
      throw ServerException('Invalid pair-device response');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to get pair device info: $e');
    }
  }

  @override
  Future<PairDeviceInfoModel> getPairDeviceInfoForPlaybackDevice() async {
    try {
      final response = await dioClient.get(ApiConstants.camsCurrentPairDevice);
      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['isSuccess'] == true &&
          data['data'] is Map<String, dynamic>) {
        return PairDeviceInfoModel.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }
      throw ServerException('Invalid pair-device response');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to get pair device info: $e');
    }
  }

  @override
  Future<PairCodeSnapshotModel> generatePairCode(String spaceId) async {
    try {
      final response = await dioClient.post(ApiConstants.camsPairCode(spaceId));
      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['isSuccess'] == true &&
          data['data'] is Map<String, dynamic>) {
        return PairCodeSnapshotModel.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }
      throw ServerException('Invalid pair-code response');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to generate pair code: $e');
    }
  }

  @override
  Future<void> revokePairCode(String spaceId) async {
    try {
      await dioClient.delete(ApiConstants.camsPairCode(spaceId));
    } catch (e) {
      throw ServerException('Failed to revoke pair code: $e');
    }
  }

  @override
  Future<void> unpairDevice(String spaceId) async {
    try {
      await dioClient.delete(ApiConstants.camsUnpair(spaceId));
    } catch (e) {
      throw ServerException('Failed to unpair device: $e');
    }
  }
}
