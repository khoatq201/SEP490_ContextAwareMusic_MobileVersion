import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/pairing_result.dart';

/// Repository interface for pairing a playback device.
abstract class DevicePairingRepository {
  /// Pairs a device using the provided pairing payload and returns a device session.
  Future<Either<Failure, DeviceAuthSession>> pairDevice({
    required String code,
    String? manufacturer,
    String? model,
    String? osVersion,
    String? appVersion,
    String? deviceId,
  });
}
