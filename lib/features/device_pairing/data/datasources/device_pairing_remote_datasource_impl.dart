import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/models/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../models/pairing_result_model.dart';
import 'device_pairing_remote_datasource.dart';

class DevicePairingRemoteDataSourceImpl
    implements DevicePairingRemoteDataSource {
  DevicePairingRemoteDataSourceImpl({required this.dioClient});

  final DioClient dioClient;

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
          if (osVersion != null && osVersion.isNotEmpty) 'osVersion': osVersion,
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
        throw ErrorMapper.fromApiErrorDetails(
          apiResult.errorDetails,
          fallbackMessage: 'Pairing failed. Please check the code and try again.',
        );
      }

      return apiResult.data!;
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(
        error,
        fallbackMessage: 'Pairing failed. Please check the code and try again.',
      );
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      throw ErrorMapper.toException(
        error,
        fallbackMessage: 'We could not pair this device right now.',
        stackTrace: stackTrace,
      );
    }
  }
}
