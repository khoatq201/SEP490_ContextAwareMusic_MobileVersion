import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/player/player_state.dart' as ps;
import 'package:cams_store_manager/features/cams/domain/entities/space_playback_state.dart';
import 'package:cams_store_manager/features/cams/domain/entities/space_queue_state_item.dart';
import 'package:cams_store_manager/features/cams/presentation/bloc/cams_playback_state.dart';
import 'package:cams_store_manager/features/now_playing/presentation/models/queue_sheet_view_data.dart';
import 'package:cams_store_manager/features/space_control/domain/entities/track.dart';

void main() {
  group('QueueSheetViewData', () {
    test('keeps played, current, and up-next sections from CAMS queue order',
        () {
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
          Track(
            id: 'track-3',
            title: 'Track Three',
            artist: 'Artist Three',
            fileUrl: '',
            moodTags: [],
            albumArt: 'https://img/track-3.jpg',
          ),
        ],
      );

      const camsState = CamsPlaybackState(
        playbackState: SpacePlaybackState(
          spaceId: 'space-1',
          currentQueueItemId: 'queue-2',
          pendingQueueItemId: 'queue-3',
          queueEndBehavior: 2,
          spaceQueueItems: [
            SpaceQueueStateItem(
              queueItemId: 'queue-3',
              trackId: 'track-3',
              trackName: 'Track Three',
              position: 3,
              queueStatus: SpacePlaybackState.queueStatusPending,
              source: 1,
            ),
            SpaceQueueStateItem(
              queueItemId: 'queue-1',
              trackId: 'track-1',
              trackName: 'Track One',
              position: 1,
              queueStatus: SpacePlaybackState.queueStatusPlayed,
              source: 1,
            ),
            SpaceQueueStateItem(
              queueItemId: 'queue-2',
              trackId: 'track-2',
              trackName: 'Track Two',
              position: 2,
              queueStatus: SpacePlaybackState.queueStatusPlaying,
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
      expect(viewData.items.map((item) => item.queueItemId).toList(), [
        'queue-1',
        'queue-2',
        'queue-3',
      ]);
      expect(viewData.played.map((item) => item.queueItemId).toList(), [
        'queue-1',
      ]);
      expect(viewData.currentItem?.queueItemId, 'queue-2');
      expect(viewData.upNext.map((item) => item.queueItemId).toList(), [
        'queue-3',
      ]);
      expect(viewData.summaryLabel, contains('3 tracks'));
      expect(viewData.summaryLabel, contains('Repeat one'));
    });

    test(
        'falls back to current queue item identity when statuses do not mark history',
        () {
      const playerState = ps.PlayerState(
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
          Track(
            id: 'track-3',
            title: 'Track Three',
            artist: 'Artist Three',
            fileUrl: '',
            moodTags: [],
          ),
        ],
      );

      const camsState = CamsPlaybackState(
        playbackState: SpacePlaybackState(
          spaceId: 'space-1',
          currentQueueItemId: 'queue-2',
          pendingQueueItemId: 'queue-3',
          spaceQueueItems: [
            SpaceQueueStateItem(
              queueItemId: 'queue-1',
              trackId: 'track-1',
              trackName: 'Track One',
              position: 1,
              queueStatus: 0,
              source: 1,
            ),
            SpaceQueueStateItem(
              queueItemId: 'queue-2',
              trackId: 'track-2',
              trackName: 'Track Two',
              position: 2,
              queueStatus: 0,
              source: 1,
            ),
            SpaceQueueStateItem(
              queueItemId: 'queue-3',
              trackId: 'track-3',
              trackName: 'Track Three',
              position: 3,
              queueStatus: 0,
              source: 1,
            ),
          ],
        ),
      );

      final viewData = QueueSheetViewData.resolve(
        playerState: playerState,
        camsState: camsState,
      );

      expect(viewData.played.single.queueItemId, 'queue-1');
      expect(viewData.current.single.queueItemId, 'queue-2');
      expect(viewData.upNext.single.queueItemId, 'queue-3');
      expect(viewData.upNextEmptyMessage, 'No upcoming tracks in queue.');
    });

    test('keeps played items from authoritative queue snapshots', () {
      const playerState = ps.PlayerState(
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
          Track(
            id: 'track-3',
            title: 'Track Three',
            artist: 'Artist Three',
            fileUrl: '',
            moodTags: [],
          ),
        ],
      );

      const camsState = CamsPlaybackState(
        playbackState: SpacePlaybackState(
          spaceId: 'space-1',
          currentQueueItemId: 'queue-2',
          pendingQueueItemId: 'queue-3',
          spaceQueueItems: [
            SpaceQueueStateItem(
              queueItemId: 'queue-1',
              trackId: 'track-1',
              trackName: 'Track One',
              position: 1,
              queueStatus: SpacePlaybackState.queueStatusPlayed,
              source: 1,
            ),
            SpaceQueueStateItem(
              queueItemId: 'queue-2',
              trackId: 'track-2',
              trackName: 'Track Two',
              position: 2,
              queueStatus: SpacePlaybackState.queueStatusPlaying,
              source: 1,
            ),
            SpaceQueueStateItem(
              queueItemId: 'queue-3',
              trackId: 'track-3',
              trackName: 'Track Three',
              position: 3,
              queueStatus: SpacePlaybackState.queueStatusPending,
              source: 1,
            ),
          ],
        ),
      );

      final viewData = QueueSheetViewData.resolve(
        playerState: playerState,
        camsState: camsState,
      );

      expect(viewData.played.map((item) => item.queueItemId).toList(), [
        'queue-1',
      ]);
      expect(viewData.played.single.isHistoryOnly, isFalse);
      expect(viewData.current.single.queueItemId, 'queue-2');
      expect(viewData.upNext.single.queueItemId, 'queue-3');
    });

    test('exposes only pending queue ids for reorder payloads', () {
      const playerState = ps.PlayerState();
      const camsState = CamsPlaybackState(
        playbackState: SpacePlaybackState(
          spaceId: 'space-1',
          currentQueueItemId: 'queue-2',
          spaceQueueItems: [
            SpaceQueueStateItem(
              queueItemId: 'queue-1',
              trackId: 'track-1',
              trackName: 'Track One',
              position: 1,
              queueStatus: SpacePlaybackState.queueStatusPlayed,
              source: 1,
            ),
            SpaceQueueStateItem(
              queueItemId: 'queue-2',
              trackId: 'track-2',
              trackName: 'Track Two',
              position: 2,
              queueStatus: SpacePlaybackState.queueStatusPlaying,
              source: 1,
            ),
            SpaceQueueStateItem(
              queueItemId: 'queue-3',
              trackId: 'track-3',
              trackName: 'Track Three',
              position: 3,
              queueStatus: SpacePlaybackState.queueStatusPending,
              source: 1,
            ),
            SpaceQueueStateItem(
              queueItemId: 'queue-4',
              trackId: 'track-4',
              trackName: 'Track Four',
              position: 4,
              queueStatus: SpacePlaybackState.queueStatusPending,
              source: 1,
            ),
            SpaceQueueStateItem(
              queueItemId: 'queue-5',
              trackId: 'track-5',
              trackName: 'Track Five',
              position: 5,
              queueStatus: SpacePlaybackState.queueStatusSkipped,
              source: 1,
            ),
          ],
        ),
      );

      final viewData = QueueSheetViewData.resolve(
        playerState: playerState,
        camsState: camsState,
      );

      expect(
        viewData.reorderablePendingItems
            .map((item) => item.queueItemId)
            .toList(),
        ['queue-3', 'queue-4'],
      );
    });

    test('maps CAMS queue item sources to display labels', () {
      const playerState = ps.PlayerState();
      const camsState = CamsPlaybackState(
        playbackState: SpacePlaybackState(
          spaceId: 'space-1',
          currentQueueItemId: 'queue-manager',
          spaceQueueItems: [
            SpaceQueueStateItem(
              queueItemId: 'queue-ai',
              trackId: 'track-ai',
              trackName: 'AI Track',
              position: 1,
              queueStatus: SpacePlaybackState.queueStatusPlayed,
              source: 0,
            ),
            SpaceQueueStateItem(
              queueItemId: 'queue-manager',
              trackId: 'track-manager',
              trackName: 'Manager Track',
              position: 2,
              queueStatus: SpacePlaybackState.queueStatusPlaying,
              source: 1,
            ),
            SpaceQueueStateItem(
              queueItemId: 'queue-schedule',
              trackId: 'track-schedule',
              trackName: 'Schedule Track',
              position: 3,
              queueStatus: SpacePlaybackState.queueStatusPending,
              source: 2,
            ),
          ],
        ),
      );

      final viewData = QueueSheetViewData.resolve(
        playerState: playerState,
        camsState: camsState,
      );

      expect(viewData.items.map((item) => item.sourceLabel).toList(), [
        'AI',
        'Manager',
        'Schedule',
      ]);
    });

    test('exposes pending label even when pending item is not in queue list',
        () {
      const playerState = ps.PlayerState();
      const camsState = CamsPlaybackState(
        playbackState: SpacePlaybackState(
          spaceId: 'space-1',
          currentQueueItemId: 'queue-1',
          pendingQueueItemId: 'pending-queue-item',
          spaceQueueItems: [
            SpaceQueueStateItem(
              queueItemId: 'queue-1',
              trackId: 'track-1',
              trackName: 'Track One',
              position: 1,
              queueStatus: SpacePlaybackState.queueStatusPlaying,
              source: 1,
            ),
          ],
        ),
      );

      final viewData = QueueSheetViewData.resolve(
        playerState: playerState,
        camsState: camsState,
      );

      expect(viewData.pendingNotInQueueLabel, 'Preparing next queue item...');
      expect(viewData.currentItem?.queueItemId, 'queue-1');
      expect(viewData.upNext, isEmpty);
    });

    test('falls back to local queue sections when CAMS queue is unavailable',
        () {
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
      expect(viewData.played.single.trackId, 'track-1');
      expect(viewData.currentItem?.trackId, 'track-2');
      expect(viewData.upNext, isEmpty);
      expect(viewData.summaryLabel, '2 tracks in local queue');
    });
  });
}
