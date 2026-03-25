import 'package:equatable/equatable.dart';

import '../../../../core/enums/override_mode_enum.dart';
import 'space_queue_state_item.dart';

/// Represents the live playback state of a Space.
/// Queue-first fields are authoritative; legacy playlist fields remain for
/// parser compatibility during migration only.
class SpacePlaybackState extends Equatable {
  final String spaceId;
  final String? storeId;
  final String? brandId;

  /// Queue-first identity fields (authoritative in CAMS v2).
  final String? currentQueueItemId;
  final String? currentTrackName;

  /// Legacy playlist-centric identity fields (compat parser only).
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

  /// Queue-first pending field.
  final String? pendingQueueItemId;

  /// Legacy pending field.
  final String? pendingPlaylistId;
  final String? pendingOverrideReason;

  /// Audio mix / end behavior.
  final int volumePercent;
  final bool isMuted;
  final int queueEndBehavior;

  /// Full queue snapshot from CAMS.
  final List<SpaceQueueStateItem> spaceQueueItems;

  const SpacePlaybackState({
    required this.spaceId,
    this.storeId,
    this.brandId,
    this.currentQueueItemId,
    this.currentTrackName,
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
    this.pendingQueueItemId,
    this.pendingPlaylistId,
    this.pendingOverrideReason,
    this.volumePercent = 100,
    this.isMuted = false,
    this.queueEndBehavior = 0,
    this.spaceQueueItems = const [],
  });

  bool get hasPlayableHls => hlsUrl != null && hlsUrl!.isNotEmpty;

  /// Whether any stream is currently available.
  bool get isStreaming => hasPlayableHls;

  bool get hasPendingQueueItem =>
      pendingQueueItemId != null && pendingQueueItemId!.isNotEmpty;

  bool get hasPendingPlaylist =>
      pendingPlaylistId != null && pendingPlaylistId!.isNotEmpty;

  bool get hasPendingPlayback => hasPendingQueueItem;

  /// Whether override is currently active.
  bool get hasActiveOverride => isManualOverride && overrideMode != null;

  /// Queue-first identity used by runtime playback orchestration.
  String? get currentIdentityId => currentQueueItemId;

  String? get currentDisplayName =>
      currentTrackName ?? moodName ?? currentPlaylistName;

  double get effectiveSeekOffset {
    if (isPaused) {
      final pausedOffset =
          pausePositionSeconds?.toDouble() ?? seekOffsetSeconds ?? 0;
      return _clampOffsetToExpectedDuration(pausedOffset);
    }
    if (startedAtUtc != null) {
      final elapsedSeconds =
          DateTime.now().toUtc().difference(startedAtUtc!).inMilliseconds /
              1000.0;
      return _clampOffsetToExpectedDuration(
        elapsedSeconds < 0 ? 0 : elapsedSeconds,
      );
    }
    return _clampOffsetToExpectedDuration(seekOffsetSeconds ?? 0);
  }

  double _clampOffsetToExpectedDuration(double offsetSeconds) {
    final safeOffset = offsetSeconds < 0 ? 0.0 : offsetSeconds;
    if (startedAtUtc == null || expectedEndAtUtc == null) {
      return safeOffset;
    }

    final totalDurationSeconds = expectedEndAtUtc!
            .toUtc()
            .difference(startedAtUtc!.toUtc())
            .inMilliseconds /
        1000.0;
    if (totalDurationSeconds <= 0) {
      return 0.0;
    }
    if (safeOffset > totalDurationSeconds) {
      return totalDurationSeconds;
    }
    return safeOffset;
  }

  @override
  List<Object?> get props => [
        spaceId,
        storeId,
        brandId,
        currentQueueItemId,
        currentTrackName,
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
        pendingQueueItemId,
        pendingPlaylistId,
        pendingOverrideReason,
        volumePercent,
        isMuted,
        queueEndBehavior,
        spaceQueueItems,
      ];
}
