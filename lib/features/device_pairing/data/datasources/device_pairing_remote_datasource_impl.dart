import '../../../../core/error/exceptions.dart';
import '../../../../core/models/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/pairing_result_model.dart';
import 'device_pairing_remote_datasource.dart';

/// Real API implementation of [DevicePairingRemoteDataSource].
class DevicePairingRemoteDataSourceImpl
    implements DevicePairingRemoteDataSource {
  final DioClient dioClient;

  DevicePairingRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<PairingResultModel> pairDevice({
    required String code,
    String? manufacturer,
    String? model,
    String? osVersion,
    String? appVersion,
    String? deviceId,
  }) async {
    try {
      final response = await dioClient.post(
        ApiConstants.authPair,
        data: {
          'code': code,
          if (manufacturer != null && manufacturer.isNotEmpty)
            'manufacturer': manufacturer,
          if (model != null && model.isNotEmpty) 'model': model,
          if (osVersion != null && osVersion.isNotEmpty)
            'osVersion': osVersion,
          if (appVersion != null && appVersion.isNotEmpty)
            'appVersion': appVersion,
          if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
        },
      );

      final apiResult = ApiResult<PairingResultModel>.fromJson(
        response.data as Map<String, dynamic>,
        fromData: (data) => PairingResultModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ).copyWith(
          deviceId: deviceId,
          manufacturer: manufacturer,
          model: model,
          osVersion: osVersion,
          appVersion: appVersion,
        ),
      );

      if (!apiResult.isSuccess || apiResult.data == null) {
        throw ServerException(apiResult.userFriendlyError);
      }

      return apiResult.data!;
    } catch (e) {
      throw ServerException('Failed to pair device: $e');
    }
  }
}
