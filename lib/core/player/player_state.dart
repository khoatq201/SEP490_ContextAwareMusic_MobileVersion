import 'package:equatable/equatable.dart';
import '../../features/space_control/domain/entities/track.dart';
import 'space_info.dart';

class PlayerState extends Equatable {
  final Track? currentTrack;
  final bool isPlaying;
  final int currentPosition; // seconds
  final int duration; // seconds

  /// The active space context (needed to dispatch commands back to MusicControlBloc).
  final String? activeStoreId;
  final String? activeSpaceId;

  /// Display name of the active space (e.g. "Main Floor").
  final String? activeSpaceName;

  /// All spaces belonging to the active store — used for the space-swap sheet
  /// in the Now Playing tab.
  final List<SpaceInfo> availableSpaces;

  const PlayerState({
    this.currentTrack,
    this.isPlaying = false,
    this.currentPosition = 0,
    this.duration = 0,
    this.activeStoreId,
    this.activeSpaceId,
    this.activeSpaceName,
    this.availableSpaces = const [],
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
    String? activeSpaceName,
    List<SpaceInfo>? availableSpaces,
    bool clearTrack = false,
  }) {
    return PlayerState(
      currentTrack: clearTrack ? null : (currentTrack ?? this.currentTrack),
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      duration: duration ?? this.duration,
      activeStoreId: activeStoreId ?? this.activeStoreId,
      activeSpaceId: activeSpaceId ?? this.activeSpaceId,
      activeSpaceName: activeSpaceName ?? this.activeSpaceName,
      availableSpaces: availableSpaces ?? this.availableSpaces,
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
        activeSpaceName,
        availableSpaces,
      ];
}
