import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/pairing_result.dart';

/// Repository interface for pairing a playback device.
abstract class DevicePairingRepository {
  /// Pairs a device using the provided [pairCode] and returns a [PairingResult].
  Future<Either<Failure, PairingResult>> pairDevice(String pairCode);
}
