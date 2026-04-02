import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/cams/data/models/space_playback_state_model.dart';

void main() {
  group('SpacePlaybackStateModel', () {
    test('parses queue-first payload and prefers new fields in mixed schema',
        () {
      final model = SpacePlaybackStateModel.fromJson({
        'spaceId': 'space-1',
        'currentQueueItemId': 'queue-new',
        'currentTrackName': 'New Track',
        'currentPlaylistId': 'playlist-legacy',
        'currentPlaylistName': 'Legacy Playlist Name',
        'hlsUrl': 'https://example.com/stream.m3u8',
        'pendingQueueItemId': 'pending-new',
        'pendingPlaylistId': 'pending-legacy',
        'volumePercent': 65,
        'isMuted': true,
        'queueEndBehavior': 2,
        'spaceQueueItems': [
          {
            'queueItemId': 'queue-new',
            'trackId': 'track-1',
            'trackName': 'New Track',
            'position': 1,
            'queueStatus': 1,
            'source': 1,
            'hlsUrl': 'https://example.com/t1.m3u8',
            'isReadyToStream': true,
          }
        ],
      });

      expect(model.currentQueueItemId, 'queue-new');
      expect(model.currentTrackName, 'New Track');
      expect(model.pendingQueueItemId, 'pending-new');
      expect(model.currentPlaylistId, 'playlist-legacy');
      expect(model.volumePercent, 65);
      expect(model.isMuted, true);
      expect(model.queueEndBehavior, 2);
      expect(model.spaceQueueItems, hasLength(1));
      expect(model.isStreaming, true);
    });

    test('parses legacy playlist-centric payload with queue-field fallback',
        () {
      final model = SpacePlaybackStateModel.fromJson({
        'spaceId': 'space-legacy',
        'currentPlaylistId': 'playlist-1',
        'currentPlaylistName': 'Legacy Playlist',
        'pendingPlaylistId': 'playlist-pending',
      });

      expect(model.currentQueueItemId, 'playlist-1');
      expect(model.currentTrackName, 'Legacy Playlist');
      expect(model.pendingQueueItemId, 'playlist-pending');
      expect(model.volumePercent, 100);
      expect(model.isMuted, false);
      expect(model.queueEndBehavior, 0);
    });

    test('parses explainability payload from nested CAMS state block', () {
      final model = SpacePlaybackStateModel.fromJson({
        'spaceId': 'space-ai',
        'explainability': {
          'TriggeredRule': 'RULE_2_HEATWAVE',
          'Reason': 'Stress High and Density Crowded',
          'NewMood': 'Chill',
          'RecommendedBpmMin': 85,
          'RecommendedBpmMax': 105,
          'RecommendedBpmTarget': 94,
          'BpmFallback': true,
          'MoodOnlyCount': 12,
          'BpmFilteredCount': 6,
        },
      });

      expect(model.explainability, isNotNull);
      expect(model.explainability!.triggeredRule, 'RULE_2_HEATWAVE');
      expect(model.explainability!.reason, 'Stress High and Density Crowded');
      expect(model.explainability!.moodName, 'Chill');
      expect(model.explainability!.recommendedBpmMin, 85);
      expect(model.explainability!.recommendedBpmMax, 105);
      expect(model.explainability!.recommendedBpmTarget, 94);
      expect(model.explainability!.usedMoodOnlyFallback, isTrue);
      expect(model.explainability!.moodOnlyCount, 12);
      expect(model.explainability!.bpmFilteredCount, 6);
    });

    test('does not create explainability from legacy mood-only state', () {
      final model = SpacePlaybackStateModel.fromJson(const {
        'spaceId': 'space-1',
        'moodName': 'Focus',
      });

      expect(model.explainability, isNull);
    });
  });
}
