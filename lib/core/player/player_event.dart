import 'package:equatable/equatable.dart';
import '../../../features/space_control/domain/entities/track.dart';
import 'space_info.dart';

abstract class PlayerEvent extends Equatable {
  const PlayerEvent();
  @override
  List<Object?> get props => [];
}

/// Fired by MusicControlBloc when the playing track changes.
class PlayerTrackChanged extends PlayerEvent {
  final Track? track;
  final bool isPlaying;
  final int currentPosition; // seconds
  final int duration; // seconds

  const PlayerTrackChanged({
    required this.track,
    required this.isPlaying,
    required this.currentPosition,
    required this.duration,
  });

  @override
  List<Object?> get props => [track, isPlaying, currentPosition, duration];
}

/// Fired when the user taps Play/Pause on the MiniPlayer.
class PlayerPlayPauseToggled extends PlayerEvent {
  const PlayerPlayPauseToggled();
}

/// Fired when the user skips to the next track via MiniPlayer.
class PlayerSkipRequested extends PlayerEvent {
  const PlayerSkipRequested();
}

/// Fired when the user taps the skip-back button.
class PlayerSkipBackRequested extends PlayerEvent {
  const PlayerSkipBackRequested();
}

/// Fired when starting playback from a playlist (sets the queue).
class PlayerPlaylistStarted extends PlayerEvent {
  final List<Track> tracks;
  final int startIndex;
  final String? playlistName;

  const PlayerPlaylistStarted({
    required this.tracks,
    this.startIndex = 0,
    this.playlistName,
  });

  @override
  List<Object?> get props => [tracks, startIndex, playlistName];
}

/// Internal: fired when the audio engine reports playback completed.
class PlayerTrackCompleted extends PlayerEvent {
  const PlayerTrackCompleted();
}

/// Fired when the active space context changes (store / space ids).
class PlayerContextUpdated extends PlayerEvent {
  final String storeId;
  final String spaceId;
  final String spaceName;

  /// Full list of spaces in the current store so the NowPlayingTab
  /// can offer a space-swap sheet.
  final List<SpaceInfo> availableSpaces;

  const PlayerContextUpdated({
    required this.storeId,
    required this.spaceId,
    required this.spaceName,
    this.availableSpaces = const [],
  });

  @override
  List<Object?> get props => [storeId, spaceId, spaceName, availableSpaces];
}

/// Fired when leaving the space (no active space).
class PlayerContextCleared extends PlayerEvent {
  const PlayerContextCleared();
}

/// Fired periodically by the audio engine to update playback position.
class PlayerPositionUpdated extends PlayerEvent {
  final int positionSeconds;
  const PlayerPositionUpdated({required this.positionSeconds});

  @override
  List<Object?> get props => [positionSeconds];
}

/// Fired when the user seeks to a specific position via the progress bar.
class PlayerSeekRequested extends PlayerEvent {
  final int positionSeconds;
  const PlayerSeekRequested({required this.positionSeconds});

  @override
  List<Object?> get props => [positionSeconds];
}

/// Internal: fired when the audio engine reports a new total duration.
class PlayerDurationUpdated extends PlayerEvent {
  final int durationSeconds;
  const PlayerDurationUpdated({required this.durationSeconds});

  @override
  List<Object?> get props => [durationSeconds];
}

/// Fired when CAMS provides an HLS URL for streaming.
/// The PlayerBloc should load this URL and seek to the offset.
class PlayerHlsStarted extends PlayerEvent {
  final String hlsUrl;
  final String? playlistName;
  final double seekOffsetSeconds;

  const PlayerHlsStarted({
    required this.hlsUrl,
    this.playlistName,
    this.seekOffsetSeconds = 0,
  });

  @override
  List<Object?> get props => [hlsUrl, playlistName, seekOffsetSeconds];
}

/// Fired when CAMS stops playback.
class PlayerHlsStopped extends PlayerEvent {
  const PlayerHlsStopped();
}
