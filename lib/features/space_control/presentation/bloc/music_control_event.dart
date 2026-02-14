import 'package:equatable/equatable.dart';
import '../../domain/entities/music_player_state.dart';

abstract class MusicControlEvent extends Equatable {
  const MusicControlEvent();

  @override
  List<Object?> get props => [];
}

class StartMusicMonitoring extends MusicControlEvent {
  final String storeId;
  final String spaceId;

  const StartMusicMonitoring({
    required this.storeId,
    required this.spaceId,
  });

  @override
  List<Object?> get props => [storeId, spaceId];
}

class StopMusicMonitoring extends MusicControlEvent {
  const StopMusicMonitoring();
}

class PlayMusic extends MusicControlEvent {
  final String spaceId;

  const PlayMusic(this.spaceId);

  @override
  List<Object?> get props => [spaceId];
}

class PauseMusic extends MusicControlEvent {
  final String spaceId;

  const PauseMusic(this.spaceId);

  @override
  List<Object?> get props => [spaceId];
}

class SkipMusic extends MusicControlEvent {
  final String spaceId;

  const SkipMusic(this.spaceId);

  @override
  List<Object?> get props => [spaceId];
}

class OverrideMoodRequested extends MusicControlEvent {
  final String spaceId;
  final String moodId;
  final int duration;

  const OverrideMoodRequested({
    required this.spaceId,
    required this.moodId,
    required this.duration,
  });

  @override
  List<Object?> get props => [spaceId, moodId, duration];
}

class MusicPlayerStateUpdated extends MusicControlEvent {
  final MusicPlayerState playerState;

  const MusicPlayerStateUpdated(this.playerState);

  @override
  List<Object?> get props => [playerState];
}
