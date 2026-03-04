import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/pairing_result_model.dart';
import 'device_pairing_remote_datasource.dart';

/// Real API implementation of [DevicePairingRemoteDataSource].
class DevicePairingRemoteDataSourceImpl
    implements DevicePairingRemoteDataSource {
  final DioClient dioClient;

  DevicePairingRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<PairingResultModel> pairDevice(String pairCode) async {
    try {
      final response = await dioClient.post(
        '/api/devices/pair',
        data: {'pairCode': pairCode},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return PairingResultModel.fromJson(
            data['data'] as Map<String, dynamic>);
      }
      return PairingResultModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException('Failed to pair device: $e');
    }
  }
}
