import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/hub_management/data/services/provisioning_identity_resolver.dart';
import 'package:cams_store_manager/features/hub_management/domain/entities/ble_candidate.dart';
import 'package:cams_store_manager/features/hub_management/domain/entities/esp_provisioning_identity.dart';

void main() {
  group('PrefixProvisioningIdentityResolver', () {
    test('exposes the configured BLE prefix', () {
      const resolver = PrefixProvisioningIdentityResolver(blePrefix: 'CAM');

      expect(resolver.blePrefix, 'CAM');
    });

    test('resolves a BLE candidate with the provided secret code', () async {
      const resolver = PrefixProvisioningIdentityResolver(blePrefix: 'CAM');
      const candidate = BleCandidate(bleDeviceName: 'CAM-ESP32-01');

      final identity = await resolver.resolve(
        candidate,
        proofOfPossession: 'shared-pop',
      );

      expect(
        identity,
        const EspProvisioningIdentity(
          blePrefix: 'CAM',
          bleDeviceName: 'CAM-ESP32-01',
          deviceId: 'cam_esp32_01',
          proofOfPossession: 'shared-pop',
          source: EspProvisioningIdentitySource.blePrefixScan,
        ),
      );
    });
  });
}
