import 'package:equatable/equatable.dart';

abstract class DevicePairingEvent extends Equatable {
  const DevicePairingEvent();

  @override
  List<Object> get props => [];
}

class PairDeviceRequested extends DevicePairingEvent {
  final String pairCode;

  const PairDeviceRequested(this.pairCode);

  @override
  List<Object> get props => [pairCode];
}
