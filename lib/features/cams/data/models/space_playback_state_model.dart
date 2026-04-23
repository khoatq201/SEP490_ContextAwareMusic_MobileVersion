import '../../../../core/enums/override_mode_enum.dart';
import '../../../../core/enums/ai_generation_mode_enum.dart';
import '../../../../core/enums/scheduling_slot_origin_enum.dart';
import '../../domain/entities/space_playback_state.dart';
import '../../domain/entities/space_queue_state_item.dart';
import 'space_queue_state_item_model.dart';

class SpacePlaybackStateModel extends SpacePlaybackState {
  const SpacePlaybackStateModel({
    required super.spaceId,
    super.storeId,
    super.brandId,
    super.currentQueueItemId,
    super.currentTrackName,
    super.currentPlaylistId,
    super.currentPlaylistName,
    super.hlsUrl,
    super.moodName,
    super.isManualOverride,
    super.overrideMode,
    super.overrideReason,
    super.manualOverrideActivatedAtUtc,
    super.manualOverrideExpiresAtUtc,
    super.manualOverrideTtlSeconds,
    super.manualOverrideRemainingSeconds,
    super.isScheduling,
    super.schedulingSlotId,
    super.schedulingSlotOrigin,
    super.schedulingEndsAtUtc,
    super.schedulingRemainingSeconds,
    super.startedAtUtc,
    super.expectedEndAtUtc,
    super.isPaused,
    super.pausePositionSeconds,
    super.seekOffsetSeconds,
    super.pendingQueueItemId,
    super.pendingPlaylistId,
    super.pendingOverrideReason,
    super.volumePercent,
    super.isIotDeviceOffline,
    super.isMuted,
    super.queueEndBehavior,
    super.spaceQueueItems,
    super.explainability,
  });

  /// Parse from GET /api/cams/spaces/{spaceId}/state -> data field.
  /// Compatible with both legacy and queue-first schemas.
  factory SpacePlaybackStateModel.fromJson(Map<String, dynamic> json) {
    final currentQueueItemId = _readString(json, 'currentQueueItemId');
    final currentPlaylistId = _readString(json, 'currentPlaylistId');
    final currentTrackName = _readString(json, 'currentTrackName');
    final currentPlaylistName = _readString(json, 'currentPlaylistName');
    final pendingQueueItemId = _readString(json, 'pendingQueueItemId');
    final pendingPlaylistId = _readString(json, 'pendingPlaylistId');
    final queueItems = SpaceQueueStateItemModel.listFromDynamic(
      _readValue(json, 'spaceQueueItems') ?? _readValue(json, 'queueItems'),
    );

    return SpacePlaybackStateModel(
      spaceId: _readString(json, 'spaceId') ?? '',
      storeId: _readString(json, 'storeId'),
      brandId: _readString(json, 'brandId'),
      currentQueueItemId: currentQueueItemId ?? currentPlaylistId,
      currentTrackName: currentTrackName ?? currentPlaylistName,
      currentPlaylistId: currentPlaylistId,
      currentPlaylistName: currentPlaylistName,
      hlsUrl: _readString(json, 'hlsUrl'),
      moodName: _readString(json, 'moodName'),
      isManualOverride: _readBool(json, 'isManualOverride') ?? false,
      overrideMode: OverrideModeEnum.fromJson(_readValue(json, 'overrideMode')),
      overrideReason: _readString(json, 'overrideReason'),
      manualOverrideActivatedAtUtc:
          _readDateTime(json, 'manualOverrideActivatedAtUtc'),
      manualOverrideExpiresAtUtc:
          _readDateTime(json, 'manualOverrideExpiresAtUtc'),
      manualOverrideTtlSeconds:
          _readNum(json, 'manualOverrideTtlSeconds')?.toInt(),
      manualOverrideRemainingSeconds:
          _readNum(json, 'manualOverrideRemainingSeconds')?.toInt(),
      isScheduling: _readBool(json, 'isScheduling') ?? false,
      schedulingSlotId: _readString(json, 'schedulingSlotId'),
      schedulingSlotOrigin: SchedulingSlotOriginEnum.fromJson(
          _readValue(json, 'schedulingSlotOrigin')),
      schedulingEndsAtUtc: _readDateTime(json, 'schedulingEndsAtUtc'),
      schedulingRemainingSeconds:
          _readNum(json, 'schedulingRemainingSeconds')?.toInt(),
      startedAtUtc: _readDateTime(json, 'startedAtUtc'),
      expectedEndAtUtc: _readDateTime(json, 'expectedEndAtUtc'),
      isPaused: _readBool(json, 'isPaused') ?? false,
      pausePositionSeconds: _readNum(json, 'pausePositionSeconds')?.toInt(),
      seekOffsetSeconds: _readNum(json, 'seekOffsetSeconds')?.toDouble(),
      pendingQueueItemId: pendingQueueItemId ?? pendingPlaylistId,
      pendingPlaylistId: pendingPlaylistId,
      pendingOverrideReason: _readString(json, 'pendingOverrideReason'),
      volumePercent: _readNum(json, 'volumePercent')?.toInt() ?? 100,
      isIotDeviceOffline: _readBool(json, 'isIotDeviceOffline') ?? false,
      isMuted: _readBool(json, 'isMuted') ?? false,
      queueEndBehavior: _readNum(json, 'queueEndBehavior')?.toInt() ?? 0,
      spaceQueueItems: queueItems.cast<SpaceQueueStateItem>(),
      explainability: _readExplainability(json),
    );
  }

