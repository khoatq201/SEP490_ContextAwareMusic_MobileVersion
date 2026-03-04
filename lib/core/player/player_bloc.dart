import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;

import '../audio/audio_player_service.dart';
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
/// When a track has a non-empty [Track.fileUrl], the bloc delegates to
/// [AudioPlayerService] to actually stream audio (HLS, MP3, etc.).
///
/// Supports playlist queue with next/previous/auto-advance.
class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  /// Injected at the time the space context becomes active.
  MusicControlBloc? _activeMusicBloc;

  /// Audio engine for real playback.
  final AudioPlayerService _audioService;

  /// Subscriptions to audio-engine streams.
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<ProcessingState>? _processingStateSub;

  PlayerBloc({required AudioPlayerService audioPlayerService})
      : _audioService = audioPlayerService,
        super(const PlayerState()) {
    on<PlayerTrackChanged>(_onTrackChanged);
    on<PlayerPlayPauseToggled>(_onPlayPauseToggled);
    on<PlayerSkipRequested>(_onSkipRequested);
    on<PlayerSkipBackRequested>(_onSkipBackRequested);
    on<PlayerPlaylistStarted>(_onPlaylistStarted);
    on<PlayerTrackCompleted>(_onTrackCompleted);
    on<PlayerContextUpdated>(_onContextUpdated);
    on<PlayerContextCleared>(_onContextCleared);
    on<PlayerPositionUpdated>(_onPositionUpdated);
    on<PlayerSeekRequested>(_onSeekRequested);
    on<PlayerDurationUpdated>(_onDurationUpdated);

    _listenToAudioStreams();
  }

  // ── Audio-stream listeners ─────────────────────────────────────────────
  void _listenToAudioStreams() {
    _positionSub = _audioService.positionStream.listen((pos) {
      if (!isClosed) {
        add(PlayerPositionUpdated(positionSeconds: pos.inSeconds));
      }
    });

    _durationSub = _audioService.durationStream.listen((dur) {
      if (!isClosed && dur != null) {
        add(PlayerDurationUpdated(durationSeconds: dur.inSeconds));
      }
    });

    // Listen for track completion to auto-advance to next track.
    _processingStateSub =
        _audioService.processingStateStream.listen((procState) {
      if (!isClosed && procState == ProcessingState.completed) {
        add(const PlayerTrackCompleted());
      }
    });
  }

  // ── Load & play a track from the current queue at given index ──────────
  Future<void> _loadAndPlayTrack(int index, Emitter<PlayerState> emit) async {
    if (index < 0 || index >= state.queue.length) return;

    final track = state.queue[index];
    emit(state.copyWith(
      currentTrack: track,
      isPlaying: true,
      currentPosition: 0,
      duration: track.duration ?? 0,
      currentIndex: index,
    ));

    final url = track.fileUrl;
    if (url.isNotEmpty) {
      try {
        await _audioService.loadUrl(url);
        _audioService.play(); // fire-and-forget
      } catch (_) {
        // Silently handle audio errors in demo mode
      }
    }
  }

  // ── Playlist started (sets queue + begins playback) ────────────────────
  void _onPlaylistStarted(
      PlayerPlaylistStarted event, Emitter<PlayerState> emit) async {
    emit(state.copyWith(
      queue: event.tracks,
      currentIndex: event.startIndex,
      playlistName: event.playlistName,
    ));

    await _loadAndPlayTrack(event.startIndex, emit);
  }

  // ── Single-track changed (legacy / space-context) ─────────────────────
  void _onTrackChanged(
      PlayerTrackChanged event, Emitter<PlayerState> emit) async {
    emit(state.copyWith(
      currentTrack: event.track,
      isPlaying: event.isPlaying,
      currentPosition: event.currentPosition,
      duration: event.duration,
    ));

    // If the track has a valid stream URL, start real audio playback.
    final url = event.track?.fileUrl;
    if (url != null && url.isNotEmpty) {
      try {
        await _audioService.loadUrl(url);
        if (event.isPlaying) {
          _audioService.play(); // fire-and-forget
        }
      } catch (_) {
        // Silently handle audio errors in demo mode
      }
    }
  }

  void _onPlayPauseToggled(
      PlayerPlayPauseToggled event, Emitter<PlayerState> emit) {
    final spaceId = state.activeSpaceId;

    // Forward to backend MusicControlBloc if in space context
    if (spaceId != null && _activeMusicBloc != null) {
      if (state.isPlaying) {
        _activeMusicBloc!.add(mc.PauseMusic(spaceId));
      } else {
        _activeMusicBloc!.add(mc.PlayMusic(spaceId));
      }
    }

    // Emit UI state FIRST, then fire-and-forget the audio engine calls.
    if (state.isPlaying) {
      _audioService.pause();
    } else {
      _audioService.play();
    }

    emit(state.copyWith(isPlaying: !state.isPlaying));
  }

  // ── Skip forward ──────────────────────────────────────────────────────
  void _onSkipRequested(
      PlayerSkipRequested event, Emitter<PlayerState> emit) async {
    // If we have a queue, advance to next track
    if (state.queue.isNotEmpty && state.hasNext) {
      await _loadAndPlayTrack(state.currentIndex + 1, emit);
      return;
    }

    // Fallback: forward to backend MusicControlBloc if in space context
    final spaceId = state.activeSpaceId;
    if (spaceId != null && _activeMusicBloc != null) {
      _activeMusicBloc!.add(mc.SkipMusic(spaceId));
    }
  }

  // ── Skip back ─────────────────────────────────────────────────────────
  void _onSkipBackRequested(
      PlayerSkipBackRequested event, Emitter<PlayerState> emit) async {
    // If more than 3 seconds into the track, restart current track
    if (state.currentPosition > 3) {
      await _audioService.seek(Duration.zero);
      emit(state.copyWith(currentPosition: 0));
      return;
    }

    // Otherwise go to previous track if available
    if (state.queue.isNotEmpty && state.hasPrevious) {
      await _loadAndPlayTrack(state.currentIndex - 1, emit);
      return;
    }

    // If at the beginning of the first track, just restart
    await _audioService.seek(Duration.zero);
    emit(state.copyWith(currentPosition: 0));
  }

  // ── Auto-advance when track completes ─────────────────────────────────
  void _onTrackCompleted(
      PlayerTrackCompleted event, Emitter<PlayerState> emit) async {
    // If there's a next track in the queue, play it
    if (state.hasNext) {
      await _loadAndPlayTrack(state.currentIndex + 1, emit);
      return;
    }

    // No more tracks — mark as stopped
    emit(state.copyWith(
      isPlaying: false,
      currentPosition: 0,
    ));
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
    _audioService.stop();
    emit(const PlayerState());
    _activeMusicBloc = null;
  }

  void _onPositionUpdated(
      PlayerPositionUpdated event, Emitter<PlayerState> emit) {
    emit(state.copyWith(currentPosition: event.positionSeconds));
  }

  void _onSeekRequested(
      PlayerSeekRequested event, Emitter<PlayerState> emit) async {
    await _audioService.seek(Duration(seconds: event.positionSeconds));
    emit(state.copyWith(currentPosition: event.positionSeconds));
  }

  void _onDurationUpdated(
      PlayerDurationUpdated event, Emitter<PlayerState> emit) {
    emit(state.copyWith(duration: event.durationSeconds));
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

  @override
  Future<void> close() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _processingStateSub?.cancel();
    _audioService.dispose();
    return super.close();
  }
}
