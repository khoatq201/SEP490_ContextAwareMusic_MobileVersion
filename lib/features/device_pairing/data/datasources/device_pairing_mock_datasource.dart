import 'dart:async';
import 'device_pairing_remote_datasource.dart';
import '../models/pairing_result_model.dart';
import '../../../../core/error/exceptions.dart';

class DevicePairingMockDataSource implements DevicePairingRemoteDataSource {
  @override
  Future<PairingResultModel> pairDevice(String pairCode) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (pairCode == '123456') {
      return const PairingResultModel(
        deviceId: 'dev-123',
        storeId: 'store-1',
        spaceId: 'space-1',
        storeName: 'Highlands Coffee',
        spaceName: 'Tầng 1',
      );
    }
    
    if (pairCode == '000000') {
      return const PairingResultModel(
        deviceId: 'dev-999',
        storeId: 'store-2',
        spaceId: 'space-2',
        storeName: 'The Coffee House',
        spaceName: 'Phòng Họp',
      );
    }

    throw ServerException('Invalid pairing code');
  }
}
