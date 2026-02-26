import 'dart:async';
import '../models/pairing_result_model.dart';
import '../../../../core/error/exceptions.dart';

abstract class DevicePairingRemoteDataSource {
  /// Calls the pairing API endpoint.
  /// Throws a [ServerException] for all error codes.
  Future<PairingResultModel> pairDevice(String pairCode);
}
