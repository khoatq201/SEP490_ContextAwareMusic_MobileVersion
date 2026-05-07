import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart' as ja;

import 'package:cams_store_manager/core/audio/audio_player_service.dart';
import 'package:cams_store_manager/core/audio/playback_notification_service.dart';
import 'package:cams_store_manager/core/player/player_state.dart' as ps;
import 'package:cams_store_manager/features/space_control/domain/entities/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlaybackNotificationService', () {
    test('publishes latest position while playback updates keep flowing',
        () async {
      final audioService = _FakeAudioPlayerService();
      final handler = CamsAudioHandler();
      final service = PlaybackNotificationService.test(
        handler: handler,
        audioPlayerService: audioService,
      );
      final publishedStates = <PlaybackState>[];
      final subscription = handler.playbackState.listen(publishedStates.add);
      addTearDown(() async {
        await subscription.cancel();
        await service.dispose();
        await audioService.dispose();
      });

      await Future<void>.delayed(Duration.zero);
      publishedStates.clear();

      service.syncPlayerState(_playerState(positionSeconds: 10), enabled: true);
      await _waitUntil(() => publishedStates.isNotEmpty);
      expect(publishedStates.last.updatePosition.inSeconds, 10);

      for (var position = 20; position <= 24; position++) {
        service.syncPlayerState(
          _playerState(positionSeconds: position),
          enabled: true,
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      await _waitUntil(
        () => publishedStates.last.updatePosition.inSeconds >= 24,
      );
      expect(publishedStates.last.playing, isTrue);
      expect(publishedStates.last.speed, 1.0);
    });
  });
}

ps.PlayerState _playerState({required int positionSeconds}) {
  return ps.PlayerState(
    currentTrack: const Track(
      id: 'track-1',
      title: 'Track One',
      artist: 'Artist One',
      fileUrl: '',
      moodTags: [],
      duration: 180,
    ),
    isPlaying: true,
    currentPosition: positionSeconds,
    currentPositionPrecise: positionSeconds.toDouble(),
    duration: 180,
  );
}

Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for condition');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

class _FakeAudioPlayerService extends AudioPlayerService {
  final _playerStateController = StreamController<ja.PlayerState>.broadcast();

  @override
  Stream<ja.PlayerState> get playerStateStream => _playerStateController.stream;

  @override
  ja.ProcessingState get processingState => ja.ProcessingState.ready;

  @override
  Duration get bufferedPosition => Duration.zero;

  @override
  Future<void> dispose() async {
    await _playerStateController.close();
  }
}
