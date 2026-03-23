import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/enums/entity_status_enum.dart';
import 'package:cams_store_manager/features/playlists/domain/entities/api_playlist.dart';
import 'package:cams_store_manager/features/playlists/domain/entities/playlist_track_item.dart';

void main() {
  group('ApiPlaylist.resolvedTotalDurationSeconds', () {
    test('prefers summed track durations when backend total mismatches', () {
      final playlist = ApiPlaylist(
        id: 'playlist-1',
        name: 'Calms playlist',
        totalDurationSeconds: 382,
        trackCount: 2,
        status: EntityStatusEnum.active,
        createdAt: DateTime.utc(2026, 3, 17),
        tracks: const [
          PlaylistTrackItem(
            trackId: 'track-1',
            durationSec: 175,
            seekOffsetSeconds: 0,
          ),
          PlaylistTrackItem(
            trackId: 'track-2',
            durationSec: 206,
            seekOffsetSeconds: 175,
          ),
        ],
      );

      expect(playlist.resolvedTotalDurationSeconds, 381);
    });

    test('keeps backend total when it already matches summed tracks', () {
      final playlist = ApiPlaylist(
        id: 'playlist-1',
        name: 'Calms playlist',
        totalDurationSeconds: 381,
        trackCount: 2,
        status: EntityStatusEnum.active,
        createdAt: DateTime.utc(2026, 3, 17),
        tracks: const [
          PlaylistTrackItem(
            trackId: 'track-1',
            durationSec: 175,
            seekOffsetSeconds: 0,
          ),
          PlaylistTrackItem(
            trackId: 'track-2',
            durationSec: 206,
            seekOffsetSeconds: 175,
          ),
        ],
      );

      expect(playlist.resolvedTotalDurationSeconds, 381);
    });
  });
}
