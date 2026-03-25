import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;

import '../audio/audio_player_service.dart';
import '../enums/playback_command_enum.dart';
import '../../features/space_control/domain/entities/track.dart';
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
    on<PlayerQueueSeeded>(_onQueueSeeded);
    on<PlayerTrackCompleted>(_onTrackCompleted);
    on<PlayerContextUpdated>(_onContextUpdated);
    on<PlayerContextCleared>(_onContextCleared);
    on<PlayerPositionUpdated>(_onPositionUpdated);
    on<PlayerSeekRequested>(_onSeekRequested);
    on<PlayerDurationUpdated>(_onDurationUpdated);
    on<PlayerHlsStarted>(_onHlsStarted);
    on<PlayerHlsStopped>(_onHlsStopped);
    on<PlayerRemoteCommandApplied>(_onRemoteCommandApplied);
    on<PlayerAudioSettingsApplied>(_onAudioSettingsApplied);

    _listenToAudioStreams();
  }

  // ── Audio-stream listeners ─────────────────────────────────────────────
  void _listenToAudioStreams() {
    _positionSub = _audioService.positionStream.listen((pos) {
      if (!isClosed) {
        add(
          PlayerPositionUpdated(
            positionSeconds: pos.inMilliseconds / 1000.0,
          ),
        );
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
  Future<void> _loadAndPlayTrack(
    int index,
    Emitter<PlayerState> emit, {
    bool playLocally = true,
  }) async {
    if (index < 0 || index >= state.queue.length) return;

    final track = state.queue[index];
    emit(state.copyWith(
      currentTrack: track,
      currentTrackId: track.id,
      isPlaying: true,
      currentPosition: 0,
      currentPositionPrecise: 0,
      duration: track.duration ?? 0,
      currentIndex: index,
      isHlsMode: false,
      clearHlsUrl: true,
      clearCurrentQueueItemId: true,
    ));

    if (!playLocally) return;

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
      playlistId: event.playlistId,
      isHlsMode: false,
      clearHlsUrl: true,
    ));

    await _loadAndPlayTrack(
      event.startIndex,
      emit,
      playLocally: event.playLocally,
    );
  }

  void _onQueueSeeded(PlayerQueueSeeded event, Emitter<PlayerState> emit) {
    if (!event.force &&
        state.isPlaying &&
        !state.isSyncedCamsPlayback &&
        state.playlistId != null &&
        state.playlistId != event.playlistId) {
      return;
    }

    var nextState = state.copyWith(
      queue: event.tracks,
      playlistName: event.playlistName,
      playlistId: event.playlistId,
    );

    if (nextState.isHlsMode && event.tracks.isNotEmpty) {
      var resolvedIndex =
          _findIndexForQueueItemId(nextState.currentQueueItemId, event.tracks);
      if (resolvedIndex < 0) {
        resolvedIndex = event.tracks.indexWhere(
          (track) => track.id == nextState.currentTrackId,
        );
      }
      if (resolvedIndex < 0) {
        resolvedIndex = _resolveIndexForOffset(
          nextState.currentPosition.toDouble(),
          event.tracks,
        );
      }
      if (resolvedIndex >= 0 && resolvedIndex < event.tracks.length) {
        final resolvedTrack = event.tracks[resolvedIndex];
        nextState = nextState.copyWith(
          currentIndex: resolvedIndex,
          currentTrack: resolvedTrack,
          currentTrackId: resolvedTrack.id,
          duration: resolvedTrack.duration ?? nextState.duration,
        );
      }
    }

    emit(nextState);
  }

  // ── Single-track changed (legacy / space-context) ─────────────────────
  void _onTrackChanged(
      PlayerTrackChanged event, Emitter<PlayerState> emit) async {
    if (state.isSyncedCamsPlayback) {
      // Ignore legacy MusicControl sync while a CAMS/HLS stream is active.
      return;
    }

    emit(state.copyWith(
      currentTrack: event.track,
      currentTrackId: event.track?.id,
      isPlaying: event.isPlaying,
      currentPosition: event.currentPosition,
      currentPositionPrecise: event.currentPosition.toDouble(),
      duration: event.duration,
      clearCurrentQueueItemId: true,
    ));

    if (!event.playLocally) return;

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
    if (state.isHlsMode && (state.hlsUrl?.isNotEmpty ?? false)) {
      // CAMS controls drive the remote HLS stream. Wait for SignalR/state sync
      // instead of mutating the queue into a fake local preview state.
      return;
    }

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
    if (state.isHlsMode && (state.hlsUrl?.isNotEmpty ?? false)) {
      // Remote HLS playback should be reconciled from CAMS events only.
      return;
    }

    // If more than 3 seconds into the track, restart current track
    if (state.currentPosition > 3) {
      await _audioService.seek(Duration.zero);
      emit(state.copyWith(currentPosition: 0, currentPositionPrecise: 0));
      return;
    }

    // Otherwise go to previous track if available
    if (state.queue.isNotEmpty && state.hasPrevious) {
      await _loadAndPlayTrack(state.currentIndex - 1, emit);
      return;
    }

    // If at the beginning of the first track, just restart
    await _audioService.seek(Duration.zero);
    emit(state.copyWith(currentPosition: 0, currentPositionPrecise: 0));
  }

  // ── Auto-advance when track completes ─────────────────────────────────
  void _onTrackCompleted(
      PlayerTrackCompleted event, Emitter<PlayerState> emit) async {
    if (state.isHlsMode && (state.hlsUrl?.isNotEmpty ?? false)) {
      emit(state.copyWith(
        isPlaying: false,
        hlsCompletionSequence: state.hlsCompletionSequence + 1,
      ));
      return;
    }

    // If there's a next track in the queue, play it
    if (state.hasNext) {
      await _loadAndPlayTrack(state.currentIndex + 1, emit);
      return;
    }

    // No more tracks — mark as stopped
    emit(state.copyWith(
      isPlaying: false,
      currentPosition: 0,
      currentPositionPrecise: 0,
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
    if (state.isHlsMode &&
        state.queue.isNotEmpty &&
        _queueTotalDuration() > 0) {
      final resolvedIndex = _resolveIndexForOffset(event.positionSeconds);
      if (resolvedIndex >= 0 && resolvedIndex < state.queue.length) {
        final resolvedTrack = state.queue[resolvedIndex];
        emit(state.copyWith(
          currentPosition: event.positionSeconds.floor(),
          currentPositionPrecise: event.positionSeconds,
          currentIndex: resolvedIndex,
          currentTrack: resolvedTrack,
          duration: resolvedTrack.duration ?? state.duration,
        ));
        return;
      }
    }

    emit(state.copyWith(
      currentPosition: event.positionSeconds.floor(),
      currentPositionPrecise: event.positionSeconds,
    ));
  }

  void _onSeekRequested(
      PlayerSeekRequested event, Emitter<PlayerState> emit) async {
    try {
      await _audioService.seek(Duration(seconds: event.positionSeconds));
    } catch (_) {
      // Manager devices can optimistically update UI before SignalR confirms
      // the new position even though they do not hold a local audio source.
    }
    emit(state.copyWith(
      currentPosition: event.positionSeconds,
      currentPositionPrecise: event.positionSeconds.toDouble(),
    ));
  }

  void _onDurationUpdated(
      PlayerDurationUpdated event, Emitter<PlayerState> emit) {
    emit(state.copyWith(duration: event.durationSeconds));
  }

  int _findIndexForTrackId(String? trackId) {
    if (trackId == null || trackId.isEmpty) return -1;
    return state.queue.indexWhere((track) => track.id == trackId);
  }

  int _findIndexForQueueItemId(
    String? queueItemId, [
    List<Track>? queueOverride,
  ]) {
    if (queueItemId == null || queueItemId.isEmpty) return -1;
    final queue = queueOverride ?? state.queue;
    return queue.indexWhere((track) => track.queueItemId == queueItemId);
  }

  int _trackStartOffsetAt(int index, [List<Track>? queueOverride]) {
    final queue = queueOverride ?? state.queue;
    if (index < 0 || index >= queue.length) return 0;

    final explicitOffset = queue[index].seekOffsetSeconds;
    if (explicitOffset != null) return explicitOffset;

    var cumulativeOffset = 0;
    for (var offsetIndex = 0; offsetIndex < index; offsetIndex++) {
      cumulativeOffset += queue[offsetIndex].duration ?? 0;
    }
    return cumulativeOffset;
  }

  int _queueTotalDuration([List<Track>? queueOverride]) {
    final queue = queueOverride ?? state.queue;
    if (queue.isEmpty) return 0;

    final lastIndex = queue.length - 1;
    return _trackStartOffsetAt(lastIndex, queue) +
        (queue[lastIndex].duration ?? 0);
  }

  double _normalizeOffsetForQueue(
    double offsetSeconds, [
    List<Track>? queueOverride,
  ]) {
    final totalDuration = _queueTotalDuration(queueOverride);
    if (totalDuration <= 0) return offsetSeconds;

    final normalized = offsetSeconds % totalDuration;
    return normalized < 0 ? normalized + totalDuration : normalized;
  }

  int _resolveIndexForOffset(
    double offsetSeconds, [
    List<Track>? queueOverride,
  ]) {
    final queue = queueOverride ?? state.queue;
    if (queue.isEmpty) return -1;

    final normalizedOffset =
        _normalizeOffsetForQueue(offsetSeconds, queueOverride);

    for (var i = 0; i < queue.length; i++) {
      final nextTrackStart = i < queue.length - 1
          ? _trackStartOffsetAt(i + 1, queue).toDouble()
          : null;
      if (nextTrackStart == null || normalizedOffset < nextTrackStart) {
        return i;
      }
    }
    return queue.length - 1;
  }

  Track _buildSyntheticStreamTrack({
    String? playlistName,
    String? trackId,
    String? trackName,
    String? queueItemId,
  }) {
    return Track(
      id: trackId ?? queueItemId ?? state.activeSpaceId ?? 'cams-stream',
      queueItemId: queueItemId,
      title: trackName ?? playlistName ?? 'Streaming music',
      artist: state.activeSpaceName ?? 'CAMS',
      fileUrl: '',
      moodTags: const [],
      duration: state.duration > 0 ? state.duration : null,
    );
  }

  // ── HLS streaming from CAMS ────────────────────────────────────────────
  void _onHlsStarted(PlayerHlsStarted event, Emitter<PlayerState> emit) async {
    final hasSeededQueue = state.queue.isNotEmpty;

    var resolvedIndex = _findIndexForQueueItemId(event.queueItemId);
    if (resolvedIndex < 0) {
      resolvedIndex =
          event.trackId != null ? _findIndexForTrackId(event.trackId) : -1;
    }
    if (resolvedIndex < 0 && hasSeededQueue) {
      resolvedIndex = _resolveIndexForOffset(event.seekOffsetSeconds);
    }

    final resolvedTrack = resolvedIndex >= 0
        ? state.queue[resolvedIndex]
        : (state.currentTrack ??
            _buildSyntheticStreamTrack(
              playlistName: event.playlistName,
              trackId: event.trackId,
              trackName: event.trackName,
              queueItemId: event.queueItemId,
            ));

    emit(state.copyWith(
      isHlsMode: true,
      hlsUrl: event.hlsUrl,
      playlistName: event.playlistName,
      playlistId: event.playlistId,
      currentQueueItemId: event.queueItemId ?? resolvedTrack.queueItemId,
      currentTrackId: event.trackId ?? resolvedTrack.id,
      isPlaying: !event.isPaused,
      currentPosition: event.seekOffsetSeconds.floor(),
      currentPositionPrecise: event.seekOffsetSeconds,
      currentTrack: resolvedTrack,
      currentIndex: resolvedIndex >= 0 ? resolvedIndex : state.currentIndex,
      duration: resolvedTrack.duration ?? state.duration,
      clearPlaylistName:
          event.playlistName == null || event.playlistName!.isEmpty,
      clearPlaylistId: event.playlistId == null || event.playlistId!.isEmpty,
    ));

    if (!event.playLocally) return;

    try {
      final shouldReloadSource = event.forceReload ||
          _audioService.loadedUrl != event.hlsUrl ||
          !state.isHlsMode ||
          state.hlsUrl != event.hlsUrl;

      if (shouldReloadSource) {
        await _audioService.loadUrl(event.hlsUrl);
      }

      if (event.seekOffsetSeconds > 0) {
        final targetPosition = Duration(
          milliseconds: (event.seekOffsetSeconds * 1000).round(),
        );
        final currentPosition = _audioService.position;
        final positionDrift =
            (currentPosition - targetPosition).inMilliseconds.abs() / 1000.0;
        if (shouldReloadSource || positionDrift > 2) {
          await _audioService.seek(targetPosition);
        }
      }
      if (event.isPaused) {
        await _audioService.pause();
      } else {
        await _audioService.play();
      }
    } catch (_) {
      // Silently handle audio errors
    }
  }

  void _onHlsStopped(PlayerHlsStopped event, Emitter<PlayerState> emit) async {
    _audioService.stop();
    emit(state.copyWith(
      isPlaying: false,
      isHlsMode: false,
      clearHlsUrl: true,
      clearTrack: true,
      clearPlaylistName: true,
      clearPlaylistId: true,
      clearCurrentQueueItemId: true,
      clearCurrentTrackId: true,
      queue: const [],
      currentIndex: -1,
      currentPosition: 0,
      duration: 0,
    ));
  }

  void _onRemoteCommandApplied(
    PlayerRemoteCommandApplied event,
    Emitter<PlayerState> emit,
  ) async {
    final absolutePosition = event.positionSeconds;
    var resolvedIndex = _findIndexForTrackId(event.targetTrackId);
    if (resolvedIndex < 0 && absolutePosition != null) {
      resolvedIndex = _resolveIndexForOffset(absolutePosition);
    }
    final resolvedTrack =
        resolvedIndex >= 0 && resolvedIndex < state.queue.length
            ? state.queue[resolvedIndex]
            : state.currentTrack;

    final isSeekCommand = event.command == PlaybackCommandEnum.seek ||
        event.command == PlaybackCommandEnum.seekForward ||
        event.command == PlaybackCommandEnum.seekBackward;
    final hasUsefulSeek =
        absolutePosition != null && (isSeekCommand || absolutePosition > 0);
    final fallbackTrackOffset =
        resolvedIndex >= 0 ? _trackStartOffsetAt(resolvedIndex) : null;

    switch (event.command) {
      case PlaybackCommandEnum.pause:
        if (event.playLocally) {
          _audioService.pause();
        }
        emit(state.copyWith(isPlaying: false));
        return;
      case PlaybackCommandEnum.resume:
        if (event.playLocally) {
          _audioService.play();
        }
        emit(state.copyWith(isPlaying: true));
        return;
      case PlaybackCommandEnum.seek:
      case PlaybackCommandEnum.seekForward:
      case PlaybackCommandEnum.seekBackward:
      case PlaybackCommandEnum.skipNext:
      case PlaybackCommandEnum.skipPrevious:
      case PlaybackCommandEnum.skipToTrack:
      case PlaybackCommandEnum.trackEnded:
        if (hasUsefulSeek &&
            event.playLocally &&
            state.isHlsMode &&
            state.hlsUrl != null &&
            state.hlsUrl!.isNotEmpty) {
          try {
            await _audioService.seek(
              Duration(milliseconds: (absolutePosition * 1000).round()),
            );
          } catch (_) {
            // Ignore seeks that arrive before the HLS source is fully loaded.
          }
        }

        final nextIsPlaying = event.command == PlaybackCommandEnum.trackEnded
            ? state.isPlaying
            : isSeekCommand
                ? state.isPlaying
                : true;

        emit(state.copyWith(
          currentPosition: (absolutePosition ??
                  fallbackTrackOffset?.toDouble() ??
                  state.currentPositionPrecise)
              .floor(),
          currentPositionPrecise: absolutePosition ??
              fallbackTrackOffset?.toDouble() ??
              state.currentPositionPrecise,
          currentIndex: resolvedIndex >= 0 ? resolvedIndex : state.currentIndex,
          currentTrack: resolvedTrack,
          currentTrackId: event.targetTrackId ?? resolvedTrack?.id,
          duration: resolvedTrack?.duration ?? state.duration,
          isPlaying: nextIsPlaying,
        ));
        return;
    }
  }

  void _onAudioSettingsApplied(
    PlayerAudioSettingsApplied event,
    Emitter<PlayerState> emit,
  ) {
    final boundedVolume = event.volumePercent.clamp(0, 100) / 100.0;
    final effectiveVolume = event.isMuted ? 0.0 : boundedVolume;
    unawaited(_audioService.setVolume(effectiveVolume));
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
    if (state.isSyncedCamsPlayback) {
      return;
    }

    final track = musicState.playerState?.currentTrack;
    final isPlaying = musicState.status == MusicControlStatus.playing;
    final position = musicState.playerState?.currentPosition ?? 0;
    final duration = track?.duration ?? 0;

    add(PlayerTrackChanged(
      track: track,
      isPlaying: isPlaying,
      currentPosition: position,
      duration: duration,
      playLocally: true,
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
