import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/suno/data/models/suno_generation_model.dart';
import 'package:cams_store_manager/features/suno/domain/entities/suno_generation_status.dart';

void main() {
  group('SunoGenerationModel', () {
    test('parses generation payload from backend numeric enum contract', () {
      final model = SunoGenerationModel.fromJson(const {
        'id': 'gen-1',
        'brandId': 'brand-1',
        'generationStatus': 2,
        'progressPercent': 100,
        'errorMessage': null,
        'generatedTrackId': 'track-100',
        'externalTaskId': 'task-22',
        'outputAudioUrl': 'https://cdn.example.com/gen-1.wav',
        'prompt': 'warm jazz trio',
        'title': 'Late Night Espresso',
        'artist': 'Fuzzy AI',
        'moodId': 'mood-1',
        'targetPlaylistId': 'playlist-9',
        'autoAddToTargetPlaylist': true,
        'completedAtUtc': '2026-03-24T08:10:00Z',
        'lastPolledAtUtc': '2026-03-24T08:11:00Z',
      });

      expect(model.id, 'gen-1');
      expect(model.brandId, 'brand-1');
      expect(model.generationStatus, SunoGenerationStatus.completed);
      expect(model.progressPercent, 100);
      expect(model.generatedTrackId, 'track-100');
      expect(model.externalTaskId, 'task-22');
      expect(model.outputAudioUrl, 'https://cdn.example.com/gen-1.wav');
      expect(model.prompt, 'warm jazz trio');
      expect(model.title, 'Late Night Espresso');
      expect(model.artist, 'Fuzzy AI');
      expect(model.moodId, 'mood-1');
      expect(model.targetPlaylistId, 'playlist-9');
      expect(model.autoAddToTargetPlaylist, isTrue);
      expect(model.completedAtUtc, DateTime.parse('2026-03-24T08:10:00Z'));
      expect(model.lastPolledAtUtc, DateTime.parse('2026-03-24T08:11:00Z'));
    });

    test('falls back to unknown status for unsupported payloads', () {
      final model = SunoGenerationModel.fromJson(const {
        'id': 'gen-2',
        'generationStatus': 'mystery-state',
      });

      expect(model.generationStatus, SunoGenerationStatus.unknown);
      expect(model.autoAddToTargetPlaylist, isFalse);
    });
  });
}
