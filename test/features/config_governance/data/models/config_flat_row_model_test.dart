import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/config_governance/data/models/config_flat_row_model.dart';
import 'package:cams_store_manager/features/config_governance/domain/entities/config_governance_enums.dart';

void main() {
  group('ConfigFlatRowModel', () {
    test('parses the flat config row from backend payload', () {
      final model = ConfigFlatRowModel.fromJson(const {
        'key': 'playback.baseVolume',
        'domain': 2,
        'scopeType': 2,
        'scopeId': 'store-1',
        'valueType': 2,
        'value': '65',
        'policyTier': 1,
        'policyDefaultValueType': 2,
        'policyDefaultValue': '70',
        'allowStoreOverride': true,
        'allowSpaceOverride': true,
        'brandLockReason': null,
      });

      expect(model.key, 'playback.baseVolume');
      expect(model.domain, ConfigDomain.playback);
      expect(model.scopeType, ConfigScopeType.store);
      expect(model.scopeId, 'store-1');
      expect(model.valueType, ConfigValueType.number);
      expect(model.value, '65');
      expect(model.policyTier, ConfigTier.tenant);
      expect(model.policyDefaultValueType, ConfigValueType.number);
      expect(model.policyDefaultValue, '70');
      expect(model.allowStoreOverride, isTrue);
      expect(model.allowSpaceOverride, isTrue);
      expect(model.brandLockReason, isNull);
      expect(model.isSpaceOverrideAllowed, isTrue);
    });

    test('keeps override gate fields nullable when backend omits override row',
        () {
      final model = ConfigFlatRowModel.fromJson(const {
        'key': 'cams.aiQueueTrackLimit',
        'domain': 7,
        'scopeType': 3,
        'scopeId': 'space-1',
        'valueType': 2,
        'value': '12',
        'policyTier': 1,
        'policyDefaultValue': '10',
      });

      expect(model.domain, ConfigDomain.cams);
      expect(model.scopeType, ConfigScopeType.space);
      expect(model.policyDefaultValueType, isNull);
      expect(model.allowStoreOverride, isNull);
      expect(model.allowSpaceOverride, isNull);
      expect(model.hasBrandOverrideGate, isFalse);
      expect(model.isStoreOverrideAllowed, isFalse);
      expect(model.isSpaceOverrideAllowed, isFalse);
    });

    test('accepts PascalCase keys from SignalR or .NET serializers', () {
      final model = ConfigFlatRowModel.fromJson(const {
        'Key': 'content.enableAudioAds',
        'Domain': '4',
        'ScopeType': '1',
        'ValueType': '3',
        'PolicyTier': '1',
        'AllowStoreOverride': 'true',
        'AllowSpaceOverride': 'false',
        'BrandLockReason': 'Brand keeps ad policy locked',
      });

      expect(model.key, 'content.enableAudioAds');
      expect(model.domain, ConfigDomain.content);
      expect(model.scopeType, ConfigScopeType.brand);
      expect(model.valueType, ConfigValueType.boolean);
      expect(model.policyTier, ConfigTier.tenant);
      expect(model.allowStoreOverride, isTrue);
      expect(model.allowSpaceOverride, isFalse);
      expect(model.brandLockReason, 'Brand keeps ad policy locked');
    });
  });
}
