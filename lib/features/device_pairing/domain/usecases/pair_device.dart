import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/pairing_result.dart';
import '../repositories/device_pairing_repository.dart';

/// Use case to pair a playback device.
class PairDevice {
  final DevicePairingRepository repository;

  PairDevice(this.repository);

  Future<Either<Failure, DeviceAuthSession>> call({
    required String code,
    String? manufacturer,
    String? model,
    String? osVersion,
    String? appVersion,
    String? deviceId,
  }) {
    if (code.trim().isEmpty) {
      return Future.value(
          const Left(ValidationFailure('Pair code cannot be empty')));
    }
    return repository.pairDevice(
      code: code.trim(),
      manufacturer: manufacturer,
      model: model,
      osVersion: osVersion,
      appVersion: appVersion,
      deviceId: deviceId,
    );
  }
}
