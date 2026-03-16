import 'dart:async';
import '../models/pairing_result_model.dart';
import '../../../../core/error/exceptions.dart';

abstract class DevicePairingRemoteDataSource {
  /// Calls the pairing API endpoint.
  /// Throws a [ServerException] for all error codes.
  Future<PairingResultModel> pairDevice({
    required String code,
    String? manufacturer,
    String? model,
    String? osVersion,
    String? appVersion,
    String? deviceId,
  });
}
