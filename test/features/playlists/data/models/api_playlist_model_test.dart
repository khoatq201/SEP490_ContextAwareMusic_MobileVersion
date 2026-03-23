import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/playlists/data/models/api_playlist_model.dart';

void main() {
  group('ApiPlaylistModel', () {
    test('parses per-track hlsUrl from detail payload', () {
      final model = ApiPlaylistModel.fromDetailJson({
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

    test('falls back to audioUrl for legacy track payloads', () {
      final model = ApiPlaylistModel.fromDetailJson({
        'id': 'playlist-legacy',
        'name': 'Legacy Playlist',
        'createdAt': '2026-03-24T08:00:00Z',
        'tracks': [
          {
            'trackId': 'track-legacy',
            'title': 'Legacy Track',
            'audioUrl': 'https://example.com/legacy.mp3',
            'seekOffsetSeconds': 10,
          }
        ],
      });

      expect(model.tracks, isNotNull);
      expect(model.tracks!.first.hlsUrl, 'https://example.com/legacy.mp3');
    });
  });
}
