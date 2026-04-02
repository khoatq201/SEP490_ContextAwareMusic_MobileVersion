import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/enums/ai_generation_mode_enum.dart';
import 'package:cams_store_manager/features/suno/data/datasources/suno_remote_datasource.dart';

void main() {
  group('CreateSunoGenerationRequest', () {
    test('serializes optional mood and playlist fields when selected', () {
      const request = CreateSunoGenerationRequest(
        prompt: '  Bright cafe groove  ',
        title: ' Morning Spark ',
        artist: ' Suno ',
        moodId: ' mood-focus ',
        targetPlaylistId: ' playlist-123 ',
        autoAddToTargetPlaylist: true,
      );

      expect(request.toJson(), {
        'prompt': 'Bright cafe groove',
        'title': 'Morning Spark',
        'artist': 'Suno',
        'moodId': 'mood-focus',
        'targetPlaylistId': 'playlist-123',
        'autoAddToTargetPlaylist': true,
      });
    });

    test('omits blank optional title and uses backend defaults', () {
      const request = CreateSunoGenerationRequest(
        prompt: '   ',
        title: '   ',
        artist: '   ',
      );

      expect(request.toJson(), {
        'autoAddToTargetPlaylist': true,
      });
    });

    test('serializes advanced fuzzy and bpm options when selected', () {
      const request = CreateSunoGenerationRequest(
        prompt: 'evening lounge',
        aiGenerationMode: AiGenerationModeEnum.brandModel,
        fuzzyProfileTemplate: 'late-night-profile',
        recommendedBpmMin: 92,
        recommendedBpmMax: 110,
        recommendedBpmTarget: 101,
      );

      expect(request.toJson(), {
        'prompt': 'evening lounge',
        'aiGenerationMode': AiGenerationModeEnum.brandModel.value,
        'fuzzyProfileTemplate': 'late-night-profile',
        'recommendedBpmMin': 92,
        'bpmMin': 92,
        'recommendedBpmMax': 110,
        'bpmMax': 110,
        'recommendedBpmTarget': 101,
        'bpmTarget': 101,
        'autoAddToTargetPlaylist': true,
      });
    });
  });
}
