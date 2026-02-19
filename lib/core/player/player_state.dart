import 'package:equatable/equatable.dart';
import '../../features/space_control/domain/entities/track.dart';

class PlayerState extends Equatable {
  final Track? currentTrack;
  final bool isPlaying;
  final int currentPosition; // seconds
  final int duration; // seconds

  /// The active space context (needed to dispatch commands back to MusicControlBloc).
  final String? activeStoreId;
  final String? activeSpaceId;

  const PlayerState({
    this.currentTrack,
    this.isPlaying = false,
    this.currentPosition = 0,
    this.duration = 0,
    this.activeStoreId,
    this.activeSpaceId,
  });

  /// Whether we have enough data to render the MiniPlayer.
  bool get hasTrack => currentTrack != null;

  double get progress =>
      (duration > 0) ? (currentPosition / duration).clamp(0.0, 1.0) : 0.0;

  PlayerState copyWith({
    Track? currentTrack,
    bool? isPlaying,
    int? currentPosition,
    int? duration,
    String? activeStoreId,
    String? activeSpaceId,
    bool clearTrack = false,
  }) {
    return PlayerState(
      currentTrack: clearTrack ? null : (currentTrack ?? this.currentTrack),
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      duration: duration ?? this.duration,
      activeStoreId: activeStoreId ?? this.activeStoreId,
      activeSpaceId: activeSpaceId ?? this.activeSpaceId,
    );
  }

  @override
  List<Object?> get props => [
        currentTrack,
        isPlaying,
        currentPosition,
        duration,
        activeStoreId,
        activeSpaceId,
      ];
}
