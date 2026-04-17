import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/config_governance/domain/entities/config_governance_enums.dart';
import 'package:cams_store_manager/features/config_governance/domain/entities/config_key_metadata.dart';

void main() {
  group('Config key metadata', () {
    test('returns friendly labels for known business config keys', () {
      expect(metadataForConfigKey('playback.baseVolume').label, 'Base Volume');
      expect(
        metadataForConfigKey('cams.aiQueueTrackLimit').description,
        contains('AI-selected tracks'),
      );
    });

    test('falls back safely for custom keys', () {
      final metadata = metadataForConfigKey('custom.experimentalFlag');

      expect(metadata.label, 'custom.experimentalFlag');
      expect(metadata.description, 'Custom config key.');
      expect(metadata.spaceBlocked, isFalse);
    });

    test('matches backend space-blocked rules', () {
      expect(
        isConfigKeySpaceBlocked('scheduling.slots', ConfigDomain.scheduling),
        isTrue,
      );
      expect(
        isConfigKeySpaceBlocked('governance.mode', ConfigDomain.governance),
        isTrue,
      );
      expect(
        isConfigKeySpaceBlocked('playback.baseVolume', ConfigDomain.playback),
        isFalse,
      );
    });

    test('matches backend brand and store blocked rules', () {
      expect(isConfigKeyBrandBlocked('governance.mode'), isTrue);
      expect(isConfigKeyStoreBlocked('governance.mode'), isTrue);
      expect(isConfigKeyBrandBlocked('playback.baseVolume'), isFalse);
      expect(isConfigKeyStoreBlocked('playback.baseVolume'), isFalse);
    });
  });
}
