import 'package:equatable/equatable.dart';
import '../../domain/entities/music_player_state.dart';

enum MusicControlStatus { initial, loading, playing, paused, error, stopped }

class MusicControlState extends Equatable {
  final MusicControlStatus status;
  final MusicPlayerState? playerState;
  final String? errorMessage;
  final bool isOverriding;

  const MusicControlState({
    this.status = MusicControlStatus.initial,
    this.playerState,
    this.errorMessage,
    this.isOverriding = false,
  });

  MusicControlState copyWith({
    MusicControlStatus? status,
    MusicPlayerState? playerState,
    String? errorMessage,
    bool? isOverriding,
  }) {
    return MusicControlState(
      status: status ?? this.status,
      playerState: playerState ?? this.playerState,
      errorMessage: errorMessage ?? this.errorMessage,
      isOverriding: isOverriding ?? this.isOverriding,
    );
  }

  @override
  List<Object?> get props => [status, playerState, errorMessage, isOverriding];
}
