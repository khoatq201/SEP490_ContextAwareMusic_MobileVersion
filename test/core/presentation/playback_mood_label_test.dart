import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/presentation/playback_mood_label.dart';

void main() {
  group('buildPlaybackMoodLabel', () {
    test('returns manual override when manual mode has no mood', () {
      final label = buildPlaybackMoodLabel(
        isManualOverride: true,
      );

      expect(label, 'Manual override');
    });

    test('prefixes manual moods clearly', () {
      final label = buildPlaybackMoodLabel(
        isManualOverride: true,
        primaryMoodName: 'Focus',
      );

      expect(label, 'Manual: Focus');
    });

    test('prefixes AI moods clearly', () {
      final label = buildPlaybackMoodLabel(
        isManualOverride: false,
        primaryMoodName: 'Chill',
      );

      expect(label, 'AI: Chill');
    });

    test('uses fallback mood names in auto mode', () {
      final label = buildPlaybackMoodLabel(
        isManualOverride: false,
        fallbackMoodNames: const ['Energetic'],
      );

      expect(label, 'AI: Energetic');
    });

    test('returns null in auto mode when no mood exists', () {
      final label = buildPlaybackMoodLabel(
        isManualOverride: false,
      );

      expect(label, isNull);
    });
  });
}
