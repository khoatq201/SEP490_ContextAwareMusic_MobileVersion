import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../../features/space_control/domain/entities/track.dart';
import '../player/player_state.dart' as app_player;
import 'audio_player_service.dart';

enum PlaybackNotificationCommandType {
  play,
  pause,
  skipNext,
  skipPrevious,
  seek,
}

class PlaybackNotificationCommand {
  const PlaybackNotificationCommand._(this.type, {this.position});

  static const play = PlaybackNotificationCommand._(
    PlaybackNotificationCommandType.play,
  );
  static const pause = PlaybackNotificationCommand._(
    PlaybackNotificationCommandType.pause,
  );
  static const skipNext = PlaybackNotificationCommand._(
    PlaybackNotificationCommandType.skipNext,
  );
  static const skipPrevious = PlaybackNotificationCommand._(
    PlaybackNotificationCommandType.skipPrevious,
  );

  static PlaybackNotificationCommand seek(Duration position) {
    return PlaybackNotificationCommand._(
      PlaybackNotificationCommandType.seek,
      position: position,
    );
  }

  final PlaybackNotificationCommandType type;
  final Duration? position;
}

class CamsAudioHandler extends BaseAudioHandler with SeekHandler {
  final StreamController<PlaybackNotificationCommand> _commandController =
      StreamController<PlaybackNotificationCommand>.broadcast();
  bool _commandsEnabled = true;

  Stream<PlaybackNotificationCommand> get commands => _commandController.stream;

  void setCommandsEnabled(bool enabled) {
    _commandsEnabled = enabled;
  }

  void _emitCommand(PlaybackNotificationCommand command) {
    if (!_commandsEnabled) return;
    _commandController.add(command);
  }

  @override
  Future<void> play() async {
    _emitCommand(PlaybackNotificationCommand.play);
  }

  @override
  Future<void> pause() async {
    _emitCommand(PlaybackNotificationCommand.pause);
  }

  @override
  Future<void> skipToNext() async {
    _emitCommand(PlaybackNotificationCommand.skipNext);
  }

  @override
  Future<void> skipToPrevious() async {
    _emitCommand(PlaybackNotificationCommand.skipPrevious);
  }

  @override
  Future<void> seek(Duration position) async {
    _emitCommand(PlaybackNotificationCommand.seek(position));
  }

  Future<void> clearSession() async {
    setCommandsEnabled(false);
    mediaItem.add(null);
    playbackState.add(PlaybackState(
      controls: [],
      systemActions: {},
      androidCompactActionIndices: [],
      processingState: AudioProcessingState.idle,
      playing: false,
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
      speed: 1.0,
    ));
  }

  @override
  Future<void> stop() => clearSession();

  Future<void> dispose() => _commandController.close();
}

class PlaybackNotificationService {
  PlaybackNotificationService._({
    required CamsAudioHandler handler,
    required AudioPlayerService audioPlayerService,
  })  : _handler = handler,
        _audioPlayerService = audioPlayerService {
    _playerStateSub = _audioPlayerService.playerStateStream.listen((_) {
      if (_isEnabled) {
        _scheduleNotificationUpdate();
      }
    });
  }

  static const String _channelId =
      'com.example.cams_store_manager.playback_controls';
  static const String _channelName = 'CAMS Playback';
  static const String _channelDescription =
      'Background controls for playback devices.';

  final CamsAudioHandler _handler;
  final AudioPlayerService _audioPlayerService;

  StreamSubscription<ja.PlayerState>? _playerStateSub;
  Timer? _notificationDebounceTimer;
  bool _notificationUpdatePending = false;
  app_player.PlayerState _latestState = const app_player.PlayerState();
  bool _isEnabled = false;
  bool _controlsEnabled = true;
  String? _lastMediaItemSignature;

  static Future<PlaybackNotificationService> init({
    required AudioPlayerService audioPlayerService,
  }) async {
    final handler = CamsAudioHandler();
    try {
      await AudioService.init(
        builder: () => handler,
        config: const AudioServiceConfig(
          androidNotificationChannelId: _channelId,
          androidNotificationChannelName: _channelName,
          androidNotificationChannelDescription: _channelDescription,
          androidNotificationOngoing: false,
          androidResumeOnClick: true,
          androidStopForegroundOnPause: false,
          preloadArtwork: false,
        ),
      );
    } catch (e) {
      // AudioService already initialized or errored, continue gracefully
      debugPrint(
        'AudioService.init already initialized or errored; continuing: $e',
      );
    }
    return PlaybackNotificationService._(
      handler: handler,
      audioPlayerService: audioPlayerService,
    );
  }

