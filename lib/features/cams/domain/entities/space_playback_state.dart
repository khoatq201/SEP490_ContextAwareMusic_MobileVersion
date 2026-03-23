import 'package:equatable/equatable.dart';
import '../../../../core/enums/override_mode_enum.dart';

/// Represents the live playback state of a Space.
/// Matches backend GET /api/cams/spaces/{spaceId}/state response.
class SpacePlaybackState extends Equatable {
  final String spaceId;
  final String? storeId;
  final String? brandId;
  final String? currentPlaylistId;
  final String? currentPlaylistName;
  final String? hlsUrl;
  final String? moodName;
  final bool isManualOverride;
  final OverrideModeEnum? overrideMode;
  final DateTime? startedAtUtc;
  final DateTime? expectedEndAtUtc;
  final bool isPaused;
  final int? pausePositionSeconds;

  /// Real-time seek offset (seconds) calculated server-side.
  final double? seekOffsetSeconds;
  final String? pendingPlaylistId;
  final String? pendingOverrideReason;

  const SpacePlaybackState({
    required this.spaceId,
    this.storeId,
    this.brandId,
    this.currentPlaylistId,
    this.currentPlaylistName,
    this.hlsUrl,
    this.moodName,
    this.isManualOverride = false,
    this.overrideMode,
    this.startedAtUtc,
    this.expectedEndAtUtc,
    this.isPaused = false,
    this.pausePositionSeconds,
    this.seekOffsetSeconds,
    this.pendingPlaylistId,
    this.pendingOverrideReason,
  });

  /// Whether any playlist is currently streaming
  bool get isStreaming =>
      currentPlaylistId != null && hlsUrl != null && hlsUrl!.isNotEmpty;

  bool get hasPendingPlaylist =>
      pendingPlaylistId != null && pendingPlaylistId!.isNotEmpty;

  /// Whether override is currently active
  bool get hasActiveOverride => isManualOverride && overrideMode != null;

  double get effectiveSeekOffset {
    if (isPaused) {
      return pausePositionSeconds?.toDouble() ?? seekOffsetSeconds ?? 0;
    }
    if (startedAtUtc != null) {
      final elapsedSeconds =
          DateTime.now().toUtc().difference(startedAtUtc!).inMilliseconds /
              1000.0;
      return elapsedSeconds < 0 ? 0 : elapsedSeconds;
    }
    return seekOffsetSeconds ?? 0;
  }

  @override
  List<Object?> get props => [
        spaceId,
        storeId,
        brandId,
        currentPlaylistId,
        currentPlaylistName,
        hlsUrl,
        moodName,
        isManualOverride,
        overrideMode,
        startedAtUtc,
        expectedEndAtUtc,
        isPaused,
        pausePositionSeconds,
        seekOffsetSeconds,
        pendingPlaylistId,
        pendingOverrideReason,
      ];
}