  /// Parse from full API response wrapper:
  /// { "isSuccess": true, "data": { ... } }
  static SpacePlaybackStateModel? fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map) return null;
    return SpacePlaybackStateModel.fromJson(Map<String, dynamic>.from(data));
  }

  /// Parse from SignalR SpaceStateSync event payload (same structure).
  factory SpacePlaybackStateModel.fromSignalR(Map<String, dynamic> payload) {
    return SpacePlaybackStateModel.fromJson(payload);
  }

  static dynamic _readValue(Map<String, dynamic> json, String key) {
    if (json.containsKey(key)) return json[key];
    if (key.isEmpty) return null;
    final pascalCaseKey = '${key[0].toUpperCase()}${key.substring(1)}';
    return json[pascalCaseKey];
  }

  static String? _readString(Map<String, dynamic> json, String key) {
    final value = _readValue(json, key);
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static num? _readNum(Map<String, dynamic> json, String key) {
    final value = _readValue(json, key);
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  static bool? _readBool(Map<String, dynamic> json, String key) {
    final value = _readValue(json, key);
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return null;
  }

  static DateTime? _readDateTime(Map<String, dynamic> json, String key) {
    final value = _readValue(json, key);
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static SpacePlaybackExplainability? _readExplainability(
    Map<String, dynamic> json,
  ) {
    final nested = _readExplainabilityPayload(json);
    final mergedSource = <String, dynamic>{...json};
    if (nested != null) {
      mergedSource.addAll(nested);
    }

    final hasCoreExplainability = _hasExplainabilityKeys(mergedSource);
    if (!hasCoreExplainability && nested == null) {
      return null;
    }

    final explainability = SpacePlaybackExplainability(
      triggeredRule: _readString(mergedSource, 'triggeredRule') ??
          _readString(mergedSource, 'fuzzyRule'),
      reason: _readString(mergedSource, 'reason') ??
          _readString(mergedSource, 'fuzzyReason'),
      moodName: _readString(mergedSource, 'moodName') ??
          _readString(mergedSource, 'newMood') ??
          _readString(mergedSource, 'selectedMoodName'),
      recommendedBpmMin: _readNum(mergedSource, 'recommendedBpmMin')?.toInt() ??
          _readNum(mergedSource, 'bpmMin')?.toInt(),
      recommendedBpmMax: _readNum(mergedSource, 'recommendedBpmMax')?.toInt() ??
          _readNum(mergedSource, 'bpmMax')?.toInt(),
      recommendedBpmTarget:
          _readNum(mergedSource, 'recommendedBpmTarget')?.toInt() ??
              _readNum(mergedSource, 'bpmTarget')?.toInt(),
      usedMoodOnlyFallback: _readBool(mergedSource, 'usedMoodOnlyFallback') ??
          _readBool(mergedSource, 'bpmFallback') ??
          _readBool(mergedSource, 'isBpmFallback'),
      moodOnlyCount: _readNum(mergedSource, 'moodOnlyCount')?.toInt(),
      bpmFilteredCount: _readNum(mergedSource, 'bpmFilteredCount')?.toInt(),
      aiGenerationMode: _readAiGenerationMode(mergedSource),
      fuzzyProfileName: _readString(mergedSource, 'fuzzyProfileName') ??
          _readString(mergedSource, 'profileName') ??
          _readString(mergedSource, 'musicProfileName'),
      fuzzyProfileTemplate: _readString(mergedSource, 'fuzzyProfileTemplate') ??
          _readString(mergedSource, 'profileTemplate') ??
          _readString(mergedSource, 'templateName'),
      restrictedToAllowedPlaylists:
          _readBool(mergedSource, 'restrictedToAllowedPlaylists') ??
              _readBool(mergedSource, 'isRestricted') ??
              _readBool(mergedSource, 'restricted'),
      allowedPlaylistCount:
          _readNum(mergedSource, 'allowedPlaylistCount')?.toInt() ??
              _readNum(mergedSource, 'restrictedPlaylistCount')?.toInt(),
    );

    return explainability.hasAnyData ? explainability : null;
  }

  static Map<String, dynamic>? _readExplainabilityPayload(
    Map<String, dynamic> json,
  ) {
    const keys = [
      'explainability',
      'aiExplainability',
      'selectionExplainability',
      'musicSelectionExplainability',
      'aiTrace',
      'fuzzyExplainability',
      'fuzzyResult',
    ];
    for (final key in keys) {
      final value = _readValue(json, key);
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
    }
    return null;
  }

  static bool _hasExplainabilityKeys(Map<String, dynamic> json) {
    const keys = [
      'triggeredRule',
      'reason',
      'recommendedBpmMin',
      'recommendedBpmMax',
      'recommendedBpmTarget',
      'bpmMin',
      'bpmMax',
      'bpmTarget',
      'usedMoodOnlyFallback',
      'bpmFallback',
      'isBpmFallback',
      'moodOnlyCount',
      'bpmFilteredCount',
      'fuzzyRule',
      'fuzzyReason',
      'newMood',
      'selectedMoodName',
      'aiGenerationMode',
      'generationMode',
      'fuzzyProfileName',
      'profileName',
      'fuzzyProfileTemplate',
      'profileTemplate',
      'restrictedToAllowedPlaylists',
      'isRestricted',
      'restricted',
      'allowedPlaylistCount',
    ];
    for (final key in keys) {
      if (_readValue(json, key) != null) {
        return true;
      }
    }
    return false;
  }

  static AiGenerationModeEnum? _readAiGenerationMode(
    Map<String, dynamic> json,
  ) {
    for (final key in const ['aiGenerationMode', 'generationMode']) {
      final value = _readValue(json, key);
      if (value == null) continue;
      final parsed = AiGenerationModeEnum.fromJson(value);
      if (parsed != AiGenerationModeEnum.unknown) {
        return parsed;
      }
    }
    return null;
  }
}
