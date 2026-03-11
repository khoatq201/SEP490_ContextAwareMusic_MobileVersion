import '../../domain/entities/space_playback_state.dart';
import '../../../../core/enums/override_mode_enum.dart';

class SpacePlaybackStateModel extends SpacePlaybackState {
  const SpacePlaybackStateModel({
    required super.spaceId,
    super.currentPlaylistId,
    super.currentPlaylistName,
    super.hlsUrl,
    super.moodName,
    super.isManualOverride,
    super.overrideMode,
    super.startedAtUtc,
    super.expectedEndAtUtc,
    super.seekOffsetSeconds,
  });

  /// Parse from GET /api/cams/spaces/{spaceId}/state → data field.
  factory SpacePlaybackStateModel.fromJson(Map<String, dynamic> json) {
    return SpacePlaybackStateModel(
      spaceId: json['spaceId'] as String,
      currentPlaylistId: json['currentPlaylistId'] as String?,
      currentPlaylistName: json['currentPlaylistName'] as String?,
      hlsUrl: json['hlsUrl'] as String?,
      moodName: json['moodName'] as String?,
      isManualOverride: json['isManualOverride'] as bool? ?? false,
      overrideMode: OverrideModeEnum.fromJson(json['overrideMode']),
      startedAtUtc: json['startedAtUtc'] != null
          ? DateTime.tryParse(json['startedAtUtc'] as String)
          : null,
      expectedEndAtUtc: json['expectedEndAtUtc'] != null
          ? DateTime.tryParse(json['expectedEndAtUtc'] as String)
          : null,
      seekOffsetSeconds: (json['seekOffsetSeconds'] as num?)?.toDouble(),
    );
  }

  /// Parse from full API response wrapper:
  /// { "isSuccess": true, "data": { ... } }
  static SpacePlaybackStateModel? fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) return null;
    return SpacePlaybackStateModel.fromJson(data);
  }

  /// Parse from SignalR SpaceStateSync event payload (same structure).
  factory SpacePlaybackStateModel.fromSignalR(Map<String, dynamic> payload) {
    return SpacePlaybackStateModel.fromJson(payload);
  }
}
