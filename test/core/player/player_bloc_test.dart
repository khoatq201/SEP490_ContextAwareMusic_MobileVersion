import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

import 'package:cams_store_manager/core/audio/audio_player_service.dart';
import 'package:cams_store_manager/core/enums/playback_command_enum.dart';
import 'package:cams_store_manager/core/player/player_bloc.dart';
import 'package:cams_store_manager/core/player/player_event.dart';
import 'package:cams_store_manager/features/space_control/domain/entities/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerBloc queue-first streaming behavior', () {
    late _FakeAudioPlayerService audioService;
    late PlayerBloc bloc;

    setUp(() {
      audioService = _FakeAudioPlayerService();
      bloc = PlayerBloc(audioPlayerService: audioService);
    });

    tearDown(() async {
      await bloc.close();
    });

    test('does not auto-advance local queue on HLS completion', () async {
      final queue = [
        const Track(
          id: 'track-1',
          queueItemId: 'queue-1',
          title: 'Track 1',
          artist: 'Artist',
          fileUrl: '',
          moodTags: [],
          duration: 180,
          seekOffsetSeconds: 0,
        ),
        const Track(
          id: 'track-2',
          queueItemId: 'queue-2',
          title: 'Track 2',
          artist: 'Artist',
          fileUrl: '',
          moodTags: [],
          duration: 220,
          seekOffsetSeconds: 180,
        ),
      ];

      bloc.add(PlayerQueueSeeded(
        tracks: queue,
        playlistId: 'playlist-1',
        force: true,
      ));
      await _tick();

      bloc.add(const PlayerHlsStarted(
        hlsUrl: 'https://stream.example.com/live.m3u8',
        playlistId: 'playlist-1',
        queueItemId: 'queue-1',
        trackId: 'track-1',
        trackName: 'Track 1',
        playLocally: false,
      ));
      await _tick();

      expect(bloc.state.currentIndex, 0);
      expect(bloc.state.currentTrackId, 'track-1');
      expect(bloc.state.isPlaying, isTrue);

      bloc.add(const PlayerTrackCompleted());
      await _tick();

      expect(bloc.state.hlsCompletionSequence, 1);
      expect(bloc.state.currentIndex, 0);
      expect(bloc.state.currentTrackId, 'track-1');
      expect(bloc.state.isPlaying, isFalse);
    });

    test('maps skipToTrack without offset by targetTrackId', () async {
      final queue = [
        const Track(
          id: 'track-1',
          queueItemId: 'queue-1',
          title: 'Track 1',
          artist: 'Artist',
          fileUrl: '',
          moodTags: [],
          duration: 180,
          seekOffsetSeconds: 0,
        ),
        const Track(
          id: 'track-2',
          queueItemId: 'queue-2',
          title: 'Track 2',
          artist: 'Artist',
          fileUrl: '',
          moodTags: [],
          duration: 220,
          seekOffsetSeconds: 180,
        ),
      ];

      bloc.add(PlayerQueueSeeded(
        tracks: queue,
        playlistId: 'playlist-1',
        force: true,
      ));
      await _tick();

      bloc.add(const PlayerHlsStarted(
        hlsUrl: 'https://stream.example.com/live.m3u8',
        playlistId: 'playlist-1',
        queueItemId: 'queue-1',
        trackId: 'track-1',
        trackName: 'Track 1',
        seekOffsetSeconds: 60,
        playLocally: false,
      ));
      await _tick();

      bloc.add(const PlayerRemoteCommandApplied(
        command: PlaybackCommandEnum.skipToTrack,
        targetTrackId: 'track-2',
        playLocally: true,
      ));
      await _tick();

      expect(bloc.state.currentTrackId, 'track-2');
      expect(bloc.state.currentIndex, 1);
      expect(bloc.state.currentTrack?.id, 'track-2');
      expect(bloc.state.currentPosition, 180);
      expect(audioService.seekCalls, isEmpty);
    });

    test('ignores targetTrackId on seek to prevent wrong title jumps', () async {
      final queue = [
        const Track(
          id: 'track-1',
          queueItemId: 'queue-1',
          title: 'Track 1',
          artist: 'Artist',
          fileUrl: '',
          moodTags: [],
          duration: 180,
          seekOffsetSeconds: 0,
        ),
        const Track(
          id: 'track-2',
          queueItemId: 'queue-2',
          title: 'Track 2',
          artist: 'Artist',
          fileUrl: '',
          moodTags: [],
          duration: 220,
          seekOffsetSeconds: 180,
        ),
      ];

      bloc.add(PlayerQueueSeeded(
        tracks: queue,
        playlistId: 'playlist-1',
        force: true,
      ));
      await _tick();

      bloc.add(const PlayerHlsStarted(
        hlsUrl: 'https://stream.example.com/live.m3u8',
        playlistId: 'playlist-1',
        queueItemId: 'queue-1',
        trackId: 'track-1',
        trackName: 'Track 1',
        seekOffsetSeconds: 60,
        playLocally: false,
      ));
      await _tick();

      bloc.add(const PlayerRemoteCommandApplied(
        command: PlaybackCommandEnum.seek,
        positionSeconds: 70,
        targetTrackId: 'track-2',
        playLocally: false,
      ));
      await _tick();

      expect(bloc.state.currentTrackId, 'track-1');
      expect(bloc.state.currentIndex, 0);
      expect(bloc.state.currentTrack?.id, 'track-1');
      expect(bloc.state.currentPosition, 70);
    });

    test('does not remap track by offset when queue timeline metadata is absent',
        () async {
      final queue = [
        const Track(
          id: 'track-1',
          queueItemId: 'queue-1',
          title: 'Track 1',
          artist: 'Artist',
          fileUrl: '',
          moodTags: [],
          duration: null,
          seekOffsetSeconds: null,
        ),
        const Track(
          id: 'track-2',
          queueItemId: 'queue-2',
          title: 'Track 2',
          artist: 'Artist',
          fileUrl: '',
          moodTags: [],
          duration: null,
          seekOffsetSeconds: null,
        ),
      ];

      bloc.add(PlayerQueueSeeded(
        tracks: queue,
        playlistId: 'playlist-1',
        force: true,
      ));
      await _tick();

      bloc.add(const PlayerHlsStarted(
        hlsUrl: 'https://stream.example.com/live.m3u8',
        playlistId: 'playlist-1',
        queueItemId: 'queue-1',
        trackId: 'track-1',
        trackName: 'Track 1',
        seekOffsetSeconds: 10,
        playLocally: false,
      ));
      await _tick();

      bloc.add(const PlayerRemoteCommandApplied(
        command: PlaybackCommandEnum.seek,
        positionSeconds: 90,
        playLocally: false,
      ));
      await _tick();

      expect(bloc.state.currentTrackId, 'track-1');
      expect(bloc.state.currentIndex, 0);
      expect(bloc.state.currentTrack?.id, 'track-1');
      expect(bloc.state.currentPosition, 90);
    });

    test('resolves current track from queueItemId without playlistId',
        () async {
      final queue = [
        const Track(
          id: 'track-1',
          queueItemId: 'queue-1',
          title: 'Track 1',
          artist: 'Artist',
          fileUrl: '',
          moodTags: [],
          duration: 180,
          seekOffsetSeconds: 0,
        ),
        const Track(
          id: 'track-2',
          queueItemId: 'queue-2',
          title: 'Track 2',
          artist: 'Artist',
          fileUrl: '',
          moodTags: [],
          duration: 220,
          seekOffsetSeconds: 180,
        ),
      ];

      bloc.add(PlayerQueueSeeded(
        tracks: queue,
        force: true,
      ));
      await _tick();

      bloc.add(const PlayerHlsStarted(
        hlsUrl: 'https://stream.example.com/live.m3u8',
        queueItemId: 'queue-2',
        trackName: 'Track 2',
        seekOffsetSeconds: 181,
        playLocally: false,
      ));
      await _tick();

      expect(bloc.state.currentIndex, 1);
      expect(bloc.state.currentTrackId, 'track-2');
      expect(bloc.state.currentTrack?.id, 'track-2');
      expect(bloc.state.currentQueueItemId, 'queue-2');
    });

    test('clears stale playlist metadata on queue-first HLS start', () async {
      final queue = [
        const Track(
          id: 'track-1',
          queueItemId: 'queue-1',
          title: 'Track 1',
          artist: 'Artist',
          fileUrl: '',
          moodTags: [],
          duration: 180,
          seekOffsetSeconds: 0,
        ),
      ];

      bloc.add(PlayerQueueSeeded(
        tracks: queue,
        playlistId: 'playlist-legacy',
        playlistName: 'Legacy Playlist',
        force: true,
      ));
      await _tick();

      expect(bloc.state.playlistId, 'playlist-legacy');
      expect(bloc.state.playlistName, 'Legacy Playlist');

      bloc.add(const PlayerHlsStarted(
        hlsUrl: 'https://stream.example.com/live.m3u8',
        queueItemId: 'queue-1',
        trackId: 'track-1',
        trackName: 'Track 1',
        playLocally: false,
      ));
      await _tick();

      expect(bloc.state.playlistId, isNull);
      expect(bloc.state.playlistName, isNull);
      expect(bloc.state.currentTrackId, 'track-1');
      expect(bloc.state.currentQueueItemId, 'queue-1');
    });

    test('applies volumePercent/isMuted to audio service volume', () async {
      bloc.add(const PlayerAudioSettingsApplied(
        volumePercent: 70,
        isMuted: false,
      ));
      await _tick();
      expect(audioService.lastSetVolume, closeTo(0.7, 0.0001));

      bloc.add(const PlayerAudioSettingsApplied(
        volumePercent: 70,
        isMuted: true,
      ));
      await _tick();
      expect(audioService.lastSetVolume, 0.0);
    });
  });
}

