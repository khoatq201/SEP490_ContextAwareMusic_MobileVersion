import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/device_pairing/data/models/pairing_result_model.dart';

void main() {
  group('DeviceAuthSessionModel', () {
    test('parses brand scope and falls back to safe placeholder names', () {
      final model = DeviceAuthSessionModel.fromJson(const {
        'deviceAccessToken': 'access-token',
        'deviceRefreshToken': 'refresh-token',
        'accessTokenExpiresAt': '2026-03-24T12:00:00Z',
        'brandId': 'brand-1',
        'storeId': 'store-1',
        'spaceId': 'space-1',
      });

      expect(model.brandId, 'brand-1');
      expect(model.storeId, 'store-1');
      expect(model.spaceId, 'space-1');
      expect(model.storeName, 'Paired Store');
      expect(model.spaceName, 'Paired Space');
      expect(model.pairedDeviceId, 'space-1');
    });

    test('serializes hydrated session back to json', () {
      final model = DeviceAuthSessionModel(
        deviceAccessToken: 'access-token',
        deviceRefreshToken: 'refresh-token',
        accessTokenExpiresAt: DateTime.parse('2026-03-24T12:00:00Z'),
        brandId: 'brand-2',
        storeId: 'store-2',
        spaceId: 'space-2',
        storeName: 'Cafe Bloom',
        spaceName: 'Main Hall',
        deviceId: 'device-2',
      );

      expect(model.toJson(), {
        'deviceAccessToken': 'access-token',
        'deviceRefreshToken': 'refresh-token',
        'accessTokenExpiresAt': '2026-03-24T12:00:00.000Z',
        'brandId': 'brand-2',
        'storeId': 'store-2',
        'spaceId': 'space-2',
        'storeName': 'Cafe Bloom',
        'spaceName': 'Main Hall',
        'deviceId': 'device-2',
        'manufacturer': null,
        'model': null,
        'osVersion': null,
        'appVersion': null,
      });
    });
  });
}
