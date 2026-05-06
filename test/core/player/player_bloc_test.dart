import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

import 'package:cams_store_manager/core/audio/audio_player_service.dart';
import 'package:cams_store_manager/core/enums/playback_command_enum.dart';
import 'package:cams_store_manager/core/player/player_bloc.dart';
import 'package:cams_store_manager/core/player/player_event.dart';
import 'package:cams_store_manager/core/player/space_info.dart';
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

    test('force reload allows repeat-one HLS restart after completion',
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
        seekOffsetSeconds: 90,
      ));
      await _tick();
      bloc.add(const PlayerTrackCompleted());
      await _tick();

      audioService.setProcessingState(ProcessingState.completed);
      final loadCallCount = audioService.loadCallCount;
      final seekCallCount = audioService.seekCalls.length;
      final playCallCount = audioService.playCallCount;

      bloc.add(PlayerHlsStarted(
        hlsUrl: 'https://stream.example.com/live.m3u8',
        playlistId: 'playlist-1',
        queueItemId: 'queue-1',
        trackId: 'track-1',
        trackName: 'Track 1',
        seekOffsetSeconds: 0,
        startedAtUtc: DateTime.now().toUtc(),
        forceReload: true,
      ));
      await _tick();

      expect(audioService.loadCallCount, loadCallCount + 1);
      expect(audioService.seekCalls.length, seekCallCount + 1);
      expect(
        audioService.seekCalls.last.inMilliseconds,
        lessThanOrEqualTo(50),
      );
      expect(audioService.playCallCount, playCallCount + 1);
      expect(bloc.state.currentQueueItemId, 'queue-1');
      expect(bloc.state.isPlaying, isTrue);
    });

    test(
        'maps local HLS position updates for later queue items back to absolute queue offsets',
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
        playlistId: 'playlist-1',
        force: true,
      ));
      await _tick();

      bloc.add(const PlayerHlsStarted(
        hlsUrl: 'https://stream.example.com/live.m3u8',
        playlistId: 'playlist-1',
        queueItemId: 'queue-2',
        trackId: 'track-2',
        trackName: 'Track 2',
        seekOffsetSeconds: 5,
        playLocally: false,
      ));
      await _tick();

      expect(bloc.state.currentIndex, 1);
      expect(bloc.state.currentPositionPrecise, closeTo(185, 0.001));
      expect(bloc.state.displayPositionPrecise, closeTo(5, 0.001));

      bloc.add(const PlayerPositionUpdated(positionSeconds: 12));
      await _tick();

      expect(bloc.state.currentPositionPrecise, closeTo(192, 0.001));
      expect(bloc.state.displayPositionPrecise, closeTo(12, 0.001));
      expect(bloc.state.progress, closeTo(12 / 220, 0.001));
    });

    test(
        'seeks local HLS audio with track-relative time but keeps absolute queue state',
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
        playlistId: 'playlist-1',
        force: true,
      ));
      await _tick();

      bloc.add(const PlayerHlsStarted(
        hlsUrl: 'https://stream.example.com/live.m3u8',
        playlistId: 'playlist-1',
        queueItemId: 'queue-2',
        trackId: 'track-2',
        trackName: 'Track 2',
        seekOffsetSeconds: 5,
        playLocally: true,
      ));
      await _tick();

      bloc.add(const PlayerSeekRequested(positionSeconds: 210));
      await _tick();

      expect(audioService.seekCalls.last, const Duration(seconds: 30));
      expect(bloc.state.currentPositionPrecise, closeTo(210, 0.001));
      expect(bloc.state.displayPositionPrecise, closeTo(30, 0.001));
    });

    test(
        'keeps progress moving when local HLS playback switches from the first queue track to the second',
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
        playlistId: 'playlist-1',
        force: true,
      ));
      await _tick();

      bloc.add(const PlayerHlsStarted(
        hlsUrl: 'https://stream.example.com/t1.m3u8',
        playlistId: 'playlist-1',
        queueItemId: 'queue-1',
        trackId: 'track-1',
        trackName: 'Track 1',
        seekOffsetSeconds: 3,
        playLocally: true,
      ));
      await _tick();

      expect(bloc.state.currentTrackId, 'track-1');
      expect(bloc.state.displayPositionPrecise, closeTo(3, 0.001));
      expect(audioService.loadedUrl, 'https://stream.example.com/t1.m3u8');
      expect(audioService.seekCalls.last, const Duration(seconds: 3));

      bloc.add(const PlayerPositionUpdated(positionSeconds: 11));
      await _tick();

      expect(bloc.state.displayPositionPrecise, closeTo(11, 0.001));
      expect(bloc.state.currentPositionPrecise, closeTo(11, 0.001));

      bloc.add(const PlayerHlsStarted(
        hlsUrl: 'https://stream.example.com/t2.m3u8',
        playlistId: 'playlist-1',
        queueItemId: 'queue-2',
        trackId: 'track-2',
        trackName: 'Track 2',
        seekOffsetSeconds: 4,
        playLocally: true,
      ));
      await _tick();

      expect(bloc.state.currentTrackId, 'track-2');
      expect(bloc.state.currentQueueItemId, 'queue-2');
      expect(bloc.state.currentIndex, 1);
      expect(bloc.state.displayPositionPrecise, closeTo(4, 0.001));
      expect(bloc.state.currentPositionPrecise, closeTo(184, 0.001));
      expect(audioService.loadedUrl, 'https://stream.example.com/t2.m3u8');
      expect(audioService.seekCalls.last, const Duration(seconds: 4));

      bloc.add(const PlayerPositionUpdated(positionSeconds: 9));
      await _tick();

      expect(bloc.state.displayPositionPrecise, closeTo(9, 0.001));
      expect(bloc.state.currentPositionPrecise, closeTo(189, 0.001));
      expect(bloc.state.progress, closeTo(9 / 220, 0.001));
    });

    test(
        'clears stale stream duration when switching to a track whose duration is not known yet',
        () async {
      final queue = [
        const Track(
          id: 'track-1',
          queueItemId: 'queue-1',
          title: 'Long Track',
          artist: 'Artist',
          fileUrl: '',
          moodTags: [],
          duration: 360,
          seekOffsetSeconds: 0,
        ),
        const Track(
          id: 'track-2',
          queueItemId: 'queue-2',
          title: 'Short Track',
          artist: 'Artist',
          fileUrl: '',
          moodTags: [],
          duration: null,
          seekOffsetSeconds: 360,
        ),
      ];

      bloc.add(PlayerQueueSeeded(
        tracks: queue,
        playlistId: 'playlist-1',
        force: true,
      ));
      await _tick();

      bloc.add(const PlayerHlsStarted(
        hlsUrl: 'https://stream.example.com/long.m3u8',
        playlistId: 'playlist-1',
        queueItemId: 'queue-1',
        trackId: 'track-1',
        trackName: 'Long Track',
        seekOffsetSeconds: 120,
        playLocally: true,
      ));
      await _tick();

      expect(bloc.state.currentTrackId, 'track-1');
      expect(bloc.state.duration, 360);
      expect(bloc.state.progress, closeTo(120 / 360, 0.001));

      bloc.add(const PlayerHlsStarted(
        hlsUrl: 'https://stream.example.com/short.m3u8',
        playlistId: 'playlist-1',
        queueItemId: 'queue-2',
        trackId: 'track-2',
        trackName: 'Short Track',
        seekOffsetSeconds: 6,
        playLocally: true,
      ));
      await _tick();

      expect(bloc.state.currentTrackId, 'track-2');
      expect(bloc.state.currentQueueItemId, 'queue-2');
      expect(bloc.state.displayPositionPrecise, closeTo(6, 0.001));
      expect(bloc.state.duration, 0);
      expect(bloc.state.progress, 0);

      audioService.emitDuration(const Duration(seconds: 45));
      await _tick();

      expect(bloc.state.duration, 45);
      expect(bloc.state.progress, closeTo(6 / 45, 0.001));
    });

    test('maps skipToTrack without offset by targetQueueItemId', () async {
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
      audioService.seekCalls.clear();

      bloc.add(const PlayerRemoteCommandApplied(
        command: PlaybackCommandEnum.skipToTrack,
        targetQueueItemId: 'queue-2',
        playLocally: true,
      ));
      await _tick();

      expect(bloc.state.currentTrackId, 'track-2');
      expect(bloc.state.currentIndex, 1);
      expect(bloc.state.currentTrack?.id, 'track-2');
      expect(bloc.state.currentQueueItemId, 'queue-2');
      expect(bloc.state.currentPosition, 180);
      expect(audioService.seekCalls, isEmpty);
    });

    test('ignores targetTrackId on seek to prevent wrong title jumps',
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

    test('keeps current queue item when remote seek position is track-relative',
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
        playlistId: 'playlist-1',
        force: true,
      ));
      await _tick();

      bloc.add(const PlayerHlsStarted(
        hlsUrl: 'https://stream.example.com/live.m3u8',
        playlistId: 'playlist-1',
        queueItemId: 'queue-2',
        trackId: 'track-2',
        trackName: 'Track 2',
        seekOffsetSeconds: 18,
        playLocally: false,
      ));
      await _tick();

      bloc.add(const PlayerRemoteCommandApplied(
        command: PlaybackCommandEnum.seek,
        positionSeconds: 100,
        playLocally: false,
      ));
      await _tick();

      expect(bloc.state.currentTrackId, 'track-2');
      expect(bloc.state.currentIndex, 1);
      expect(bloc.state.currentTrack?.id, 'track-2');
      expect(bloc.state.currentQueueItemId, 'queue-2');
      expect(bloc.state.currentPosition, 280);
      expect(bloc.state.displayPositionPrecise, closeTo(100, 0.001));
    });

    test(
        'does not remap track by offset when queue timeline metadata is absent',
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

    test('focuses pending queue item before HLS stream starts', () async {
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

      bloc.add(const PlayerQueueFocusApplied(
        queueItemId: 'queue-2',
        trackId: 'track-2',
        isPlaying: false,
      ));
      await _tick();

      expect(bloc.state.currentIndex, 1);
      expect(bloc.state.currentTrack?.id, 'track-2');
      expect(bloc.state.currentTrackId, 'track-2');
      expect(bloc.state.currentQueueItemId, 'queue-2');
      expect(bloc.state.hasTrack, isTrue);
      expect(bloc.state.isPlaying, isFalse);
      expect(bloc.state.isSyncedCamsPlayback, isFalse);
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

    test('stops audio engine and clears queue-first state on HLS stop',
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
      ];

      bloc.add(PlayerQueueSeeded(
        tracks: queue,
        force: true,
      ));
      await _tick();

      bloc.add(const PlayerHlsStarted(
        hlsUrl: 'https://stream.example.com/live.m3u8',
        queueItemId: 'queue-1',
        trackId: 'track-1',
        trackName: 'Track 1',
        playLocally: true,
      ));
      await _tick();

      expect(bloc.state.hasTrack, isTrue);
      expect(audioService.loadedUrl, 'https://stream.example.com/live.m3u8');

      bloc.add(const PlayerHlsStopped());
      await _tick();

      expect(bloc.state.hasTrack, isFalse);
      expect(bloc.state.queue, isEmpty);
      expect(bloc.state.hlsUrl, isNull);
      expect(audioService.loadedUrl, isNull);
      expect(audioService.stopCallCount, 1);
    });

    test('clears playback state when active space context changes', () async {
      bloc.add(const PlayerContextUpdated(
        storeId: 'store-1',
        spaceId: 'space-1',
        spaceName: 'Space 1',
        availableSpaces: [
          SpaceInfo(
            id: 'space-1',
            storeId: 'store-1',
            name: 'Space 1',
            isOnline: true,
          ),
          SpaceInfo(
            id: 'space-2',
            storeId: 'store-1',
            name: 'Space 2',
            isOnline: true,
          ),
        ],
      ));
      await _tick();

      bloc.add(const PlayerHlsStarted(
        hlsUrl: 'https://stream.example.com/space-1.m3u8',
        queueItemId: 'queue-1',
        trackId: 'track-1',
        trackName: 'Track 1',
        playLocally: true,
      ));
      await _tick();

      expect(bloc.state.isSyncedCamsPlayback, isTrue);
      expect(audioService.loadedUrl, 'https://stream.example.com/space-1.m3u8');

      bloc.add(const PlayerContextUpdated(
        storeId: 'store-1',
        spaceId: 'space-2',
        spaceName: 'Space 2',
      ));
      await _tick();

      expect(audioService.loadedUrl, isNull);
      expect(audioService.stopCallCount, 1);
      expect(bloc.state.activeSpaceId, 'space-2');
      expect(bloc.state.hasTrack, isFalse);
      expect(bloc.state.queue, isEmpty);
      expect(bloc.state.hlsUrl, isNull);
      expect(
        bloc.state.availableSpaces.map((space) => space.id),
        ['space-1', 'space-2'],
      );
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
  int loadCallCount = 0;
  int playCallCount = 0;
  int stopCallCount = 0;

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
    loadCallCount += 1;
    _loadedUrl = url;
    _processingState = ProcessingState.ready;
    return null;
  }

  @override
  Future<void> play() async {
    playCallCount += 1;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {
    stopCallCount += 1;
    _loadedUrl = null;
    _position = Duration.zero;
  }

  @override
  Future<void> seek(Duration position) async {
    seekCalls.add(position);
    _position = position;
  }

  void emitDuration(Duration? duration) {
    _durationController.add(duration);
  }

  void setProcessingState(ProcessingState processingState) {
    _processingState = processingState;
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
