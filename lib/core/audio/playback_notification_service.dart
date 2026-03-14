import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../../features/space_control/domain/entities/track.dart';
import '../player/player_state.dart' as app_player;
import 'audio_player_service.dart';

enum PlaybackNotificationCommand {
  play,
  pause,
  skipNext,
}

class CamsAudioHandler extends BaseAudioHandler with SeekHandler {
  final StreamController<PlaybackNotificationCommand> _commandController =
      StreamController<PlaybackNotificationCommand>.broadcast();

  Stream<PlaybackNotificationCommand> get commands => _commandController.stream;

  @override
  Future<void> play() async {
    _commandController.add(PlaybackNotificationCommand.play);
  }

  @override
  Future<void> pause() async {
    _commandController.add(PlaybackNotificationCommand.pause);
  }

  @override
  Future<void> skipToNext() async {
    _commandController.add(PlaybackNotificationCommand.skipNext);
  }

  Future<void> clearSession() async {
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
        _publishPlaybackState();
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
  app_player.PlayerState _latestState = const app_player.PlayerState();
  bool _isEnabled = false;

  static Future<PlaybackNotificationService> init({
    required AudioPlayerService audioPlayerService,
  }) async {
    final handler = CamsAudioHandler();
    await AudioService.init(
      builder: () => handler,
      config: const AudioServiceConfig(
        androidNotificationChannelId: _channelId,
        androidNotificationChannelName: _channelName,
        androidNotificationChannelDescription: _channelDescription,
        androidNotificationOngoing: true,
        androidResumeOnClick: true,
        preloadArtwork: false,
      ),
    );
    return PlaybackNotificationService._(
      handler: handler,
      audioPlayerService: audioPlayerService,
    );
  }

  Stream<PlaybackNotificationCommand> get commands => _handler.commands;

  void syncPlayerState(
    app_player.PlayerState playerState, {
    required bool enabled,
  }) {
    _latestState = playerState;
    _isEnabled = enabled && playerState.hasTrack;
    if (!_isEnabled) {
      clear();
      return;
    }

    _handler.mediaItem.add(_buildMediaItem(playerState));
    _publishPlaybackState();
  }

  Future<void> clear() async {
    _isEnabled = false;
    _latestState = const app_player.PlayerState();
    await _handler.clearSession();
  }

  Future<void> dispose() async {
    await _playerStateSub?.cancel();
    await _handler.dispose();
  }

  void _publishPlaybackState() {
    _handler.playbackState.add(_buildPlaybackState(_latestState));
  }

  MediaItem _buildMediaItem(app_player.PlayerState state) {
    final track = state.currentTrack;
    final title = _resolveTitle(state, track);
    final artist = _resolveArtist(state, track);
    final artUri = _resolveArtUri(track);
    final durationSeconds =
        state.duration > 0 ? state.duration : track?.duration ?? 0;

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
    final canSkipNext = state.isHlsMode || state.hasNext;
    final controls = <MediaControl>[
      state.isPlaying ? MediaControl.pause : MediaControl.play,
      if (canSkipNext) MediaControl.skipToNext,
    ];

    return PlaybackState(
      controls: controls,
      systemActions: const {},
      androidCompactActionIndices: <int>[
        0,
        if (canSkipNext) 1,
      ],
      processingState: _mapProcessingState(_audioPlayerService.processingState),
      playing: state.isPlaying,
      updatePosition: Duration(seconds: state.currentPosition),
      bufferedPosition: _audioPlayerService.bufferedPosition,
      speed: 1.0,
      queueIndex: state.currentIndex >= 0 ? state.currentIndex : 0,
    );
  }

  AudioProcessingState _mapProcessingState(ja.ProcessingState state) {
    switch (state) {
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
