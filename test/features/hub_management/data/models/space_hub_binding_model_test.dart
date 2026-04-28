import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/hub_management/data/models/space_hub_binding_model.dart';
import 'package:cams_store_manager/features/hub_management/domain/entities/hub_device_location.dart';
import 'package:cams_store_manager/features/hub_management/domain/entities/space_hub_binding.dart';

void main() {
  group('SpaceHubBindingModel', () {
    test('serializes and restores nested device location fields', () {
      final capturedAtUtc = DateTime.parse('2026-04-04T10:05:00.000Z');
      final updatedAtUtc = DateTime.parse('2026-04-04T10:06:00.000Z');
      final model = SpaceHubBindingModel(
        spaceId: 'space-1',
        bleDeviceName: 'CAM-ESP32-01',
        wifiSsid: 'Store WiFi',
        provisioningMethod: HubProvisioningMethod.blePrefixScan,
        provisionedAtUtc: DateTime.parse('2026-04-04T10:00:00.000Z'),
        status: SpaceHubBindingStatus.syncPending,
        lastError: 'backend pending',
        deviceLocation: HubDeviceLocation(
          latitude: 10.7769,
          longitude: 106.7009,
          city: 'Ho Chi Minh City',
          source: HubDeviceLocationSource.phoneGps,
          capturedAtUtc: capturedAtUtc,
        ),
        deviceLocationStatus: HubDeviceLocationStatus.deviceSyncPending,
        deviceLocationLastError: 'custom-location failed',
        deviceLocationUpdatedAtUtc: updatedAtUtc,
      );

      final json = model.toJson();
      final restored = SpaceHubBindingModel.fromJson(json);

      expect(restored, model);
      expect(json['deviceLocationStatus'], 'deviceSyncPending');
      expect(json['deviceLocation'], {
        'lat': 10.7769,
        'lon': 106.7009,
        'city': 'Ho Chi Minh City',
        'source': 'phoneGps',
        'capturedAtUtc': capturedAtUtc.toIso8601String(),
      });
    });

    test('defaults location status to configured when old payload has location',
        () {
      final restored = SpaceHubBindingModel.fromJson(const {
        'spaceId': 'space-1',
        'bleDeviceName': 'CAM-ESP32-01',
        'wifiSsid': 'Store WiFi',
        'provisioningMethod': 'blePrefixScan',
        'provisionedAtUtc': '2026-04-04T10:00:00.000Z',
        'status': 'bound',
        'deviceLocation': {
          'lat': 10.7769,
          'lon': 106.7009,
          'city': 'Ho Chi Minh City',
          'source': 'manual',
          'capturedAtUtc': '2026-04-04T10:05:00.000Z',
        },
      });

      expect(restored.deviceLocationStatus, HubDeviceLocationStatus.configured);
      expect(restored.deviceLocation?.source, HubDeviceLocationSource.manual);
    });
  });
}
