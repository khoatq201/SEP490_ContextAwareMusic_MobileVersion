import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/enums/entity_status_enum.dart';
import 'package:cams_store_manager/features/playlists/domain/entities/api_playlist.dart';
import 'package:cams_store_manager/features/playlists/domain/entities/playlist_track_item.dart';

void main() {
  group('ApiPlaylist.isStreamReady', () {
    test('prefers per-track hls readiness when detail tracks exist', () {
      final playlist = ApiPlaylist(
        id: 'playlist-1',
        name: 'Queue-first playlist',
        hlsUrl: 'https://legacy.example.com/playlist.m3u8',
        trackCount: 2,
        status: EntityStatusEnum.active,
        createdAt: DateTime.utc(2026, 3, 25),
        tracks: const [
          PlaylistTrackItem(
            trackId: 'track-1',
            hlsUrl: null,
            seekOffsetSeconds: 0,
          ),
          PlaylistTrackItem(
            trackId: 'track-2',
            hlsUrl: '',
            seekOffsetSeconds: 120,
          ),
        ],
      );

      expect(playlist.isStreamReady, isFalse);
    });

    test('returns true when any track has hls url', () {
      final playlist = ApiPlaylist(
        id: 'playlist-1',
        name: 'Queue-first playlist',
        trackCount: 2,
        status: EntityStatusEnum.active,
        createdAt: DateTime.utc(2026, 3, 25),
        tracks: const [
          PlaylistTrackItem(
            trackId: 'track-1',
            hlsUrl: '',
            seekOffsetSeconds: 0,
          ),
          PlaylistTrackItem(
            trackId: 'track-2',
            hlsUrl: 'https://stream.example.com/t2.m3u8',
            seekOffsetSeconds: 120,
          ),
        ],
      );

      expect(playlist.isStreamReady, isTrue);
    });

    test('falls back to legacy playlist-level hls url when tracks are absent',
        () {
      final playlist = ApiPlaylist(
        id: 'playlist-1',
        name: 'Legacy list item',
        hlsUrl: 'https://legacy.example.com/playlist.m3u8',
        trackCount: 0,
        status: EntityStatusEnum.active,
        createdAt: DateTime.utc(2026, 3, 25),
      );

      expect(playlist.isStreamReady, isTrue);
    });
  });

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
