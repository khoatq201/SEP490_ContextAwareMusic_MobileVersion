import '../../domain/entities/space_playback_state.dart';
import '../../../../core/enums/override_mode_enum.dart';

class SpacePlaybackStateModel extends SpacePlaybackState {
  const SpacePlaybackStateModel({
    required super.spaceId,
    super.storeId,
    super.brandId,
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
    super.pendingPlaylistId,
    super.pendingOverrideReason,
  });

  /// Parse from GET /api/cams/spaces/{spaceId}/state -> data field.
  factory SpacePlaybackStateModel.fromJson(Map<String, dynamic> json) {
    return SpacePlaybackStateModel(
      spaceId: _readString(json, 'spaceId') ?? '',
      storeId: _readString(json, 'storeId'),
      brandId: _readString(json, 'brandId'),
      currentPlaylistId: _readString(json, 'currentPlaylistId'),
      currentPlaylistName: _readString(json, 'currentPlaylistName'),
      hlsUrl: _readString(json, 'hlsUrl'),
      moodName: _readString(json, 'moodName'),
      isManualOverride: _readBool(json, 'isManualOverride') ?? false,
      overrideMode: OverrideModeEnum.fromJson(_readValue(json, 'overrideMode')),
      startedAtUtc: _readDateTime(json, 'startedAtUtc'),
      expectedEndAtUtc: _readDateTime(json, 'expectedEndAtUtc'),
      isPaused: _readBool(json, 'isPaused') ?? false,
      pausePositionSeconds: _readNum(json, 'pausePositionSeconds')?.toInt(),
      seekOffsetSeconds: _readNum(json, 'seekOffsetSeconds')?.toDouble(),
      pendingPlaylistId: _readString(json, 'pendingPlaylistId'),
      pendingOverrideReason: _readString(json, 'pendingOverrideReason'),
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
