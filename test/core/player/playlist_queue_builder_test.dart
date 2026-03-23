import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/enums/entity_status_enum.dart';
import 'package:cams_store_manager/core/player/playlist_queue_builder.dart';
import 'package:cams_store_manager/features/playlists/domain/entities/api_playlist.dart';
import 'package:cams_store_manager/features/playlists/domain/entities/playlist_track_item.dart';

void main() {
  test('buildPlaylistQueue uses resolved total duration for last track', () {
    final playlist = ApiPlaylist(
      id: 'playlist-1',
      name: 'Calms playlist',
      totalDurationSeconds: 382, // Backend can be off by 1s
      trackCount: 2,
      status: EntityStatusEnum.active,
      createdAt: DateTime.utc(2026, 3, 17),
      tracks: const [
        PlaylistTrackItem(
          trackId: 'track-1',
          title: 'Track 1',
          durationSec: 175,
          seekOffsetSeconds: 0,
        ),
        PlaylistTrackItem(
          trackId: 'track-2',
          title: 'Track 2',
          durationSec: 206,
          seekOffsetSeconds: 175,
        ),
      ],
    );

    final queue = buildPlaylistQueue(playlist);

    expect(queue.length, 2);
    expect(queue[0].duration, 175);
    expect(queue[1].duration, 206);
    expect(queue[0].seekOffsetSeconds, 0);
    expect(queue[1].seekOffsetSeconds, 175);
  });
}
