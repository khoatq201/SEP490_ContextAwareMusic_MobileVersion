import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/player/player_state.dart' as ps;
import 'package:cams_store_manager/features/cams/domain/entities/space_playback_state.dart';
import 'package:cams_store_manager/features/cams/domain/entities/space_queue_state_item.dart';
import 'package:cams_store_manager/features/cams/presentation/bloc/cams_playback_state.dart';
import 'package:cams_store_manager/features/now_playing/presentation/models/queue_sheet_view_data.dart';
import 'package:cams_store_manager/features/space_control/domain/entities/track.dart';

void main() {
  group('QueueSheetViewData', () {
    test('prioritizes CAMS queue snapshot and sorts by queue position', () {
      const playerState = ps.PlayerState(
        queue: [
          Track(
            id: 'track-1',
            title: 'Track One',
            artist: 'Artist One',
            fileUrl: '',
            moodTags: [],
            albumArt: 'https://img/track-1.jpg',
          ),
          Track(
            id: 'track-2',
            title: 'Track Two',
            artist: 'Artist Two',
            fileUrl: '',
            moodTags: [],
            albumArt: 'https://img/track-2.jpg',
          ),
        ],
      );

      const camsState = CamsPlaybackState(
        playbackState: SpacePlaybackState(
          spaceId: 'space-1',
          currentQueueItemId: 'queue-1',
          queueEndBehavior: 2,
          spaceQueueItems: [
            SpaceQueueStateItem(
              queueItemId: 'queue-2',
              trackId: 'track-2',
              trackName: 'Track Two',
              position: 2,
              queueStatus: 1,
              source: 1,
            ),
            SpaceQueueStateItem(
              queueItemId: 'queue-1',
              trackId: 'track-1',
              trackName: 'Track One',
              position: 1,
              queueStatus: 1,
              source: 1,
              isReadyToStream: true,
            ),
          ],
        ),
      );

      final viewData = QueueSheetViewData.resolve(
        playerState: playerState,
        camsState: camsState,
      );

      expect(viewData.isFromCams, isTrue);
      expect(viewData.items, hasLength(2));
      expect(viewData.items.first.queueItemId, 'queue-1');
      expect(viewData.items.first.trackId, 'track-1');
      expect(viewData.currentItem?.queueItemId, 'queue-1');
      expect(viewData.upNext, hasLength(1));
      expect(viewData.upNext.first.queueItemId, 'queue-2');
      expect(viewData.summaryLabel, contains('2 tracks'));
      expect(viewData.summaryLabel, contains('Repeat one'));
    });

    test('exposes pending state even when pending item is not in queue list',
        () {
      const playerState = ps.PlayerState();
      const camsState = CamsPlaybackState(
        playbackState: SpacePlaybackState(
          spaceId: 'space-1',
          pendingQueueItemId: 'pending-queue-item',
          spaceQueueItems: [
            SpaceQueueStateItem(
              queueItemId: 'queue-1',
              trackId: 'track-1',
              trackName: 'Track One',
              position: 1,
              queueStatus: 1,
              source: 1,
            ),
          ],
        ),
      );

      final viewData = QueueSheetViewData.resolve(
        playerState: playerState,
        camsState: camsState,
      );

      expect(viewData.isFromCams, isTrue);
      expect(viewData.pendingNotInQueueLabel, 'Preparing next queue item...');
      expect(viewData.currentItem?.title, 'Track One');
    });

    test('falls back to local queue when CAMS queue snapshot is empty', () {
      const playerState = ps.PlayerState(
        currentIndex: 1,
        queue: [
          Track(
            id: 'track-1',
            title: 'Track One',
            artist: 'Artist One',
            fileUrl: '',
            moodTags: [],
          ),
          Track(
            id: 'track-2',
            title: 'Track Two',
            artist: 'Artist Two',
            fileUrl: '',
            moodTags: [],
          ),
        ],
      );

      const camsState = CamsPlaybackState(
        playbackState: SpacePlaybackState(spaceId: 'space-1'),
      );

      final viewData = QueueSheetViewData.resolve(
        playerState: playerState,
        camsState: camsState,
      );

      expect(viewData.isFromCams, isFalse);
      expect(viewData.items, hasLength(2));
      expect(viewData.currentItem?.trackId, 'track-2');
      expect(viewData.upNext, isEmpty);
      expect(viewData.summaryLabel, '2 tracks in local queue');
    });
  });
}
