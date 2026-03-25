import 'package:equatable/equatable.dart';

import '../../../../core/enums/playback_command_enum.dart';
import '../../../../core/enums/queue_insert_mode_enum.dart';
import '../../domain/entities/space_playback_state.dart';

abstract class CamsPlaybackEvent extends Equatable {
  const CamsPlaybackEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize CAMS playback â€” connect SignalR, fetch state & moods.
class CamsInitPlayback extends CamsPlaybackEvent {
  final String spaceId;

  const CamsInitPlayback({required this.spaceId});

  @override
  List<Object?> get props => [spaceId];
}

/// Dispose CAMS â€” disconnect SignalR, leave space.
class CamsDisposePlayback extends CamsPlaybackEvent {
  const CamsDisposePlayback();
}

/// Override space with a specific mood.
class CamsOverrideMood extends CamsPlaybackEvent {
  final String moodId;
  final String? reason;

  const CamsOverrideMood({required this.moodId, this.reason});

  @override
  List<Object?> get props => [moodId, reason];
}

/// Queue-native playlist request.
class CamsPlayPlaylist extends CamsPlaybackEvent {
  final String playlistId;
  final String? reason;
  final bool clearExistingQueue;
  final QueueInsertModeEnum requestedMode;

  const CamsPlayPlaylist({
    required this.playlistId,
    this.reason,
    this.clearExistingQueue = false,
    this.requestedMode = QueueInsertModeEnum.addToQueue,
  });

  @override
  List<Object?> get props =>
      [playlistId, reason, clearExistingQueue, requestedMode];
}

/// Queue-native track request.
class CamsPlayTrack extends CamsPlaybackEvent {
  final String trackId;
  final String? playlistId;
  final String? reason;
  final bool clearExistingQueue;
  final QueueInsertModeEnum requestedMode;

  const CamsPlayTrack({
    required this.trackId,
    this.playlistId,
    this.reason,
    this.clearExistingQueue = false,
    this.requestedMode = QueueInsertModeEnum.addToQueue,
  });

  @override
  List<Object?> get props =>
      [trackId, playlistId, reason, clearExistingQueue, requestedMode];
}

/// Backward-compatible alias for old UI dispatchers.
class CamsOverridePlaylist extends CamsPlayPlaylist {
  const CamsOverridePlaylist({required super.playlistId, super.reason})
      : super(requestedMode: QueueInsertModeEnum.playNow);
}

/// Backward-compatible alias for old UI dispatchers.
class CamsPlayPlaylistTrack extends CamsPlayTrack {
  const CamsPlayPlaylistTrack({
    required super.playlistId,
    required String targetTrackId,
    super.reason,
  }) : super(
          trackId: targetTrackId,
          requestedMode: QueueInsertModeEnum.playNow,
        );
}

/// Queue management: reorder queue items by their queue item ids.
class CamsReorderQueue extends CamsPlaybackEvent {
  final List<String> queueItemIds;

  const CamsReorderQueue({
    required this.queueItemIds,
  });

  @override
  List<Object?> get props => [queueItemIds];
}

/// Queue management: remove one or more queue items.
class CamsRemoveQueueItems extends CamsPlaybackEvent {
  final List<String> queueItemIds;

  const CamsRemoveQueueItems({
    required this.queueItemIds,
  });

  @override
  List<Object?> get props => [queueItemIds];
}

/// Queue management: clear all queue items.
class CamsClearQueue extends CamsPlaybackEvent {
  const CamsClearQueue();
}

/// Patch remote audio settings (volume/mute/queue-end behavior).
class CamsUpdateAudioState extends CamsPlaybackEvent {
  final int? volumePercent;
  final bool? isMuted;
  final int? queueEndBehavior;

  const CamsUpdateAudioState({
    this.volumePercent,
    this.isMuted,
    this.queueEndBehavior,
  });

  bool get hasAnyUpdate =>
      volumePercent != null || isMuted != null || queueEndBehavior != null;

  @override
  List<Object?> get props => [volumePercent, isMuted, queueEndBehavior];
}

/// Cancel active override â€” AI scheduling resumes.
class CamsCancelOverride extends CamsPlaybackEvent {
  const CamsCancelOverride();
}

/// Send a playback command (Pause/Resume/Seek/Skip).
class CamsSendCommand extends CamsPlaybackEvent {
  final PlaybackCommandEnum command;
  final double? seekPositionSeconds;
  final String? targetTrackId;

  const CamsSendCommand({
    required this.command,
    this.seekPositionSeconds,
    this.targetTrackId,
  });

  @override
  List<Object?> get props => [command, seekPositionSeconds, targetTrackId];
}

/// Internal: SignalR PlayStream event received.
class CamsPlayStreamReceived extends CamsPlaybackEvent {
  final String spaceId;
  final String hlsUrl;
  final String? playlistId;
  final String? currentQueueItemId;
  final String? trackId;
  final String? trackName;
  final bool isManualOverride;
  final DateTime? startedAtUtc;

  const CamsPlayStreamReceived({
    required this.spaceId,
    required this.hlsUrl,
    this.playlistId,
    this.currentQueueItemId,
    this.trackId,
    this.trackName,
    this.isManualOverride = false,
    this.startedAtUtc,
  });

  @override
  List<Object?> get props => [
        spaceId,
        hlsUrl,
        playlistId,
        currentQueueItemId,
        trackId,
        trackName,
        isManualOverride,
        startedAtUtc,
      ];
}

/// Internal: SignalR PlaybackStateChanged event received.
class CamsPlaybackCommandReceived extends CamsPlaybackEvent {
  final String spaceId;
  final PlaybackCommandEnum command;
  final double? seekPositionSeconds;
  final String? targetTrackId;

  const CamsPlaybackCommandReceived({
    required this.spaceId,
    required this.command,
    this.seekPositionSeconds,
    this.targetTrackId,
  });

  @override
  List<Object?> get props =>
      [spaceId, command, seekPositionSeconds, targetTrackId];
}

/// Internal: SignalR SpaceStateSync event received.
class CamsStateSyncReceived extends CamsPlaybackEvent {
  final SpacePlaybackState playbackState;

  const CamsStateSyncReceived({
    required this.playbackState,
  });

  @override
  List<Object?> get props => [playbackState];
}

/// Internal: SignalR StopPlayback event received.
class CamsStopPlaybackReceived extends CamsPlaybackEvent {
  const CamsStopPlaybackReceived();
}

/// Refresh state from server (manual pull).
class CamsRefreshState extends CamsPlaybackEvent {
  final bool silent;

  const CamsRefreshState({this.silent = false});

  @override
  List<Object?> get props => [silent];
}

/// Report current playback telemetry from playback device to StoreHub.
/// This is best-effort for analytics/health monitoring.
class CamsReportPlaybackState extends CamsPlaybackEvent {
  final String spaceId;
  final bool isPlaying;
  final double? positionSeconds;
  final String? currentHlsUrl;

  const CamsReportPlaybackState({
    required this.spaceId,
    required this.isPlaying,
    this.positionSeconds,
    this.currentHlsUrl,
  });

  @override
  List<Object?> get props =>
      [spaceId, isPlaying, positionSeconds, currentHlsUrl];
}
