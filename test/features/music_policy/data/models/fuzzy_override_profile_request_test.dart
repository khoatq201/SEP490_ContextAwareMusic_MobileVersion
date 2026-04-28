import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/music_policy/data/models/fuzzy_override_profile_request.dart';
import 'package:cams_store_manager/features/music_policy/data/models/fuzzy_override_summary_model.dart';

void main() {
  group('FuzzyOverrideProfileRequest', () {
    test('serializes only populated override fields', () {
      const request = FuzzyOverrideProfileRequest(
        name: ' Lunch Rush ',
        chillBpmMin: 82,
        focusBpmMax: 112,
        pressureCriticalMin: 0.75,
        defaultDensityRatioWhenNull: 0.45,
        allowedPlaylistIds: ['playlist-1', 'playlist-2'],
      );

      expect(request.toJson(), {
        'name': 'Lunch Rush',
        'chillBpmMin': 82,
        'focusBpmMax': 112,
        'pressureCriticalMin': 0.75,
        'defaultDensityRatioWhenNull': 0.45,
        'allowedPlaylistIds': ['playlist-1', 'playlist-2'],
      });
    });
  });

  group('FuzzyOverrideSummaryModel', () {
    test('reads nested summary from store or space payload', () {
      final summary = FuzzyOverrideSummaryModel.fromRootJson(const {
        'brandMusicPolicy': {
          'activeFuzzyMusicProfileId': 'profile-1',
          'activeFuzzyMusicProfileName': 'Lunch Rush',
          'fuzzyProfileTemplate': 'coffee-house',
          'aiGenerationMode': 'BrandModel',
          'overrideLevel': 'Custom',
          'allowedPlaylistIds': ['playlist-1'],
          'restrictedToAllowedPlaylists': true,
        },
      });

      expect(summary, isNotNull);
      expect(summary!.profileId, 'profile-1');
      expect(summary.name, 'Lunch Rush');
      expect(summary.templateName, 'coffee-house');
      expect(summary.playlistSummary, '1 allowed playlist');
    });
  });
}
