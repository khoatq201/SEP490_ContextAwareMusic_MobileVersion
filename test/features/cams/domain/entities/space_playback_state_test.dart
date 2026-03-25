import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/cams/domain/entities/space_playback_state.dart';

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
}
