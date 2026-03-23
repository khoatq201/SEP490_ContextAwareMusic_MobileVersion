import '../models/space_playback_state_model.dart';
import '../models/space_queue_state_item_model.dart';
import '../models/override_response_model.dart';
import '../models/pair_code_snapshot_model.dart';
import '../models/pair_device_info_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/enums/playback_command_enum.dart';
import '../../../../core/enums/queue_insert_mode_enum.dart';
import 'package:dio/dio.dart';

abstract class CamsRemoteDataSource {
  /// Override Space music — DirectPlaylist or MoodOverride.
  /// Exactly one of [playlistId] or [moodId] must be provided.
  Future<OverrideResponseModel> overrideSpace({
    required String spaceId,
    List<String>? trackIds,
    String? playlistId,
    String? moodId,
    bool? isClearManagerSelectedQueues,
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

  /// Patch audio mixer fields (volume/mute/queue-end behavior).
  Future<void> updateAudioState({
    required String spaceId,
    int? volumePercent,
    bool? isMuted,
    int? queueEndBehavior,
    bool usePlaybackDeviceScope = false,
  });

  /// Queue native: add tracks with insert mode.
  Future<void> queueTracks({
    required String spaceId,
    required List<String> trackIds,
    required QueueInsertModeEnum mode,
    bool isClearExistingQueue = false,
    String? reason,
    bool usePlaybackDeviceScope = false,
  });

  /// Queue native: add playlist with insert mode.
  Future<void> queuePlaylist({
    required String spaceId,
    required String playlistId,
    required QueueInsertModeEnum mode,
    bool isClearExistingQueue = false,
    String? reason,
    bool usePlaybackDeviceScope = false,
  });

  /// Reorder pending queue items.
  Future<void> reorderQueue({
    required String spaceId,
    required List<String> queueItemIds,
    bool usePlaybackDeviceScope = false,
  });

  /// Remove selected queue items.
  Future<void> removeQueueItems({
    required String spaceId,
    required List<String> queueItemIds,
    bool usePlaybackDeviceScope = false,
  });

  /// Clear all queue items and stop playback.
  Future<void> clearQueue({
    required String spaceId,
    bool usePlaybackDeviceScope = false,
  });

  /// Read queue snapshot.
  Future<List<SpaceQueueStateItemModel>> getQueue(
    String spaceId, {
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
    List<String>? trackIds,
    String? playlistId,
    String? moodId,
    bool? isClearManagerSelectedQueues,
    String? reason,
    bool usePlaybackDeviceScope = false,
  }) async {
    try {
      final response = await dioClient.post(
        usePlaybackDeviceScope
            ? '/api/cams/spaces/override'
            : ApiConstants.camsOverride(spaceId),
        data: {
          if (trackIds != null) 'trackIds': trackIds,
          if (playlistId != null) 'playlistId': playlistId,
          if (moodId != null) 'moodId': moodId,
          if (isClearManagerSelectedQueues != null)
            'isClearManagerSelectedQueues': isClearManagerSelectedQueues,
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
      if (seekPositionSeconds != null)
        'seekPositionSeconds': seekPositionSeconds,
      if (targetTrackId != null) 'targetTrackId': targetTrackId,
    };

    final managerScopedPath =
        spaceId.isEmpty ? null : ApiConstants.camsPlayback(spaceId);
    const playbackScopedPath = '/api/cams/spaces/playback';
    final primaryPath = usePlaybackDeviceScope
        ? playbackScopedPath
        : (managerScopedPath ?? playbackScopedPath);
    final fallbackPath =
        usePlaybackDeviceScope ? managerScopedPath : playbackScopedPath;

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
  Future<void> updateAudioState({
    required String spaceId,
    int? volumePercent,
    bool? isMuted,
    int? queueEndBehavior,
    bool usePlaybackDeviceScope = false,
  }) async {
    final payload = {
      if (volumePercent != null) 'volumePercent': volumePercent,
      if (isMuted != null) 'isMuted': isMuted,
      if (queueEndBehavior != null) 'queueEndBehavior': queueEndBehavior,
    };

    if (payload.isEmpty) return;

    try {
      await _patchWithScope(
        spaceId: spaceId,
        managerScopedPathBuilder: ApiConstants.camsAudioState,
        playbackScopedPath: ApiConstants.camsCurrentDeviceAudioState,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
        payload: payload,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to update audio state: $e');
    }
  }

  @override
  Future<void> queueTracks({
    required String spaceId,
    required List<String> trackIds,
    required QueueInsertModeEnum mode,
    bool isClearExistingQueue = false,
    String? reason,
    bool usePlaybackDeviceScope = false,
  }) async {
    final payload = {
      'trackIds': trackIds,
      'mode': mode.value,
      'isClearExistingQueue': isClearExistingQueue,
      if (reason != null) 'reason': reason,
    };

    try {
      await _postWithScope(
        spaceId: spaceId,
        managerScopedPathBuilder: ApiConstants.camsQueueTracks,
        playbackScopedPath: ApiConstants.camsCurrentDeviceQueueTracks,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
        payload: payload,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to queue tracks: $e');
    }
  }

  @override
  Future<void> queuePlaylist({
    required String spaceId,
    required String playlistId,
    required QueueInsertModeEnum mode,
    bool isClearExistingQueue = false,
    String? reason,
    bool usePlaybackDeviceScope = false,
  }) async {
    final payload = {
      'playlistId': playlistId,
      'mode': mode.value,
      'isClearExistingQueue': isClearExistingQueue,
      if (reason != null) 'reason': reason,
    };

    try {
      await _postWithScope(
        spaceId: spaceId,
        managerScopedPathBuilder: ApiConstants.camsQueuePlaylist,
        playbackScopedPath: ApiConstants.camsCurrentDeviceQueuePlaylist,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
        payload: payload,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to queue playlist: $e');
    }
  }

  @override
  Future<void> reorderQueue({
    required String spaceId,
    required List<String> queueItemIds,
    bool usePlaybackDeviceScope = false,
  }) async {
    final payload = {
      'queueItemIds': queueItemIds,
    };

    try {
      await _patchWithScope(
        spaceId: spaceId,
        managerScopedPathBuilder: ApiConstants.camsQueueReorder,
        playbackScopedPath: ApiConstants.camsCurrentDeviceQueueReorder,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
        payload: payload,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to reorder queue: $e');
    }
  }

  @override
  Future<void> removeQueueItems({
    required String spaceId,
    required List<String> queueItemIds,
    bool usePlaybackDeviceScope = false,
  }) async {
    final payload = {
      'queueItemIds': queueItemIds,
    };

    try {
      await _deleteWithScope(
        spaceId: spaceId,
        managerScopedPathBuilder: ApiConstants.camsQueue,
        playbackScopedPath: ApiConstants.camsCurrentDeviceQueue,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
        payload: payload,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to remove queue items: $e');
    }
  }

  @override
  Future<void> clearQueue({
    required String spaceId,
    bool usePlaybackDeviceScope = false,
  }) async {
    try {
      await _deleteWithScope(
        spaceId: spaceId,
        managerScopedPathBuilder: ApiConstants.camsQueueAll,
        playbackScopedPath: ApiConstants.camsCurrentDeviceQueueAll,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to clear queue: $e');
    }
  }

  @override
  Future<List<SpaceQueueStateItemModel>> getQueue(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  }) async {
    final managerScopedPath =
        spaceId.isEmpty ? null : ApiConstants.camsQueue(spaceId);
    const playbackScopedPath = ApiConstants.camsCurrentDeviceQueue;
    final primaryPath = usePlaybackDeviceScope
        ? playbackScopedPath
        : (managerScopedPath ?? playbackScopedPath);
    final fallbackPath =
        usePlaybackDeviceScope ? managerScopedPath : playbackScopedPath;

    try {
      return await _fetchQueueByPath(primaryPath);
    } on DioException catch (e) {
      final canFallback = fallbackPath != null &&
          fallbackPath != primaryPath &&
          _isScopeFallbackStatusCode(e.response?.statusCode);
      if (canFallback) {
        try {
          return await _fetchQueueByPath(fallbackPath);
        } catch (_) {
          // Fall through to common error.
        }
      }
      throw ServerException('Failed to get queue: $e');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to get queue: $e');
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
    final fallbackPath =
        usePlaybackDeviceScope ? managerScopedPath : playbackScopedPath;

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

  Future<void> _postWithScope({
    required String spaceId,
    required String Function(String spaceId) managerScopedPathBuilder,
    required String playbackScopedPath,
    required bool usePlaybackDeviceScope,
    required Map<String, dynamic> payload,
  }) async {
    final managerScopedPath =
        spaceId.isEmpty ? null : managerScopedPathBuilder(spaceId);
    final primaryPath = usePlaybackDeviceScope
        ? playbackScopedPath
        : (managerScopedPath ?? playbackScopedPath);
    final fallbackPath =
        usePlaybackDeviceScope ? managerScopedPath : playbackScopedPath;

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
          // Fall through to common error.
        }
      }
      rethrow;
    }
  }

  Future<void> _patchWithScope({
    required String spaceId,
    required String Function(String spaceId) managerScopedPathBuilder,
    required String playbackScopedPath,
    required bool usePlaybackDeviceScope,
    required Map<String, dynamic> payload,
  }) async {
    final managerScopedPath =
        spaceId.isEmpty ? null : managerScopedPathBuilder(spaceId);
    final primaryPath = usePlaybackDeviceScope
        ? playbackScopedPath
        : (managerScopedPath ?? playbackScopedPath);
    final fallbackPath =
        usePlaybackDeviceScope ? managerScopedPath : playbackScopedPath;

    try {
      await dioClient.dio.patch(primaryPath, data: payload);
      return;
    } on DioException catch (e) {
      final canFallback = fallbackPath != null &&
          fallbackPath != primaryPath &&
          _isScopeFallbackStatusCode(e.response?.statusCode);
      if (canFallback) {
        try {
          await dioClient.dio.patch(fallbackPath, data: payload);
          return;
        } catch (_) {
          // Fall through to common error.
        }
      }
      rethrow;
    }
  }

  Future<void> _deleteWithScope({
    required String spaceId,
    required String Function(String spaceId) managerScopedPathBuilder,
    required String playbackScopedPath,
    required bool usePlaybackDeviceScope,
    Map<String, dynamic>? payload,
  }) async {
    final managerScopedPath =
        spaceId.isEmpty ? null : managerScopedPathBuilder(spaceId);
    final primaryPath = usePlaybackDeviceScope
        ? playbackScopedPath
        : (managerScopedPath ?? playbackScopedPath);
    final fallbackPath =
        usePlaybackDeviceScope ? managerScopedPath : playbackScopedPath;

    try {
      await dioClient.delete(primaryPath, data: payload);
      return;
    } on DioException catch (e) {
      final canFallback = fallbackPath != null &&
          fallbackPath != primaryPath &&
          _isScopeFallbackStatusCode(e.response?.statusCode);
      if (canFallback) {
        try {
          await dioClient.delete(fallbackPath, data: payload);
          return;
        } catch (_) {
          // Fall through to common error.
        }
      }
      rethrow;
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

  Future<List<SpaceQueueStateItemModel>> _fetchQueueByPath(String path) async {
    final response = await dioClient.get(path);
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      return SpaceQueueStateItemModel.listFromDynamic(data);
    }
    if (body is List) {
      return SpaceQueueStateItemModel.listFromDynamic(body);
    }
    throw ServerException('Invalid queue response');
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
