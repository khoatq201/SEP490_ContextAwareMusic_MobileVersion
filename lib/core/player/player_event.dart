import 'package:equatable/equatable.dart';
import '../../../features/space_control/domain/entities/track.dart';

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

/// Fired when the active space context changes (store / space ids).
class PlayerContextUpdated extends PlayerEvent {
  final String storeId;
  final String spaceId;

  const PlayerContextUpdated({
    required this.storeId,
    required this.spaceId,
  });

  @override
  List<Object?> get props => [storeId, spaceId];
}

/// Fired when leaving the space (no active space).
class PlayerContextCleared extends PlayerEvent {
  const PlayerContextCleared();
}
