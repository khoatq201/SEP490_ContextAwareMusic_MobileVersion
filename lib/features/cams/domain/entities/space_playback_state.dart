import 'package:equatable/equatable.dart';
import '../../../core/enums/override_mode_enum.dart';

/// Represents the live playback state of a Space.
/// Matches backend GET /api/cams/spaces/{spaceId}/state response.
class SpacePlaybackState extends Equatable {
  final String spaceId;
  final String? currentPlaylistId;
  final String? currentPlaylistName;
  final String? hlsUrl;
  final String? moodName;
  final bool isManualOverride;
  final OverrideModeEnum? overrideMode;
  final DateTime? startedAtUtc;
  final DateTime? expectedEndAtUtc;

  /// Real-time seek offset (seconds) calculated server-side.
  final double? seekOffsetSeconds;

  const SpacePlaybackState({
    required this.spaceId,
    this.currentPlaylistId,
    this.currentPlaylistName,
    this.hlsUrl,
    this.moodName,
    this.isManualOverride = false,
    this.overrideMode,
    this.startedAtUtc,
    this.expectedEndAtUtc,
    this.seekOffsetSeconds,
  });

  /// Whether any playlist is currently streaming
  bool get isStreaming =>
      currentPlaylistId != null && hlsUrl != null && hlsUrl!.isNotEmpty;

  /// Whether override is currently active
  bool get hasActiveOverride => isManualOverride && overrideMode != null;

  @override
  List<Object?> get props => [
        spaceId,
        currentPlaylistId,
        currentPlaylistName,
        hlsUrl,
        moodName,
        isManualOverride,
        overrideMode,
        startedAtUtc,
        expectedEndAtUtc,
        seekOffsetSeconds,
      ];
}
