import '../../../../core/enums/override_mode_enum.dart';
import '../../domain/entities/space_queue_state_item.dart';
import '../../domain/entities/space_playback_state.dart';
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
    super.startedAtUtc,
    super.expectedEndAtUtc,
    super.isPaused,
    super.pausePositionSeconds,
    super.seekOffsetSeconds,
    super.pendingQueueItemId,
    super.pendingPlaylistId,
    super.pendingOverrideReason,
    super.volumePercent,
    super.isMuted,
    super.queueEndBehavior,
    super.spaceQueueItems,
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
      startedAtUtc: _readDateTime(json, 'startedAtUtc'),
      expectedEndAtUtc: _readDateTime(json, 'expectedEndAtUtc'),
      isPaused: _readBool(json, 'isPaused') ?? false,
      pausePositionSeconds: _readNum(json, 'pausePositionSeconds')?.toInt(),
      seekOffsetSeconds: _readNum(json, 'seekOffsetSeconds')?.toDouble(),
      pendingQueueItemId: pendingQueueItemId ?? pendingPlaylistId,
      pendingPlaylistId: pendingPlaylistId,
      pendingOverrideReason: _readString(json, 'pendingOverrideReason'),
      volumePercent: _readNum(json, 'volumePercent')?.toInt() ?? 100,
      isMuted: _readBool(json, 'isMuted') ?? false,
      queueEndBehavior: _readNum(json, 'queueEndBehavior')?.toInt() ?? 0,
      spaceQueueItems: queueItems.cast<SpaceQueueStateItem>(),
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
}
