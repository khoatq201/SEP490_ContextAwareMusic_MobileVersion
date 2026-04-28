import 'package:equatable/equatable.dart';

import '../../../../core/enums/ai_generation_mode_enum.dart';
import '../../../../core/enums/override_mode_enum.dart';
import '../../../../core/enums/scheduling_slot_origin_enum.dart';
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
      return '${recommendedBpmMin!} - ${recommendedBpmMax!} BPM';
    }
    if (recommendedBpmTarget != null) {
      return '${recommendedBpmTarget!} BPM';
    }
    return null;
  }

  String? get bpmTargetLabel {
    if (recommendedBpmTarget == null) return null;
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
  final String? overrideReason;
  final DateTime? manualOverrideActivatedAtUtc;
  final DateTime? manualOverrideExpiresAtUtc;
  final int? manualOverrideTtlSeconds;
  final int? manualOverrideRemainingSeconds;
  final bool isScheduling;
  final String? schedulingSlotId;
  final SchedulingSlotOriginEnum? schedulingSlotOrigin;
  final DateTime? schedulingEndsAtUtc;
  final int? schedulingRemainingSeconds;
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
  final bool isIotDeviceOffline;
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
    this.overrideReason,
    this.manualOverrideActivatedAtUtc,
    this.manualOverrideExpiresAtUtc,
    this.manualOverrideTtlSeconds,
    this.manualOverrideRemainingSeconds,
    this.isScheduling = false,
    this.schedulingSlotId,
    this.schedulingSlotOrigin,
    this.schedulingEndsAtUtc,
    this.schedulingRemainingSeconds,
    this.startedAtUtc,
    this.expectedEndAtUtc,
    this.isPaused = false,
    this.pausePositionSeconds,
    this.seekOffsetSeconds,
    this.pendingQueueItemId,
    this.pendingPlaylistId,
    this.pendingOverrideReason,
    this.volumePercent = 100,
    this.isIotDeviceOffline = false,
    this.isMuted = false,
    this.queueEndBehavior = 0,
    this.spaceQueueItems = const [],
    this.explainability,
  });

  SpaceQueueStateItem? get effectiveQueueItem {
    if (spaceQueueItems.isEmpty) {
      return null;
    }

    if (currentQueueItemId != null && currentQueueItemId!.isNotEmpty) {
      for (final item in spaceQueueItems) {
        if (item.queueItemId == currentQueueItemId) {
          return item;
        }
      }
    }

    for (final item in spaceQueueItems) {
      if (item.queueStatus == queueStatusPlaying) {
        return item;
      }
    }

    return null;
  }

  List<SpaceQueueStateItem> get sortedQueueItems {
    final sortedItems = [...spaceQueueItems]
      ..sort((a, b) => a.position.compareTo(b.position));
    return List<SpaceQueueStateItem>.unmodifiable(sortedItems);
  }

  SpaceQueueStateItem? get focusedQueueItem {
    final sortedItems = sortedQueueItems;
    final focusedIndex = _resolveFocusedQueueIndex(sortedItems);
    if (focusedIndex < 0 || focusedIndex >= sortedItems.length) {
      return null;
    }
    return sortedItems[focusedIndex];
  }

  SpaceQueueStateItem? get previousQueueItem {
    final sortedItems = sortedQueueItems;
    final focusedIndex = _resolveFocusedQueueIndex(sortedItems);
    if (focusedIndex <= 0 || focusedIndex >= sortedItems.length) {
      return null;
    }
    return sortedItems[focusedIndex - 1];
  }

  String? get effectiveQueueItemId {
    if (currentQueueItemId != null && currentQueueItemId!.isNotEmpty) {
      return currentQueueItemId;
    }
    final queueItemId = effectiveQueueItem?.queueItemId;
    if (queueItemId != null && queueItemId.isNotEmpty) {
      return queueItemId;
    }
    return null;
  }

  String? get effectiveTrackName {
    if (currentTrackName != null && currentTrackName!.isNotEmpty) {
      return currentTrackName;
    }
    final queueTrackName = effectiveQueueItem?.trackName;
    if (queueTrackName != null && queueTrackName.isNotEmpty) {
      return queueTrackName;
    }
    return currentPlaylistName;
  }

  String? get effectiveHlsUrl {
    if (hlsUrl != null && hlsUrl!.isNotEmpty) {
      return hlsUrl;
    }
    final queueHlsUrl = effectiveQueueItem?.hlsUrl;
    if (queueHlsUrl != null && queueHlsUrl.isNotEmpty) {
      return queueHlsUrl;
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

  bool get hasRuntimeScheduling => isScheduling;

  String? get schedulingOriginLabel => schedulingSlotOrigin?.label;

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

  int _resolveFocusedQueueIndex(List<SpaceQueueStateItem> sortedItems) {
    if (sortedItems.isEmpty) return -1;

    final currentQueueItemId = this.currentQueueItemId;
    if (currentQueueItemId != null && currentQueueItemId.isNotEmpty) {
      final currentIndex = sortedItems.indexWhere(
        (item) => item.queueItemId == currentQueueItemId,
      );
      if (currentIndex >= 0) {
        return currentIndex;
      }
    }

    final playingIndex = sortedItems.indexWhere(
      (item) => item.queueStatus == queueStatusPlaying,
    );
    if (playingIndex >= 0) {
      return playingIndex;
    }

    final pendingQueueItemId = this.pendingQueueItemId;
    if (pendingQueueItemId != null && pendingQueueItemId.isNotEmpty) {
      final pendingIndex = sortedItems.indexWhere(
        (item) => item.queueItemId == pendingQueueItemId,
      );
      if (pendingIndex >= 0) {
        return pendingIndex;
      }
    }

    final currentTrackName = this.currentTrackName?.trim().toLowerCase();
    if (currentTrackName != null && currentTrackName.isNotEmpty) {
      final currentTrackIndex = sortedItems.indexWhere((item) {
        final trackName = item.trackName?.trim().toLowerCase();
        return trackName != null && trackName == currentTrackName;
      });
      if (currentTrackIndex >= 0) {
        return currentTrackIndex;
      }
    }

    return sortedItems.indexWhere(
      (item) => item.queueStatus == queueStatusPending,
    );
  }

  SpacePlaybackState copyWith({
    String? spaceId,
    String? storeId,
    String? brandId,
    String? currentQueueItemId,
    String? currentTrackName,
    String? currentPlaylistId,
    String? currentPlaylistName,
    String? hlsUrl,
    String? moodName,
    bool? isManualOverride,
    OverrideModeEnum? overrideMode,
    String? overrideReason,
    DateTime? manualOverrideActivatedAtUtc,
    DateTime? manualOverrideExpiresAtUtc,
    int? manualOverrideTtlSeconds,
    int? manualOverrideRemainingSeconds,
    bool? isScheduling,
    String? schedulingSlotId,
    SchedulingSlotOriginEnum? schedulingSlotOrigin,
    DateTime? schedulingEndsAtUtc,
    int? schedulingRemainingSeconds,
    DateTime? startedAtUtc,
    DateTime? expectedEndAtUtc,
    bool? isPaused,
    int? pausePositionSeconds,
    double? seekOffsetSeconds,
    String? pendingQueueItemId,
    String? pendingPlaylistId,
    String? pendingOverrideReason,
    int? volumePercent,
    bool? isIotDeviceOffline,
    bool? isMuted,
    int? queueEndBehavior,
    List<SpaceQueueStateItem>? spaceQueueItems,
    SpacePlaybackExplainability? explainability,
    bool clearStoreId = false,
    bool clearBrandId = false,
    bool clearCurrentQueueItemId = false,
    bool clearCurrentTrackName = false,
    bool clearCurrentPlaylistId = false,
    bool clearCurrentPlaylistName = false,
    bool clearHlsUrl = false,
    bool clearMoodName = false,
    bool clearOverrideMode = false,
    bool clearOverrideReason = false,
    bool clearManualOverrideActivatedAtUtc = false,
    bool clearManualOverrideExpiresAtUtc = false,
    bool clearManualOverrideTtlSeconds = false,
    bool clearManualOverrideRemainingSeconds = false,
    bool clearSchedulingSlotId = false,
    bool clearSchedulingSlotOrigin = false,
    bool clearSchedulingEndsAtUtc = false,
    bool clearSchedulingRemainingSeconds = false,
    bool clearStartedAtUtc = false,
    bool clearExpectedEndAtUtc = false,
    bool clearPausePositionSeconds = false,
    bool clearSeekOffsetSeconds = false,
    bool clearPendingQueueItemId = false,
    bool clearPendingPlaylistId = false,
    bool clearPendingOverrideReason = false,
    bool clearExplainability = false,
  }) {
    return SpacePlaybackState(
      spaceId: spaceId ?? this.spaceId,
      storeId: clearStoreId ? null : (storeId ?? this.storeId),
      brandId: clearBrandId ? null : (brandId ?? this.brandId),
      currentQueueItemId: clearCurrentQueueItemId
          ? null
          : (currentQueueItemId ?? this.currentQueueItemId),
      currentTrackName: clearCurrentTrackName
          ? null
          : (currentTrackName ?? this.currentTrackName),
      currentPlaylistId: clearCurrentPlaylistId
          ? null
          : (currentPlaylistId ?? this.currentPlaylistId),
      currentPlaylistName: clearCurrentPlaylistName
          ? null
          : (currentPlaylistName ?? this.currentPlaylistName),
      hlsUrl: clearHlsUrl ? null : (hlsUrl ?? this.hlsUrl),
      moodName: clearMoodName ? null : (moodName ?? this.moodName),
      isManualOverride: isManualOverride ?? this.isManualOverride,
      overrideMode:
          clearOverrideMode ? null : (overrideMode ?? this.overrideMode),
      overrideReason:
          clearOverrideReason ? null : (overrideReason ?? this.overrideReason),
      manualOverrideActivatedAtUtc: clearManualOverrideActivatedAtUtc
          ? null
          : (manualOverrideActivatedAtUtc ?? this.manualOverrideActivatedAtUtc),
      manualOverrideExpiresAtUtc: clearManualOverrideExpiresAtUtc
          ? null
          : (manualOverrideExpiresAtUtc ?? this.manualOverrideExpiresAtUtc),
      manualOverrideTtlSeconds: clearManualOverrideTtlSeconds
          ? null
          : (manualOverrideTtlSeconds ?? this.manualOverrideTtlSeconds),
      manualOverrideRemainingSeconds: clearManualOverrideRemainingSeconds
          ? null
          : (manualOverrideRemainingSeconds ??
              this.manualOverrideRemainingSeconds),
      isScheduling: isScheduling ?? this.isScheduling,
      schedulingSlotId: clearSchedulingSlotId
          ? null
          : (schedulingSlotId ?? this.schedulingSlotId),
      schedulingSlotOrigin: clearSchedulingSlotOrigin
          ? null
          : (schedulingSlotOrigin ?? this.schedulingSlotOrigin),
      schedulingEndsAtUtc: clearSchedulingEndsAtUtc
          ? null
          : (schedulingEndsAtUtc ?? this.schedulingEndsAtUtc),
      schedulingRemainingSeconds: clearSchedulingRemainingSeconds
          ? null
          : (schedulingRemainingSeconds ?? this.schedulingRemainingSeconds),
      startedAtUtc:
          clearStartedAtUtc ? null : (startedAtUtc ?? this.startedAtUtc),
      expectedEndAtUtc: clearExpectedEndAtUtc
          ? null
          : (expectedEndAtUtc ?? this.expectedEndAtUtc),
      isPaused: isPaused ?? this.isPaused,
      pausePositionSeconds: clearPausePositionSeconds
          ? null
          : (pausePositionSeconds ?? this.pausePositionSeconds),
      seekOffsetSeconds: clearSeekOffsetSeconds
          ? null
          : (seekOffsetSeconds ?? this.seekOffsetSeconds),
      pendingQueueItemId: clearPendingQueueItemId
          ? null
          : (pendingQueueItemId ?? this.pendingQueueItemId),
      pendingPlaylistId: clearPendingPlaylistId
          ? null
          : (pendingPlaylistId ?? this.pendingPlaylistId),
      pendingOverrideReason: clearPendingOverrideReason
          ? null
          : (pendingOverrideReason ?? this.pendingOverrideReason),
      volumePercent: volumePercent ?? this.volumePercent,
      isIotDeviceOffline: isIotDeviceOffline ?? this.isIotDeviceOffline,
      isMuted: isMuted ?? this.isMuted,
      queueEndBehavior: queueEndBehavior ?? this.queueEndBehavior,
      spaceQueueItems: spaceQueueItems ?? this.spaceQueueItems,
      explainability:
          clearExplainability ? null : (explainability ?? this.explainability),
    );
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
        overrideReason,
        manualOverrideActivatedAtUtc,
        manualOverrideExpiresAtUtc,
        manualOverrideTtlSeconds,
        manualOverrideRemainingSeconds,
        isScheduling,
        schedulingSlotId,
        schedulingSlotOrigin,
        schedulingEndsAtUtc,
        schedulingRemainingSeconds,
        startedAtUtc,
        expectedEndAtUtc,
        isPaused,
        pausePositionSeconds,
        seekOffsetSeconds,
        pendingQueueItemId,
        pendingPlaylistId,
        pendingOverrideReason,
        volumePercent,
        isIotDeviceOffline,
        isMuted,
        queueEndBehavior,
        spaceQueueItems,
        explainability,
      ];
}
