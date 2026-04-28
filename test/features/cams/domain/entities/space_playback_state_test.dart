import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/cams/domain/entities/space_playback_state.dart';
import 'package:cams_store_manager/features/cams/domain/entities/space_queue_state_item.dart';

void main() {
  group('SpacePlaybackState.effectiveSeekOffset', () {
    test('uses startedAtUtc while playing, even when seekOffsetSeconds exists',
        () {
      final startedAtUtc = DateTime.now().toUtc().subtract(
            const Duration(seconds: 12),
          );
      final state = SpacePlaybackState(
        spaceId: 'space-1',
        startedAtUtc: startedAtUtc,
        seekOffsetSeconds: 2,
      );

      expect(state.effectiveSeekOffset, inInclusiveRange(10.0, 14.0));
    });

    test('returns pausePositionSeconds when paused', () {
      const state = SpacePlaybackState(
        spaceId: 'space-1',
        isPaused: true,
        pausePositionSeconds: 37,
        seekOffsetSeconds: 99,
      );

      expect(state.effectiveSeekOffset, 37);
    });

    test('falls back to seekOffsetSeconds when startedAtUtc is missing', () {
      const state = SpacePlaybackState(
        spaceId: 'space-1',
        seekOffsetSeconds: 88.5,
      );

      expect(state.effectiveSeekOffset, 88.5);
    });

    test('uses startedAtUtc when seekOffsetSeconds is null', () {
      final startedAtUtc = DateTime.now().toUtc().subtract(
            const Duration(seconds: 7),
          );
      final state = SpacePlaybackState(
        spaceId: 'space-1',
        startedAtUtc: startedAtUtc,
        seekOffsetSeconds: null,
      );

      expect(state.effectiveSeekOffset, inInclusiveRange(5.0, 9.0));
    });

    test('never returns negative when startedAtUtc is in the future', () {
      final state = SpacePlaybackState(
        spaceId: 'space-1',
        startedAtUtc: DateTime.now().toUtc().add(const Duration(seconds: 10)),
      );

      expect(state.effectiveSeekOffset, 0);
    });
  });

  group('SpacePlaybackState queue fallback', () {
    test('does not derive active playback fields from queue snapshot alone', () {
      const state = SpacePlaybackState(
        spaceId: 'space-1',
        spaceQueueItems: [
          SpaceQueueStateItem(
            queueItemId: 'queue-1',
            trackId: 'track-1',
            trackName: 'Track One',
            position: 1,
            queueStatus: 0,
            source: 1,
            hlsUrl: 'https://example.com/t1.m3u8',
            isReadyToStream: true,
          ),
          SpaceQueueStateItem(
            queueItemId: 'queue-2',
            trackId: 'track-2',
            trackName: 'Track Two',
            position: 2,
            queueStatus: 0,
            source: 1,
            hlsUrl: 'https://example.com/t2.m3u8',
            isReadyToStream: true,
          ),
        ],
      );

      expect(state.effectiveQueueItemId, isNull);
      expect(state.effectiveTrackName, isNull);
      expect(state.effectiveHlsUrl, isNull);
      expect(state.hasPlayableHls, isFalse);
      expect(state.isStreaming, isFalse);
    });

    test('does not derive active playback from played queue items', () {
      const state = SpacePlaybackState(
        spaceId: 'space-1',
        spaceQueueItems: [
          SpaceQueueStateItem(
            queueItemId: 'queue-1',
            trackId: 'track-1',
            trackName: 'Track One',
            position: 1,
            queueStatus: SpacePlaybackState.queueStatusPlayed,
            source: 1,
            hlsUrl: 'https://example.com/t1.m3u8',
            isReadyToStream: true,
          ),
          SpaceQueueStateItem(
            queueItemId: 'queue-2',
            trackId: 'track-2',
            trackName: 'Track Two',
            position: 2,
            queueStatus: SpacePlaybackState.queueStatusSkipped,
            source: 1,
            hlsUrl: 'https://example.com/t2.m3u8',
            isReadyToStream: true,
          ),
        ],
      );

      expect(state.effectiveQueueItemId, isNull);
      expect(state.effectiveTrackName, isNull);
      expect(state.effectiveHlsUrl, isNull);
      expect(state.hasPlayableHls, isFalse);
      expect(state.isStreaming, isFalse);
    });
  });
}
