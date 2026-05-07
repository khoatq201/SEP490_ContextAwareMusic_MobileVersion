import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/enums/scheduling_slot_origin_enum.dart';
import 'package:cams_store_manager/features/cams/data/models/space_playback_state_model.dart';
import 'package:cams_store_manager/features/config_governance/domain/entities/config_governance_enums.dart';

void main() {
  group('SpacePlaybackStateModel', () {
    test('parses queue-first payload and prefers new fields in mixed schema',
        () {
      final model = SpacePlaybackStateModel.fromJson(const {
        'spaceId': 'space-1',
        'currentQueueItemId': 'queue-new',
        'currentTrackName': 'New Track',
        'currentPlaylistId': 'playlist-legacy',
        'currentPlaylistName': 'Legacy Playlist Name',
        'hlsUrl': 'https://example.com/stream.m3u8',
        'pendingQueueItemId': 'pending-new',
        'pendingPlaylistId': 'pending-legacy',
        'volumePercent': 65,
        'isIotDeviceAssigned': true,
        'isIotDeviceOffline': true,
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
            'coverImageUrl': 'https://example.com/cover.jpg',
            'isReadyToStream': true,
          }
        ],
      });

      expect(model.currentQueueItemId, 'queue-new');
      expect(model.currentTrackName, 'New Track');
      expect(model.pendingQueueItemId, 'pending-new');
      expect(model.currentPlaylistId, 'playlist-legacy');
      expect(model.volumePercent, 65);
      expect(model.isIotDeviceAssigned, true);
      expect(model.isIotDeviceOffline, true);
      expect(model.iotStatusLabel, 'IoT Offline');
      expect(model.isMuted, true);
      expect(model.queueEndBehavior, 2);
      expect(model.spaceQueueItems, hasLength(1));
      expect(model.spaceQueueItems.single.coverImageUrl,
          'https://example.com/cover.jpg');
      expect(model.isStreaming, true);
    });

    test('parses governance mode aliases from space state payload', () {
      final strict = SpacePlaybackStateModel.fromJson(const {
        'spaceId': 'space-strict',
        'governanceMode': 'StrictSync',
      });
      final freedom = SpacePlaybackStateModel.fromJson(const {
        'spaceId': 'space-freedom',
        'governentMode': 3,
      });
      final aiMode = SpacePlaybackStateModel.fromJson(const {
        'spaceId': 'space-ai',
        'governmentMode': 'AI Mode',
      });

      expect(strict.governanceMode, StoreGovernanceMode.strictSync);
      expect(freedom.governanceMode, StoreGovernanceMode.freedom);
      expect(aiMode.governanceMode, StoreGovernanceMode.aiMode);
    });

    test('parses legacy playlist-centric payload with queue-field fallback',
        () {
      final model = SpacePlaybackStateModel.fromJson(const {
        'spaceId': 'space-legacy',
        'currentPlaylistId': 'playlist-1',
        'currentPlaylistName': 'Legacy Playlist',
        'pendingPlaylistId': 'playlist-pending',
      });

      expect(model.currentQueueItemId, 'playlist-1');
      expect(model.currentTrackName, 'Legacy Playlist');
      expect(model.pendingQueueItemId, 'playlist-pending');
      expect(model.volumePercent, 100);
      expect(model.isIotDeviceAssigned, isNull);
      expect(model.isIotDeviceOffline, false);
      expect(model.isMuted, false);
      expect(model.queueEndBehavior, 0);
    });

    test('parses explainability payload from nested CAMS state block', () {
      final model = SpacePlaybackStateModel.fromJson(const {
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

    test('parses IoT assignment state labels', () {
      final unassigned = SpacePlaybackStateModel.fromJson(const {
        'spaceId': 'space-iot-unassigned',
        'isIotDeviceAssigned': false,
        'isIotDeviceOffline': false,
      });
      final online = SpacePlaybackStateModel.fromJson(const {
        'spaceId': 'space-iot-online',
        'isIotDeviceAssigned': true,
        'isIotDeviceOffline': false,
      });

      expect(unassigned.iotStatusLabel, 'IoT Unassigned');
      expect(unassigned.hasIotWarning, isTrue);
      expect(online.iotStatusLabel, 'IoT Online');
      expect(online.hasIotWarning, isFalse);
    });

    test('parses manual override, scheduling, and AI trace aliases', () {
      final model = SpacePlaybackStateModel.fromJson(const {
        'spaceId': 'space-runtime',
        'isManualOverride': true,
        'overrideReason': 'Manager takeover',
        'manualOverrideActivatedAtUtc': '2026-04-17T08:00:00Z',
        'manualOverrideExpiresAtUtc': '2026-04-17T08:30:00Z',
        'manualOverrideTtlSeconds': 1800,
        'manualOverrideRemainingSeconds': 1200,
        'isScheduling': true,
        'schedulingSlotId': 'slot-1',
        'schedulingSlotOrigin': 2,
        'schedulingEndsAtUtc': '2026-04-17T09:00:00Z',
        'schedulingRemainingSeconds': 2400,
        'aiTrace': {
          'fuzzyRule': 'BRAND_SLOT_RULE',
          'fuzzyReason': 'Brand schedule selected the slot',
          'bpmMin': 90,
          'bpmMax': 110,
          'bpmTarget': 100,
          'isBpmFallback': false,
        },
      });

      expect(model.overrideReason, 'Manager takeover');
      expect(model.manualOverrideTtlSeconds, 1800);
      expect(model.manualOverrideRemainingSeconds, 1200);
      expect(model.isScheduling, isTrue);
      expect(model.schedulingSlotId, 'slot-1');
      expect(model.schedulingSlotOrigin, SchedulingSlotOriginEnum.brand);
      expect(model.schedulingRemainingSeconds, 2400);
      expect(model.explainability, isNotNull);
      expect(model.explainability!.triggeredRule, 'BRAND_SLOT_RULE');
      expect(model.explainability!.reason, 'Brand schedule selected the slot');
      expect(model.explainability!.recommendedBpmMin, 90);
      expect(model.explainability!.recommendedBpmMax, 110);
      expect(model.explainability!.recommendedBpmTarget, 100);
      expect(model.explainability!.usedMoodOnlyFallback, isFalse);
    });

    test('parses fuzzy confidence and score breakdown with signal impacts', () {
      final model = SpacePlaybackStateModel.fromJson(const {
        'spaceId': 'space-ai-score',
        'fuzzyConfidence': 0.17,
        'fuzzyScoreBreakdown': {
          'chillScore': 0.33,
          'focusScore': 0.40,
          'energeticScore': 0.28,
          'signalContributions': [
            {
              'signal': 'crowdPressure(people=1, level=Low)',
              'chillDelta': 0.04,
              'focusDelta': 0.18,
              'energeticDelta': -0.06,
            },
          ],
        },
      });

      final explainability = model.explainability;
      expect(explainability, isNotNull);
      expect(explainability!.confidence, 0.17);
      expect(explainability.scoreBreakdown, isNotNull);
      expect(explainability.scoreBreakdown!.chillScore, 0.33);
      expect(explainability.scoreBreakdown!.focusScore, 0.40);
      expect(explainability.scoreBreakdown!.energeticScore, 0.28);
      expect(explainability.signalContributions, hasLength(1));
      expect(
        explainability.signalContributions.single.signal,
        'crowdPressure(people=1, level=Low)',
      );
      expect(explainability.signalContributions.single.focusDelta, 0.18);
      expect(explainability.signalContributions.single.energeticDelta, -0.06);
    });

    test('parses snake case fuzzy score aliases', () {
      final model = SpacePlaybackStateModel.fromJson(const {
        'spaceId': 'space-ai-snake',
        'fuzzy_confidence': 62,
        'fuzzy_score_breakdown': {
          'chill_score': 33,
          'focus_score': 40,
          'energetic_score': 28,
          'signal_contributions': [
            {
              'signal': 'ambientNoise(dB=60.0, level=Moderate)',
              'chill_delta': 0.03,
              'focus_delta': 0.06,
              'energetic_delta': 0.01,
            },
          ],
        },
      });

      final explainability = model.explainability;
      expect(explainability, isNotNull);
      expect(explainability!.confidence, 62);
      expect(explainability.scoreBreakdown!.chillScore, 33);
      expect(explainability.scoreBreakdown!.focusScore, 40);
      expect(explainability.scoreBreakdown!.energeticScore, 28);
      expect(explainability.signalContributions.single.signal,
          'ambientNoise(dB=60.0, level=Moderate)');
      expect(explainability.signalContributions.single.chillDelta, 0.03);
    });

    test('parses fuzzy score JSON string and ignores invalid JSON safely', () {
      final jsonBacked = SpacePlaybackStateModel.fromJson(const {
        'spaceId': 'space-ai-json',
        'fuzzyScoreJson':
            '{"chill_score":0.2,"focus_score":0.7,"energetic_score":0.1,"signals":["timeOfDay(local=18:31)"]}',
      });

      expect(jsonBacked.explainability, isNotNull);
      expect(jsonBacked.explainability!.scoreBreakdown!.focusScore, 0.7);
      expect(
        jsonBacked.explainability!.signalContributions.single.signal,
        'timeOfDay(local=18:31)',
      );

      final invalid = SpacePlaybackStateModel.fromJson(const {
        'spaceId': 'space-ai-invalid-json',
        'fuzzyScoreJson': '{not-json',
      });

      expect(invalid.explainability, isNull);
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
