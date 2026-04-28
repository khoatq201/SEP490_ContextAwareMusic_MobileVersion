import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/enums/ai_generation_mode_enum.dart';
import 'package:cams_store_manager/core/enums/store_fuzzy_override_level_enum.dart';
import 'package:cams_store_manager/features/suno/data/models/suno_config_model.dart';

void main() {
  group('SunoConfigModel', () {
    test('parses config payload and serializes back to json', () {
      final model = SunoConfigModel.fromJson(const {
        'brandId': 'brand-7',
        'sunoPromptTemplate': 'Make it airy and bright',
        'sunoDefaultPlaylistId': 'playlist-123',
        'generationMode': 'BrandModel',
        'availableAiGenerationModes': [0, 1],
        'defaultFuzzyProfileTemplate': 'coffee-house',
        'availableFuzzyProfileTemplates': ['coffee-house', 'rush-hour'],
        'defaultRecommendedBpmMin': 90,
        'defaultRecommendedBpmMax': 118,
        'defaultRecommendedBpmTarget': 104,
        'storeOverrideLevel': 'Custom',
      });

      expect(model.brandId, 'brand-7');
      expect(model.sunoPromptTemplate, 'Make it airy and bright');
      expect(model.sunoDefaultPlaylistId, 'playlist-123');
      expect(model.aiGenerationMode, AiGenerationModeEnum.brandModel);
      expect(model.availableGenerationModes, [
        AiGenerationModeEnum.suno,
        AiGenerationModeEnum.brandModel,
      ]);
      expect(model.fuzzyProfileTemplate, 'coffee-house');
      expect(model.availableFuzzyProfileTemplates, [
        'coffee-house',
        'rush-hour',
      ]);
      expect(model.recommendedBpmMin, 90);
      expect(model.recommendedBpmMax, 118);
      expect(model.recommendedBpmTarget, 104);
      expect(model.fuzzyOverrideLevel, StoreFuzzyOverrideLevelEnum.custom);
      expect(model.toJson(), {
        'brandId': 'brand-7',
        'sunoPromptTemplate': 'Make it airy and bright',
        'sunoDefaultPlaylistId': 'playlist-123',
        'aiGenerationMode': AiGenerationModeEnum.brandModel.value,
        'fuzzyProfileTemplate': 'coffee-house',
        'recommendedBpmMin': 90,
        'recommendedBpmMax': 118,
        'recommendedBpmTarget': 104,
        'fuzzyOverrideLevel': 'Custom',
      });
    });
  });
}
