import '../models/space_playback_state_model.dart';
import '../models/space_queue_state_item_model.dart';
import '../models/override_response_model.dart';
import '../models/pair_code_snapshot_model.dart';
import '../models/pair_device_info_model.dart';
import '../../domain/entities/space_playback_state.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure_kind.dart';
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

  Future<String?> getSpaceMoodName(String spaceId);

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
      _throwMappedDioException(
        e,
        fallbackMessage: 'Failed to send playback command.',
        primaryPath: primaryPath,
        fallbackPath: fallbackPath,
      );
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
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(
        error,
        fallbackMessage: 'Unable to update scheduling right now.',
      );
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      throw ErrorMapper.toException(
        error,
        fallbackMessage: 'Unable to update scheduling right now.',
        stackTrace: stackTrace,
      );
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
        fallbackMessage: 'Failed to queue tracks.',
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
        fallbackMessage: 'Failed to queue playlist.',
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
      _throwMappedDioException(
        e,
        fallbackMessage: 'Unable to load the CAMS queue right now.',
        primaryPath: primaryPath,
        fallbackPath: fallbackPath,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      if (e is AppException) rethrow;
      throw ErrorMapper.toException(
        e,
        fallbackMessage: 'Unable to load the CAMS queue right now.',
      );
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
      final state = await _fetchSpaceStateByPath(primaryPath);
      return await _withLiveSpaceMood(state);
    } on DioException catch (e) {
      final canFallback = fallbackPath != null &&
          fallbackPath != primaryPath &&
          _isScopeFallbackStatusCode(e.response?.statusCode);
      if (canFallback) {
        try {
          final state = await _fetchSpaceStateByPath(fallbackPath);
          return await _withLiveSpaceMood(state);
        } catch (_) {
          // Fall through to the common error message below.
        }
      }
      _throwMappedDioException(
        e,
        fallbackMessage: 'Unable to load CAMS playback state right now.',
        primaryPath: primaryPath,
        fallbackPath: fallbackPath,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      if (e is AppException) rethrow;
      throw ErrorMapper.toException(
        e,
        fallbackMessage: 'Unable to load CAMS playback state right now.',
      );
    }
  }

  @override
  Future<String?> getSpaceMoodName(String spaceId) async {
    final trimmedSpaceId = spaceId.trim();
    if (trimmedSpaceId.isEmpty) return null;

    for (final path in [
      ApiConstants.camsSpaceMood(trimmedSpaceId),
      ApiConstants.camsSpaceMoodPlural(trimmedSpaceId),
    ]) {
      try {
        final response = await dioClient.get(path);
        final moodName = _extractMoodName(response.data);
        if (moodName != null && moodName.trim().isNotEmpty) {
          return moodName.trim();
        }
      } on DioException catch (error) {
        if (_isScopeFallbackStatusCode(error.response?.statusCode)) {
          continue;
        }
        continue;
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  Future<SpacePlaybackStateModel> _withLiveSpaceMood(
    SpacePlaybackStateModel state,
  ) async {
    final moodName = await getSpaceMoodName(state.spaceId);
    if (moodName == null || moodName.trim().isEmpty) return state;
    if (moodName.trim() == state.moodName?.trim()) return state;
    return SpacePlaybackStateModel(
      spaceId: state.spaceId,
      storeId: state.storeId,
      brandId: state.brandId,
      currentQueueItemId: state.currentQueueItemId,
      currentTrackName: state.currentTrackName,
      currentPlaylistId: state.currentPlaylistId,
      currentPlaylistName: state.currentPlaylistName,
      hlsUrl: state.hlsUrl,
      moodName: moodName,
      isManualOverride: state.isManualOverride,
      overrideMode: state.overrideMode,
      overrideReason: state.overrideReason,
      manualOverrideActivatedAtUtc: state.manualOverrideActivatedAtUtc,
      manualOverrideExpiresAtUtc: state.manualOverrideExpiresAtUtc,
      manualOverrideTtlSeconds: state.manualOverrideTtlSeconds,
      manualOverrideRemainingSeconds: state.manualOverrideRemainingSeconds,
      isScheduling: state.isScheduling,
      schedulingSlotId: state.schedulingSlotId,
      schedulingSlotOrigin: state.schedulingSlotOrigin,
      schedulingEndsAtUtc: state.schedulingEndsAtUtc,
      schedulingRemainingSeconds: state.schedulingRemainingSeconds,
      startedAtUtc: state.startedAtUtc,
      expectedEndAtUtc: state.expectedEndAtUtc,
      isPaused: state.isPaused,
      pausePositionSeconds: state.pausePositionSeconds,
      seekOffsetSeconds: state.seekOffsetSeconds,
      pendingQueueItemId: state.pendingQueueItemId,
      pendingPlaylistId: state.pendingPlaylistId,
      pendingOverrideReason: state.pendingOverrideReason,
      volumePercent: state.volumePercent,
      isIotDeviceAssigned: state.isIotDeviceAssigned,
      isIotDeviceOffline: state.isIotDeviceOffline,
      isMuted: state.isMuted,
      queueEndBehavior: state.queueEndBehavior,
      spaceQueueItems: state.spaceQueueItems,
      explainability: state.explainability,
    );
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
    required String fallbackMessage,
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
      _throwMappedDioException(
        e,
        fallbackMessage: fallbackMessage,
        primaryPath: primaryPath,
        fallbackPath: fallbackPath,
      );
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
      if (data['isSuccess'] == false) {
        _throwApiResponseFailure(
          data,
          fallbackMessage: 'Unable to load CAMS playback state right now.',
          path: path,
          statusCode: response.statusCode,
        );
      }
      final model = SpacePlaybackStateModel.fromApiResponse(data);
      if (model != null) return model;
    }
    throw ServerException(
      'Invalid CAMS playback state response.',
      FailureKind.unexpected,
      null,
      response.statusCode,
      _requestDebugContext(path: path, payload: data),
    );
  }

  String? _extractMoodName(dynamic body) {
    final payload = _extractMoodPayload(body);
    if (payload == null) return null;

    final direct = _readFirstString(payload, const [
      'moodName',
      'currentMood',
      'spaceMood',
      'name',
      'selectedMoodName',
      'newMood',
      'targetMood',
    ]);
    if (direct != null) return direct;

    final mood = _readValue(payload, 'mood');
    if (mood is Map) {
      return _readFirstString(Map<String, dynamic>.from(mood), const [
        'moodName',
        'name',
        'currentMood',
      ]);
    }
    if (mood is String && mood.trim().isNotEmpty) {
      return mood.trim();
    }

    return null;
  }

  Map<String, dynamic>? _extractMoodPayload(dynamic body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return body;
    }
    if (body is Map) {
      final normalized = Map<String, dynamic>.from(body);
      final data = normalized['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return normalized;
    }
    return null;
  }

  String? _readFirstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = _readValue(json, key);
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  Future<List<SpaceQueueStateItemModel>> _fetchQueueByPath(String path) async {
    final response = await dioClient.get(path);
    final body = response.data;
    if (body is Map<String, dynamic>) {
      if (body['isSuccess'] == false) {
        _throwApiResponseFailure(
          body,
          fallbackMessage: 'Unable to load the CAMS queue right now.',
          path: path,
          statusCode: response.statusCode,
        );
      }
      final data = body['data'];
      return SpaceQueueStateItemModel.listFromDynamic(data);
    }
    if (body is List) {
      return SpaceQueueStateItemModel.listFromDynamic(body);
    }
    throw ServerException(
      'Invalid CAMS queue response.',
      FailureKind.unexpected,
      null,
      response.statusCode,
      _requestDebugContext(path: path, payload: body),
    );
  }

  Never _throwMappedDioException(
    DioException error, {
    required String fallbackMessage,
    required String primaryPath,
    String? fallbackPath,
  }) {
    final exception = ErrorMapper.fromDioException(
      error,
      fallbackMessage: fallbackMessage,
    );
    final debugMessage = [
      _requestDebugContext(path: primaryPath),
      if (fallbackPath != null && fallbackPath != primaryPath)
        'fallbackPath=$fallbackPath',
      if (exception.debugMessage != null && exception.debugMessage!.isNotEmpty)
        exception.debugMessage,
    ].join(' | ');
    throw ServerException(
      exception.message,
      exception.kind,
      exception.backendCode,
      exception.statusCode,
      debugMessage,
      exception.isRetryable,
    );
  }

  Never _throwApiResponseFailure(
    dynamic payload, {
    required String fallbackMessage,
    required String path,
    int? statusCode,
  }) {
    throw ErrorMapper.fromApiResponsePayload(
      payload,
      fallbackMessage: fallbackMessage,
      statusCode: statusCode,
      debugMessage: _requestDebugContext(path: path, payload: payload),
    );
  }

  String _requestDebugContext({
    required String path,
    dynamic payload,
  }) {
    return [
      'path=$path',
      if (payload != null) 'payload=$payload',
    ].join(' | ');
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
