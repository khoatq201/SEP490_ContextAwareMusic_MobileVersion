import 'dart:async';
import 'device_pairing_remote_datasource.dart';
import '../models/pairing_result_model.dart';
import '../../../../core/error/exceptions.dart';

class DevicePairingMockDataSource implements DevicePairingRemoteDataSource {
  @override
  Future<PairingResultModel> pairDevice({
    required String code,
    String? manufacturer,
    String? model,
    String? osVersion,
    String? appVersion,
    String? deviceId,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (code == '123456' || code == 'ABC123') {
      return DeviceAuthSessionModel(
        deviceAccessToken: 'mock_device_access_token',
        deviceRefreshToken: 'mock_device_refresh_token',
        accessTokenExpiresAt: DateTime.now().toUtc().add(
              const Duration(minutes: 15),
            ),
        storeId: 'store-1',
        spaceId: 'space-1',
        storeName: 'Highlands Coffee',
        spaceName: 'Floor 1',
        deviceId: deviceId ?? 'dev-123',
        manufacturer: manufacturer ?? 'Samsung',
        model: model ?? 'SM-T510',
        osVersion: osVersion ?? 'Android 14',
        appVersion: appVersion ?? '1.0.0',
      );
    }

    if (code == '000000') {
      return DeviceAuthSessionModel(
        deviceAccessToken: 'mock_device_access_token_2',
        deviceRefreshToken: 'mock_device_refresh_token_2',
        accessTokenExpiresAt: DateTime.now().toUtc().add(
              const Duration(minutes: 15),
            ),
        storeId: 'store-2',
        spaceId: 'space-2',
        storeName: 'The Coffee House',
        spaceName: 'Meeting Room',
        deviceId: deviceId ?? 'dev-999',
        manufacturer: manufacturer ?? 'Lenovo',
        model: model ?? 'TB-8505F',
        osVersion: osVersion ?? 'Android 13',
        appVersion: appVersion ?? '1.0.0',
      );
    }

    throw ServerException('Invalid pairing code');
  }
}
