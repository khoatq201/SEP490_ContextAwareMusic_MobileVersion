import '../models/space_playback_state_model.dart';
import '../models/space_queue_state_item_model.dart';
import '../models/override_response_model.dart';
import '../models/pair_code_snapshot_model.dart';
import '../models/pair_device_info_model.dart';
import '../../domain/entities/space_playback_state.dart';
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
    bool? isCutOver,
    int? manualOverrideTtlSeconds,
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
    String? targetQueueItemId,
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

  Future<void> updateSchedulingState({
    required String spaceId,
    required bool isScheduling,
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

  Future<SpacePlaybackExplainability?> getFuzzyProfileBpmGuidance({
    required String spaceId,
    required String? storeId,
    required String? moodName,
  });

  Future<PairDeviceInfoModel> getPairDeviceInfoForManager(String spaceId);

  Future<PairDeviceInfoModel> getPairDeviceInfoForPlaybackDevice();

  Future<PairCodeSnapshotModel> generatePairCode(String spaceId);

  Future<void> revokePairCode(String spaceId);

  Future<void> unpairDevice(String spaceId);
}

class CamsRemoteDataSourceImpl implements CamsRemoteDataSource {
  static const int _minimumAcceptedVolumePercent = 30;

  final DioClient dioClient;

  CamsRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<OverrideResponseModel> overrideSpace({
    required String spaceId,
    List<String>? trackIds,
    String? playlistId,
    String? moodId,
    bool? isClearManagerSelectedQueues,
    bool? isCutOver,
    int? manualOverrideTtlSeconds,
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
          if (isCutOver != null) 'isCutOver': isCutOver,
          if (manualOverrideTtlSeconds != null)
            'manualOverrideTtlSeconds': manualOverrideTtlSeconds,
          if (reason != null) 'reason': reason,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final model = OverrideResponseModel.fromApiResponse(data);
        if (model != null) return model;
      }
      throw const ServerException('Invalid override response');
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
    String? targetQueueItemId,
    String? targetTrackId,
    bool usePlaybackDeviceScope = false,
  }) async {
    final payload = {
      'command': command.value,
      if (seekPositionSeconds != null)
        'seekPositionSeconds': seekPositionSeconds,
      if (targetQueueItemId != null) 'targetQueueItemId': targetQueueItemId,
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
    final normalizedVolumePercent =
        _normalizeVolumePercentForAudioPatch(volumePercent, isMuted);
    final payload = {
      if (normalizedVolumePercent != null)
        'volumePercent': normalizedVolumePercent,
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
  Future<void> updateSchedulingState({
    required String spaceId,
    required bool isScheduling,
    bool usePlaybackDeviceScope = false,
  }) async {
    try {
      await _patchWithScope(
        spaceId: spaceId,
        managerScopedPathBuilder: ApiConstants.camsSchedulingState,
        playbackScopedPath: ApiConstants.camsCurrentDeviceSchedulingState,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
        payload: {'isScheduling': isScheduling},
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to update scheduling state: $e');
    }
  }

  int? _normalizeVolumePercentForAudioPatch(int? volumePercent, bool? isMuted) {
    if (volumePercent == null) return null;

    final boundedVolume = volumePercent.clamp(0, 100).toInt();
    if (boundedVolume == 0) {
      return isMuted == true ? null : _minimumAcceptedVolumePercent;
    }

    if (boundedVolume < _minimumAcceptedVolumePercent) {
      return _minimumAcceptedVolumePercent;
    }

    return boundedVolume;
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

  @override
  Future<SpacePlaybackExplainability?> getFuzzyProfileBpmGuidance({
    required String spaceId,
    required String? storeId,
    required String? moodName,
  }) async {
    final bandKey = _resolveBpmBandKey(moodName);
    if (bandKey == null) return null;

    final paths = <String>[
      if (spaceId.trim().isNotEmpty)
        ApiConstants.fuzzyMusicProfileForSpace(spaceId.trim()),
      if (storeId?.trim().isNotEmpty ?? false)
        ApiConstants.fuzzyMusicProfileForStore(storeId!.trim()),
      ApiConstants.fuzzyMusicProfileForCurrentStore,
    ];

    for (final path in paths) {
      try {
        final response = await dioClient.get(path);
        final profile = _extractFuzzyProfilePayload(response.data);
        if (profile == null) continue;
        final guidance = _buildBpmGuidanceFromProfile(
          profile: profile,
          bandKey: bandKey,
          moodName: moodName,
        );
        if (guidance != null) return guidance;
      } on DioException catch (e) {
        if (_isScopeFallbackStatusCode(e.response?.statusCode)) {
          continue;
        }
        continue;
      } catch (_) {
        continue;
      }
    }

    return null;
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
    throw const ServerException('Invalid space state response');
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
    throw const ServerException('Invalid queue response');
  }

  Map<String, dynamic>? _extractFuzzyProfilePayload(dynamic body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      if (data is List) return _firstMap(data);
      return body;
    }
    if (body is Map) {
      final normalized = Map<String, dynamic>.from(body);
      final data = normalized['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      if (data is List) return _firstMap(data);
      return normalized;
    }
    if (body is List) return _firstMap(body);
    return null;
  }

  Map<String, dynamic>? _firstMap(List<dynamic> entries) {
    for (final entry in entries) {
      if (entry is Map<String, dynamic>) return entry;
      if (entry is Map) return Map<String, dynamic>.from(entry);
    }
    return null;
  }

  SpacePlaybackExplainability? _buildBpmGuidanceFromProfile({
    required Map<String, dynamic> profile,
    required String bandKey,
    required String? moodName,
  }) {
    final min = _readInt(profile, '${bandKey}BpmMin');
    final max = _readInt(profile, '${bandKey}BpmMax');
    if (min == null || max == null) return null;

    final target =
        _readInt(profile, '${bandKey}BpmTarget') ?? ((min + max) / 2).round();
    return SpacePlaybackExplainability(
      moodName: moodName?.trim(),
      recommendedBpmMin: min,
      recommendedBpmMax: max,
      recommendedBpmTarget: target,
      fuzzyProfileName: _readString(profile, 'name') ??
          _readString(profile, 'profileName') ??
          _readString(profile, 'fuzzyProfileName'),
      fuzzyProfileTemplate: _readString(profile, 'templateKey') ??
          _readString(profile, 'templateName') ??
          _readString(profile, 'fuzzyProfileTemplate'),
    );
  }

  String? _resolveBpmBandKey(String? moodName) {
    final normalized = moodName?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    if (normalized.contains('focus')) return 'focus';
    if (normalized.contains('chill') || normalized.contains('calm')) {
      return 'chill';
    }
    if (normalized.contains('energetic') ||
        normalized.contains('energy') ||
        normalized.contains('active')) {
      return 'energetic';
    }
    return null;
  }

  dynamic _readValue(Map<String, dynamic> json, String key) {
    if (json.containsKey(key)) return json[key];
    if (key.isEmpty) return null;
    final pascalCaseKey = '${key[0].toUpperCase()}${key.substring(1)}';
    return json[pascalCaseKey];
  }

  int? _readInt(Map<String, dynamic> json, String key) {
    final value = _readValue(json, key);
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  String? _readString(Map<String, dynamic> json, String key) {
    final value = _readValue(json, key);
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
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
      throw const ServerException('Invalid pair-device response');
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
      throw const ServerException('Invalid pair-device response');
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
      throw const ServerException('Invalid pair-code response');
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
