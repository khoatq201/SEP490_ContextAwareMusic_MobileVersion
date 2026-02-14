import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/control_music.dart';
import '../../domain/usecases/override_mood.dart';
import '../../domain/usecases/subscribe_music_player_state.dart';
import 'music_control_event.dart';
import 'music_control_state.dart';

class MusicControlBloc extends Bloc<MusicControlEvent, MusicControlState> {
  final ControlMusic controlMusic;
  final OverrideMood overrideMood;
  final SubscribeMusicPlayerState subscribeMusicPlayerState;

  StreamSubscription? _musicPlayerStateSubscription;

  MusicControlBloc({
    required this.controlMusic,
    required this.overrideMood,
    required this.subscribeMusicPlayerState,
  }) : super(const MusicControlState()) {
    on<StartMusicMonitoring>(_onStartMusicMonitoring);
    on<StopMusicMonitoring>(_onStopMusicMonitoring);
    on<PlayMusic>(_onPlayMusic);
    on<PauseMusic>(_onPauseMusic);
    on<SkipMusic>(_onSkipMusic);
    on<OverrideMoodRequested>(_onOverrideMoodRequested);
    on<MusicPlayerStateUpdated>(_onMusicPlayerStateUpdated);
  }

  void _onStartMusicMonitoring(
    StartMusicMonitoring event,
    Emitter<MusicControlState> emit,
  ) {
    emit(state.copyWith(status: MusicControlStatus.loading));

    // Subscribe to music player state updates
    _musicPlayerStateSubscription = subscribeMusicPlayerState(
      event.storeId,
      event.spaceId,
    ).listen(
      (playerState) => add(MusicPlayerStateUpdated(playerState)),
      onError: (error) {
        emit(state.copyWith(
          status: MusicControlStatus.error,
          errorMessage: 'Failed to receive music player updates: $error',
        ));
      },
    );
  }

  void _onStopMusicMonitoring(
    StopMusicMonitoring event,
    Emitter<MusicControlState> emit,
  ) {
    _musicPlayerStateSubscription?.cancel();
    emit(state.copyWith(status: MusicControlStatus.stopped));
  }

  Future<void> _onPlayMusic(
    PlayMusic event,
    Emitter<MusicControlState> emit,
  ) async {
    final result = await controlMusic.play(event.spaceId);

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: MusicControlStatus.error,
          errorMessage: failure.message,
        ));
      },
      (_) {
        // State will be updated via MQTT subscription
      },
    );
  }

  Future<void> _onPauseMusic(
    PauseMusic event,
    Emitter<MusicControlState> emit,
  ) async {
    final result = await controlMusic.pause(event.spaceId);

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: MusicControlStatus.error,
          errorMessage: failure.message,
        ));
      },
      (_) {
        // State will be updated via MQTT subscription
      },
    );
  }

  Future<void> _onSkipMusic(
    SkipMusic event,
    Emitter<MusicControlState> emit,
  ) async {
    final result = await controlMusic.skip(event.spaceId);

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: MusicControlStatus.error,
          errorMessage: failure.message,
        ));
      },
      (_) {
        // State will be updated via MQTT subscription
      },
    );
  }

  Future<void> _onOverrideMoodRequested(
    OverrideMoodRequested event,
    Emitter<MusicControlState> emit,
  ) async {
    emit(state.copyWith(isOverriding: true));

    final result = await overrideMood(
      spaceId: event.spaceId,
      moodId: event.moodId,
      duration: event.duration,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: MusicControlStatus.error,
          errorMessage: failure.message,
          isOverriding: false,
        ));
      },
      (_) {
        emit(state.copyWith(isOverriding: false));
      },
    );
  }

  void _onMusicPlayerStateUpdated(
    MusicPlayerStateUpdated event,
    Emitter<MusicControlState> emit,
  ) {
    MusicControlStatus newStatus;

    if (event.playerState.isPlaying) {
      newStatus = MusicControlStatus.playing;
    } else if (event.playerState.isPaused) {
      newStatus = MusicControlStatus.paused;
    } else {
      newStatus = MusicControlStatus.stopped;
    }

    emit(state.copyWith(
      status: newStatus,
      playerState: event.playerState,
    ));
  }

  @override
  Future<void> close() {
    _musicPlayerStateSubscription?.cancel();
    return super.close();
  }
}
