import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/pairing_result.dart';

enum DevicePairingStatus { initial, loading, success, failure }

class DevicePairingState extends Equatable {
  const DevicePairingState({
    this.status = DevicePairingStatus.initial,
    this.failure,
    this.pairingResult,
  });

  final DevicePairingStatus status;
  final Failure? failure;
  final PairingResult? pairingResult;

  String? get errorMessage => failure?.message;

  DevicePairingState copyWith({
    DevicePairingStatus? status,
    Failure? failure,
    bool clearFailure = false,
    PairingResult? pairingResult,
    bool clearPairingResult = false,
  }) {
    return DevicePairingState(
      status: status ?? this.status,
      failure: clearFailure ? null : (failure ?? this.failure),
      pairingResult:
          clearPairingResult ? null : (pairingResult ?? this.pairingResult),
    );
  }

  @override
  List<Object?> get props => [status, failure, pairingResult];
}
