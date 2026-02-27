import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/space_control/presentation/bloc/music_control_bloc.dart';
import '../../features/space_control/presentation/bloc/music_control_event.dart'
    as mc;
import '../../features/space_control/presentation/bloc/music_control_state.dart';
import 'player_event.dart';
import 'player_state.dart';

/// Global PlayerBloc that lives above the router.
///
/// It mirrors/aggregates the state of whichever [MusicControlBloc] is
/// currently active (i.e. the one for the selected space).  When
/// SpaceDetailPage mounts, call [PlayerContextUpdated] and feed it the
/// SpaceMonitoring stream via [PlayerTrackChanged] events.
///
/// The bloc also holds a reference to the active [MusicControlBloc] so
/// Play/Pause/Skip commands can be forwarded back to the real backend.
class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  /// Injected at the time the space context becomes active.
  MusicControlBloc? _activeMusicBloc;

  PlayerBloc() : super(const PlayerState()) {
    on<PlayerTrackChanged>(_onTrackChanged);
    on<PlayerPlayPauseToggled>(_onPlayPauseToggled);
    on<PlayerSkipRequested>(_onSkipRequested);
    on<PlayerContextUpdated>(_onContextUpdated);
    on<PlayerContextCleared>(_onContextCleared);
  }

  // -------------------------------------------------------------------------
  void _onTrackChanged(PlayerTrackChanged event, Emitter<PlayerState> emit) {
    emit(state.copyWith(
      currentTrack: event.track,
      isPlaying: event.isPlaying,
      currentPosition: event.currentPosition,
      duration: event.duration,
    ));
  }

  void _onPlayPauseToggled(
      PlayerPlayPauseToggled event, Emitter<PlayerState> emit) {
    final spaceId = state.activeSpaceId;
    if (spaceId == null || _activeMusicBloc == null) return;

    if (state.isPlaying) {
      _activeMusicBloc!.add(mc.PauseMusic(spaceId));
    } else {
      _activeMusicBloc!.add(mc.PlayMusic(spaceId));
    }
    // Optimistic UI toggle; real state will arrive via PlayerTrackChanged
    emit(state.copyWith(isPlaying: !state.isPlaying));
  }

  void _onSkipRequested(PlayerSkipRequested event, Emitter<PlayerState> emit) {
    final spaceId = state.activeSpaceId;
    if (spaceId == null || _activeMusicBloc == null) return;
    _activeMusicBloc!.add(mc.SkipMusic(spaceId));
  }

  void _onContextUpdated(
      PlayerContextUpdated event, Emitter<PlayerState> emit) {
    emit(state.copyWith(
      activeStoreId: event.storeId,
      activeSpaceId: event.spaceId,
      activeSpaceName: event.spaceName,
      availableSpaces: event.availableSpaces,
    ));
  }

  void _onContextCleared(
      PlayerContextCleared event, Emitter<PlayerState> emit) {
    emit(const PlayerState());
    _activeMusicBloc = null;
  }

  // -------------------------------------------------------------------------
  // Called from SpaceDetailPage after it creates its MusicControlBloc so
  // the global PlayerBloc can forward commands to it.
  // -------------------------------------------------------------------------
  void attachMusicBloc(MusicControlBloc bloc) {
    _activeMusicBloc = bloc;
  }

  // -------------------------------------------------------------------------
  // Convenience: feed a MusicControlState snapshot into PlayerBloc.
  // Call this inside SpaceDetailPage's BlocListener.
  // -------------------------------------------------------------------------
  void syncFromMusicState(MusicControlState musicState) {
    final track = musicState.playerState?.currentTrack;
    final isPlaying = musicState.status == MusicControlStatus.playing;
    final position = musicState.playerState?.currentPosition ?? 0;
    final duration = track?.duration ?? 0;

    add(PlayerTrackChanged(
      track: track,
      isPlaying: isPlaying,
      currentPosition: position,
      duration: duration,
    ));
  }
}