  @visibleForTesting
  PlaybackNotificationService.test({
    required CamsAudioHandler handler,
    required AudioPlayerService audioPlayerService,
  }) : this._(
          handler: handler,
          audioPlayerService: audioPlayerService,
        );

  Stream<PlaybackNotificationCommand> get commands => _handler.commands;

  void syncPlayerState(
    app_player.PlayerState playerState, {
    required bool enabled,
    bool controlsEnabled = true,
    bool forceMediaItem = false,
    bool immediate = false,
  }) {
    _latestState = playerState;
    _isEnabled = enabled && playerState.hasTrack;
    _controlsEnabled = _isEnabled && controlsEnabled;
    _handler.setCommandsEnabled(_controlsEnabled);
    if (!_isEnabled) {
      clear();
      return;
    }

    // Only update mediaItem when the track identity actually changes.
    final newMediaSignature = _mediaItemSignature(playerState);
    if (forceMediaItem || newMediaSignature != _lastMediaItemSignature) {
      _lastMediaItemSignature = newMediaSignature;
      _handler.mediaItem.add(_buildMediaItem(playerState));
    }

    if (immediate) {
      _notificationDebounceTimer?.cancel();
      _notificationUpdatePending = false;
      _publishPlaybackState();
    } else {
      _scheduleNotificationUpdate();
    }
  }

  Future<void> clear() async {
    _isEnabled = false;
    _controlsEnabled = false;
    _latestState = const app_player.PlayerState();
    _lastMediaItemSignature = null;
    _notificationDebounceTimer?.cancel();
    _notificationUpdatePending = false;
    await _handler.clearSession();
  }

  Future<void> dispose() async {
    _notificationDebounceTimer?.cancel();
    _notificationUpdatePending = false;
    await _playerStateSub?.cancel();
    await _handler.dispose();
  }

  /// Throttle notification updates to max ~2/sec.
  void _scheduleNotificationUpdate() {
    if (_notificationDebounceTimer?.isActive ?? false) {
      _notificationUpdatePending = true;
      return;
    }

    _publishPlaybackState();
    _notificationDebounceTimer = Timer(
      const Duration(milliseconds: 500),
      () {
        _notificationDebounceTimer = null;
        if (!_isEnabled || !_notificationUpdatePending) {
          _notificationUpdatePending = false;
          return;
        }

        _notificationUpdatePending = false;
        _scheduleNotificationUpdate();
      },
    );
  }

  void _publishPlaybackState() {
    _handler.playbackState.add(_buildPlaybackState(_latestState));
  }

  MediaItem _buildMediaItem(app_player.PlayerState state) {
    final track = state.currentTrack;
    final title = _resolveTitle(state, track);
    final artist = _resolveArtist(state, track);
    final artUri = _resolveArtUri(track);
    final durationSeconds = _resolveDurationSeconds(state);

    return MediaItem(
      id: track?.id ?? state.playlistId ?? state.activeSpaceId ?? 'cams-stream',
      title: title,
      artist: artist,
      album: state.playlistName ?? state.activeSpaceName,
      duration: durationSeconds > 0 ? Duration(seconds: durationSeconds) : null,
      artUri: artUri,
      extras: <String, dynamic>{
        if (state.activeSpaceName != null) 'spaceName': state.activeSpaceName,
        if (state.playlistName != null) 'playlistName': state.playlistName,
        'isHlsMode': state.isHlsMode,
      },
    );
  }

