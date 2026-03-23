import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/tracks/data/models/api_track_model.dart';

void main() {
  group('ApiTrackModel', () {
    test('reads hlsUrl when present', () {
      final model = ApiTrackModel.fromJson({
        'id': 'track-1',
        'title': 'Track 1',
        'hlsUrl': 'https://example.com/t1.m3u8',
        'createdAt': '2026-03-24T08:00:00Z',
      });

      expect(model.hlsUrl, 'https://example.com/t1.m3u8');
    });

    test('falls back to audioUrl for backward compatibility', () {
      final model = ApiTrackModel.fromJson({
        'id': 'track-2',
        'title': 'Track 2',
        'audioUrl': 'https://example.com/legacy-track.mp3',
        'createdAt': '2026-03-24T08:00:00Z',
      });

      expect(model.hlsUrl, 'https://example.com/legacy-track.mp3');
    });
  });
}
