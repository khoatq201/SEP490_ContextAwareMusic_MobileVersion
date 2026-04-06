import 'package:equatable/equatable.dart';

import '../../../../core/enums/ai_generation_mode_enum.dart';
import '../../../../core/enums/override_mode_enum.dart';
import 'space_queue_state_item.dart';

class SpacePlaybackExplainability extends Equatable {
  final String? triggeredRule;
  final String? reason;
  final String? moodName;
  final int? recommendedBpmMin;
  final int? recommendedBpmMax;
  final int? recommendedBpmTarget;
  final bool? usedMoodOnlyFallback;
  final int? moodOnlyCount;
  final int? bpmFilteredCount;
  final AiGenerationModeEnum? aiGenerationMode;
  final String? fuzzyProfileName;
  final String? fuzzyProfileTemplate;
  final bool? restrictedToAllowedPlaylists;
  final int? allowedPlaylistCount;

  const SpacePlaybackExplainability({
    this.triggeredRule,
    this.reason,
    this.moodName,
    this.recommendedBpmMin,
    this.recommendedBpmMax,
    this.recommendedBpmTarget,
    this.usedMoodOnlyFallback,
    this.moodOnlyCount,
    this.bpmFilteredCount,
    this.aiGenerationMode,
    this.fuzzyProfileName,
    this.fuzzyProfileTemplate,
    this.restrictedToAllowedPlaylists,
    this.allowedPlaylistCount,
  });

  bool get hasBpmBand => recommendedBpmMin != null && recommendedBpmMax != null;

  bool get hasAnyData =>
      (triggeredRule?.trim().isNotEmpty ?? false) ||
      (reason?.trim().isNotEmpty ?? false) ||
      (moodName?.trim().isNotEmpty ?? false) ||
      recommendedBpmMin != null ||
      recommendedBpmMax != null ||
      recommendedBpmTarget != null ||
      usedMoodOnlyFallback != null ||
      moodOnlyCount != null ||
      bpmFilteredCount != null ||
      aiGenerationMode != null ||
      (fuzzyProfileName?.trim().isNotEmpty ?? false) ||
      (fuzzyProfileTemplate?.trim().isNotEmpty ?? false) ||
      restrictedToAllowedPlaylists != null ||
      allowedPlaylistCount != null;

  String? get bpmBandLabel {
    if (hasBpmBand) {
      return '${recommendedBpmMin!}-${recommendedBpmMax!} BPM';
    }
    if (recommendedBpmTarget != null) {
      return 'Target ${recommendedBpmTarget!} BPM';
    }
    return null;
  }

  String? get bpmTargetLabel {
    if (recommendedBpmTarget == null) return null;
    if (hasBpmBand) {
      return 'Target ${recommendedBpmTarget!} BPM';
    }
    return '${recommendedBpmTarget!} BPM';
  }

  String? get playlistRestrictionLabel {
    if (allowedPlaylistCount != null) {
      final count = allowedPlaylistCount!;
      return '$count allowed playlist${count == 1 ? '' : 's'}';
    }
    if (restrictedToAllowedPlaylists == true) {
      return 'Playlist restriction enabled';
    }
    if (restrictedToAllowedPlaylists == false) {
      return 'No playlist restriction';
    }
    return null;
  }

  @override
  List<Object?> get props => [
        triggeredRule,
        reason,
        moodName,
        recommendedBpmMin,
        recommendedBpmMax,
        recommendedBpmTarget,
        usedMoodOnlyFallback,
        moodOnlyCount,
        bpmFilteredCount,
        aiGenerationMode,
        fuzzyProfileName,
        fuzzyProfileTemplate,
        restrictedToAllowedPlaylists,
        allowedPlaylistCount,
      ];
}

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
  final SpacePlaybackExplainability? explainability;

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
    this.explainability,
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
      final compensatedElapsed = rawElapsed - (serverClockOffsetMs / 1000.0);
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
        explainability,
      ];
}
