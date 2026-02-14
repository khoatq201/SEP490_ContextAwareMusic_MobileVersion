import 'package:equatable/equatable.dart';
import 'track.dart';

class MusicPlayerState extends Equatable {
  final Track? currentTrack;
  final String status; // Playing, Paused, Stopped, Buffering
  final int currentPosition; // in seconds
  final bool isPlayingFromCache;

  const MusicPlayerState({
    this.currentTrack,
    required this.status,
    this.currentPosition = 0,
    this.isPlayingFromCache = false,
  });

  @override
  List<Object?> get props => [
        currentTrack,
        status,
        currentPosition,
        isPlayingFromCache,
      ];

  bool get isPlaying => status == 'Playing';
  bool get isPaused => status == 'Paused';
  bool get isStopped => status == 'Stopped';

  MusicPlayerState copyWith({
    Track? currentTrack,
    String? status,
    int? currentPosition,
    bool? isPlayingFromCache,
  }) {
    return MusicPlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      status: status ?? this.status,
      currentPosition: currentPosition ?? this.currentPosition,
      isPlayingFromCache: isPlayingFromCache ?? this.isPlayingFromCache,
    );
  }
}
