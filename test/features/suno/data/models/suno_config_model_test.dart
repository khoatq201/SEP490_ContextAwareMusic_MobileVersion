import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/suno/data/models/suno_config_model.dart';

void main() {
  group('SunoConfigModel', () {
    test('parses config payload and serializes back to json', () {
      final model = SunoConfigModel.fromJson(const {
        'brandId': 'brand-7',
        'sunoPromptTemplate': 'Make it airy and bright',
        'sunoDefaultPlaylistId': 'playlist-123',
      });

      expect(model.brandId, 'brand-7');
      expect(model.sunoPromptTemplate, 'Make it airy and bright');
      expect(model.sunoDefaultPlaylistId, 'playlist-123');
      expect(model.toJson(), {
        'brandId': 'brand-7',
        'sunoPromptTemplate': 'Make it airy and bright',
        'sunoDefaultPlaylistId': 'playlist-123',
      });
    });
  });
}
