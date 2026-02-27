import 'package:equatable/equatable.dart';
import '../../domain/entities/pairing_result.dart';

enum DevicePairingStatus { initial, loading, success, failure }

class DevicePairingState extends Equatable {
  final DevicePairingStatus status;
  final String? errorMessage;
  final PairingResult? pairingResult;

  const DevicePairingState({
    this.status = DevicePairingStatus.initial,
    this.errorMessage,
    this.pairingResult,
  });

  DevicePairingState copyWith({
    DevicePairingStatus? status,
    String? errorMessage,
    PairingResult? pairingResult,
  }) {
    return DevicePairingState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      pairingResult: pairingResult ?? this.pairingResult,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, pairingResult];
}