class _FakeAudioPlayerService extends AudioPlayerService {
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _processingController = StreamController<ProcessingState>.broadcast();

  final List<Duration> seekCalls = [];
  String? _loadedUrl;
  Duration _position = Duration.zero;
  final Duration _bufferedPosition = Duration.zero;
  ProcessingState _processingState = ProcessingState.idle;
  double? lastSetVolume;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Stream<ProcessingState> get processingStateStream =>
      _processingController.stream;

  @override
  Duration get position => _position;

  @override
  Duration get bufferedPosition => _bufferedPosition;

  @override
  ProcessingState get processingState => _processingState;

  @override
  String? get loadedUrl => _loadedUrl;

  @override
  Future<Duration?> loadUrl(String url) async {
    _loadedUrl = url;
    _processingState = ProcessingState.ready;
    return null;
  }

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {
    _loadedUrl = null;
    _position = Duration.zero;
  }

  @override
  Future<void> seek(Duration position) async {
    seekCalls.add(position);
    _position = position;
  }

  @override
  Future<void> setVolume(double volume) async {
    lastSetVolume = volume;
  }

  @override
  Future<void> dispose() async {
    await _positionController.close();
    await _durationController.close();
    await _processingController.close();
  }
}

Future<void> _tick() {
  return Future<void>.delayed(const Duration(milliseconds: 40));
}
