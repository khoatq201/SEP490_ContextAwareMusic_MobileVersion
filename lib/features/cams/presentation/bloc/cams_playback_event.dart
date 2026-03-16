import 'package:equatable/equatable.dart';
import '../../../../core/enums/playback_command_enum.dart';
import '../../domain/entities/space_playback_state.dart';

abstract class CamsPlaybackEvent extends Equatable {
  const CamsPlaybackEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize CAMS playback — connect SignalR, fetch state & moods.
class CamsInitPlayback extends CamsPlaybackEvent {
  final String spaceId;

  const CamsInitPlayback({required this.spaceId});

  @override
  List<Object?> get props => [spaceId];
}

/// Dispose CAMS — disconnect SignalR, leave space.
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

/// Override space with a specific playlist.
class CamsOverridePlaylist extends CamsPlaybackEvent {
  final String playlistId;
  final String? reason;

  const CamsOverridePlaylist({required this.playlistId, this.reason});

  @override
  List<Object?> get props => [playlistId, reason];
}

/// Play a specific track from a playlist.
///
/// If the playlist is not active yet, the bloc will first override to that
/// playlist and defer the track jump until the stream is ready.
class CamsPlayPlaylistTrack extends CamsPlaybackEvent {
  final String playlistId;
  final String targetTrackId;
  final String? reason;

  const CamsPlayPlaylistTrack({
    required this.playlistId,
    required this.targetTrackId,
    this.reason,
  });

  @override
  List<Object?> get props => [playlistId, targetTrackId, reason];
}

/// Cancel active override — AI scheduling resumes.
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
  final String playlistId;
  final bool isManualOverride;
  final DateTime? startedAtUtc;

  const CamsPlayStreamReceived({
    required this.spaceId,
    required this.hlsUrl,
    required this.playlistId,
    this.isManualOverride = false,
    this.startedAtUtc,
  });

  @override
  List<Object?> get props =>
      [spaceId, hlsUrl, playlistId, isManualOverride, startedAtUtc];
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
  const CamsRefreshState();
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