  PlaybackState _buildPlaybackState(app_player.PlayerState state) {
    if (!_controlsEnabled) {
      return PlaybackState(
        controls: const [],
        systemActions: const {},
        androidCompactActionIndices: const [],
        processingState: _mapProcessingState(
          _audioPlayerService.processingState,
          state,
        ),
        playing: state.isPlaying,
        updatePosition: _notificationPosition(state),
        bufferedPosition: _audioPlayerService.bufferedPosition,
        speed: 1.0,
        queueIndex: state.currentIndex >= 0 ? state.currentIndex : 0,
      );
    }

    final canSkipPrevious = state.hasPrevious;
    final canSkipNext = state.hasNext;
    final controls = <MediaControl>[
      if (canSkipPrevious) MediaControl.skipToPrevious,
      state.isPlaying ? MediaControl.pause : MediaControl.play,
      if (canSkipNext) MediaControl.skipToNext,
    ];
    final compactActionIndices = <int>[];
    if (canSkipPrevious) compactActionIndices.add(0);
    compactActionIndices.add(canSkipPrevious ? 1 : 0);
    if (canSkipNext && compactActionIndices.length < 3) {
      compactActionIndices.add(controls.length - 1);
    }

    return PlaybackState(
      controls: controls,
      systemActions: state.duration > 0 ? const {MediaAction.seek} : const {},
      androidCompactActionIndices: compactActionIndices,
      processingState: _mapProcessingState(
        _audioPlayerService.processingState,
        state,
      ),
      playing: state.isPlaying,
      updatePosition: _notificationPosition(state),
      bufferedPosition: _audioPlayerService.bufferedPosition,
      speed: 1.0,
      queueIndex: state.currentIndex >= 0 ? state.currentIndex : 0,
    );
  }

  AudioProcessingState _mapProcessingState(
    ja.ProcessingState engineState,
    app_player.PlayerState appState,
  ) {
    if (appState.hasTrack &&
        appState.isPlaying &&
        (engineState == ja.ProcessingState.loading ||
            engineState == ja.ProcessingState.buffering)) {
      return AudioProcessingState.ready;
    }

    switch (engineState) {
      case ja.ProcessingState.idle:
        return AudioProcessingState.idle;
      case ja.ProcessingState.loading:
        return AudioProcessingState.loading;
      case ja.ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ja.ProcessingState.ready:
        return AudioProcessingState.ready;
      case ja.ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  String _mediaItemSignature(app_player.PlayerState state) {
    final track = state.currentTrack;
    return [
      track?.id ?? state.playlistId ?? state.activeSpaceId ?? 'cams-stream',
      _resolveTitle(state, track),
      _resolveArtist(state, track),
      state.playlistName ?? state.activeSpaceName ?? '',
      _resolveDurationSeconds(state),
      _resolveArtUri(track)?.toString() ?? '',
      state.isHlsMode,
    ].join('|');
  }

  int _resolveDurationSeconds(app_player.PlayerState state) {
    final stateDuration = state.duration;
    if (stateDuration > 0) return stateDuration;

    final trackDuration = state.currentTrack?.duration;
    if (trackDuration != null && trackDuration > 0) return trackDuration;

    return 0;
  }

  Duration _notificationPosition(app_player.PlayerState state) {
    final durationSeconds = _resolveDurationSeconds(state);
    final positionSeconds = durationSeconds > 0
        ? state.displayPositionPrecise
            .clamp(0.0, durationSeconds.toDouble())
            .toDouble()
        : (state.displayPositionPrecise < 0
            ? 0.0
            : state.displayPositionPrecise);

    return Duration(milliseconds: (positionSeconds * 1000).round());
  }

  String _resolveTitle(app_player.PlayerState state, Track? track) {
    final trackTitle = track?.title.trim();
    if (trackTitle != null && trackTitle.isNotEmpty) {
      return trackTitle;
    }

    final playlistName = state.playlistName?.trim();
    if (playlistName != null && playlistName.isNotEmpty) {
      return playlistName;
    }

    return 'Streaming music';
  }

  String _resolveArtist(app_player.PlayerState state, Track? track) {
    final trackArtist = track?.artist.trim();
    if (trackArtist != null && trackArtist.isNotEmpty) {
      return trackArtist;
    }

    final spaceName = state.activeSpaceName?.trim();
    if (spaceName != null && spaceName.isNotEmpty) {
      return spaceName;
    }

    return 'CAMS';
  }

  Uri? _resolveArtUri(Track? track) {
    final albumArt = track?.albumArt?.trim();
    if (albumArt == null || albumArt.isEmpty) {
      return null;
    }

    return Uri.tryParse(albumArt);
  }
}
