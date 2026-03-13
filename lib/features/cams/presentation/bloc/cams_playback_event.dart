import 'package:equatable/equatable.dart';
import '../../../../core/enums/playback_command_enum.dart';

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
  final String hlsUrl;
  final String playlistId;
  final bool isManualOverride;
  final DateTime? startedAtUtc;

  const CamsPlayStreamReceived({
    required this.hlsUrl,
    required this.playlistId,
    this.isManualOverride = false,
    this.startedAtUtc,
  });

  @override
  List<Object?> get props =>
      [hlsUrl, playlistId, isManualOverride, startedAtUtc];
}

/// Internal: SignalR PlaybackStateChanged event received.
class CamsPlaybackCommandReceived extends CamsPlaybackEvent {
  final PlaybackCommandEnum command;
  final double? seekPositionSeconds;
  final String? targetTrackId;

  const CamsPlaybackCommandReceived({
    required this.command,
    this.seekPositionSeconds,
    this.targetTrackId,
  });

  @override
  List<Object?> get props => [command, seekPositionSeconds, targetTrackId];
}

/// Internal: SignalR SpaceStateSync event received.
class CamsStateSyncReceived extends CamsPlaybackEvent {
  final String spaceId;
  final String? hlsUrl;
  final String? playlistId;
  final String? playlistName;
  final String? moodName;
  final bool isManualOverride;
  final double? seekOffsetSeconds;

  const CamsStateSyncReceived({
    required this.spaceId,
    this.hlsUrl,
    this.playlistId,
    this.playlistName,
    this.moodName,
    this.isManualOverride = false,
    this.seekOffsetSeconds,
  });

  @override
  List<Object?> get props => [
        spaceId,
        hlsUrl,
        playlistId,
        playlistName,
        moodName,
        isManualOverride,
        seekOffsetSeconds,
      ];
}

/// Internal: SignalR StopPlayback event received.
class CamsStopPlaybackReceived extends CamsPlaybackEvent {
  const CamsStopPlaybackReceived();
}

/// Refresh state from server (manual pull).
class CamsRefreshState extends CamsPlaybackEvent {
  const CamsRefreshState();
}
