import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/pairing_result.dart';
import '../repositories/device_pairing_repository.dart';

/// Use case to pair a playback device.
class PairDevice {
  final DevicePairingRepository repository;

  PairDevice(this.repository);

  Future<Either<Failure, PairingResult>> call(String pairCode) {
    if (pairCode.trim().isEmpty) {
      return Future.value(const Left(ValidationFailure('Pair code cannot be empty')));
    }
    return repository.pairDevice(pairCode.trim());
  }
}
