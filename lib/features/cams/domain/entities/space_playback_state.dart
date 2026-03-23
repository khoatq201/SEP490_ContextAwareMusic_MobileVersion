import 'package:equatable/equatable.dart';

import '../../../../core/enums/override_mode_enum.dart';
import 'space_queue_state_item.dart';

/// Represents the live playback state of a Space.
/// Supports both legacy playlist-centric payload and queue-first payload.
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

  bool get hasPendingPlayback => hasPendingQueueItem || hasPendingPlaylist;

  /// Whether override is currently active.
  bool get hasActiveOverride => isManualOverride && overrideMode != null;

  /// Resolved identity used by compat layers during migration.
  String? get currentIdentityId => currentQueueItemId ?? currentPlaylistId;

  String? get currentDisplayName =>
      currentTrackName ?? currentPlaylistName ?? moodName;

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
