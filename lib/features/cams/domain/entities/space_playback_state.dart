import 'package:equatable/equatable.dart';

import '../../../../core/enums/override_mode_enum.dart';
import 'space_queue_state_item.dart';

/// Represents the live playback state of a Space.
/// Queue-first fields are authoritative; legacy playlist fields remain for
/// parser compatibility during migration only.
class SpacePlaybackState extends Equatable {
  static const int queueStatusPending = 0;
  static const int queueStatusPlaying = 1;
  static const int queueStatusPlayed = 2;
  static const int queueStatusSkipped = 3;

  /// Clock drift compensation: (deviceTimeUtc − serverTimeUtc) in ms.
  /// Set once from StoreHubService.serverClockOffsetMs after
  /// `ConnectionConfirmed` is received.
  static int serverClockOffsetMs = 0;

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

  SpaceQueueStateItem? get effectiveQueueItem {
    if (spaceQueueItems.isEmpty ||
        currentQueueItemId == null ||
        currentQueueItemId!.isEmpty) {
      return null;
    }

    for (final item in spaceQueueItems) {
      if (item.queueItemId == currentQueueItemId) {
        return item;
      }
    }

    return null;
  }

  String? get effectiveQueueItemId {
    if (currentQueueItemId != null && currentQueueItemId!.isNotEmpty) {
      return currentQueueItemId;
    }
    return null;
  }

  String? get effectiveTrackName {
    if (currentTrackName != null && currentTrackName!.isNotEmpty) {
      return currentTrackName;
    }
    return currentPlaylistName;
  }

  String? get effectiveHlsUrl {
    if (hlsUrl != null && hlsUrl!.isNotEmpty) {
      return hlsUrl;
    }
    return null;
  }

  bool get hasPlayableHls =>
      effectiveHlsUrl != null && effectiveHlsUrl!.isNotEmpty;

  /// Whether any stream is currently available.
  bool get isStreaming => hasPlayableHls;

  /// Mirrors the web client's "isSpacePlaying" gate:
  /// when the server provides a playback window, the current HLS should only
  /// auto-play while `now` is still inside that window.
  ///
  /// If the timing window is absent, keep the current mobile fallback behavior
  /// and treat the HLS as eligible for playback.
  bool get isWithinPlaybackWindow {
    if (startedAtUtc == null || expectedEndAtUtc == null) {
      return true;
    }

    final nowUtc = DateTime.now().toUtc();
    final startedUtc = startedAtUtc!.toUtc();
    final expectedEndUtc = expectedEndAtUtc!.toUtc();
    return !nowUtc.isBefore(startedUtc) && !nowUtc.isAfter(expectedEndUtc);
  }

  bool get hasPendingQueueItem =>
      pendingQueueItemId != null && pendingQueueItemId!.isNotEmpty;

  bool get hasPendingPlaylist =>
      pendingPlaylistId != null && pendingPlaylistId!.isNotEmpty;

  bool get hasPendingPlayback => hasPendingQueueItem;

  /// Whether override is currently active.
  bool get hasActiveOverride => isManualOverride && overrideMode != null;

  /// Queue-first identity used by runtime playback orchestration.
  String? get currentIdentityId => effectiveQueueItemId ?? currentPlaylistId;

  String? get currentDisplayName =>
      effectiveTrackName ?? moodName ?? currentPlaylistName;

  double get effectiveSeekOffset {
    if (isPaused) {
      final pausedOffset =
          pausePositionSeconds?.toDouble() ?? seekOffsetSeconds ?? 0;
      return _clampOffsetToExpectedDuration(pausedOffset);
    }
    if (startedAtUtc != null) {
      final rawElapsed =
          DateTime.now().toUtc().difference(startedAtUtc!).inMilliseconds /
              1000.0;
      // Subtract device-vs-server clock drift so we don't run ahead.
      final compensatedElapsed =
          rawElapsed - (serverClockOffsetMs / 1000.0);
      return _clampOffsetToExpectedDuration(
        compensatedElapsed < 0 ? 0 : compensatedElapsed,
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
