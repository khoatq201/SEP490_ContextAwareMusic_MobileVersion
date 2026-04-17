import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/playlists/data/models/api_playlist_model.dart';

void main() {
  group('ApiPlaylistModel', () {
    test('parses per-track hlsUrl from detail payload', () {
      final model = ApiPlaylistModel.fromDetailJson(const {
        'id': 'playlist-1',
        'name': 'Playlist',
        'createdAt': '2026-03-24T08:00:00Z',
        'tracks': [
          {
            'trackId': 'track-1',
            'title': 'Track 1',
            'hlsUrl': 'https://example.com/t1.m3u8',
            'seekOffsetSeconds': 0,
          }
        ],
      });

      expect(model.tracks, isNotNull);
      expect(model.tracks!.first.hlsUrl, 'https://example.com/t1.m3u8');
    });

    test('derives total duration from track detail payload', () {
      final model = ApiPlaylistModel.fromDetailJson(const {
        'id': 'playlist-2',
        'name': 'Playlist',
        'createdAt': '2026-03-24T08:00:00Z',
        'tracks': [
          {
            'trackId': 'track-1',
            'durationSec': 120,
            'seekOffsetSeconds': 0,
          },
          {
            'trackId': 'track-2',
            'actualDurationSec': 95,
            'seekOffsetSeconds': 120,
          }
        ],
      });

      expect(model.resolvedTotalDurationSeconds, 215);
    });
  });
}
