import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/enums/entity_status_enum.dart';
import 'package:cams_store_manager/core/player/playlist_queue_builder.dart';
import 'package:cams_store_manager/features/playlists/domain/entities/api_playlist.dart';
import 'package:cams_store_manager/features/playlists/domain/entities/playlist_track_item.dart';

void main() {
  group('buildPlaylistQueue', () {
    test('uses seek offsets as primary duration source between tracks', () {
      final playlist = ApiPlaylist(
        id: 'playlist-1',
        name: 'Queue-first',
        totalDurationSeconds: 300,
        status: EntityStatusEnum.active,
        createdAt: DateTime.utc(2026, 3, 25),
        tracks: const [
          PlaylistTrackItem(
            trackId: 'track-1',
            title: 'Track 1',
            seekOffsetSeconds: 0,
          ),
          PlaylistTrackItem(
            trackId: 'track-2',
            title: 'Track 2',
            seekOffsetSeconds: 100,
          ),
          PlaylistTrackItem(
            trackId: 'track-3',
            title: 'Track 3',
            seekOffsetSeconds: 250,
          ),
        ],
      );

      final queue = buildPlaylistQueue(playlist);

      expect(queue.length, 3);
      expect(queue[0].duration, 100);
      expect(queue[1].duration, 150);
      expect(queue[2].duration, 50);
    });

    test('falls back to effective track duration for the final item', () {
      final playlist = ApiPlaylist(
        id: 'playlist-2',
        name: 'Fallback duration',
        status: EntityStatusEnum.active,
        createdAt: DateTime.utc(2026, 3, 25),
        tracks: const [
          PlaylistTrackItem(
            trackId: 'track-1',
            title: 'Track 1',
            durationSec: 90,
            seekOffsetSeconds: 0,
          ),
          PlaylistTrackItem(
            trackId: 'track-2',
            title: 'Track 2',
            durationSec: 120,
            actualDurationSec: 125,
            seekOffsetSeconds: 90,
          ),
        ],
      );

      final queue = buildPlaylistQueue(playlist);

      expect(queue.length, 2);
      expect(queue[0].duration, 90);
      expect(queue[1].duration, 125);
      expect(queue[0].seekOffsetSeconds, 0);
      expect(queue[1].seekOffsetSeconds, 90);
    });
  });
}
