import 'package:equatable/equatable.dart';

abstract class DevicePairingEvent extends Equatable {
  const DevicePairingEvent();

  @override
  List<Object?> get props => [];
}

class PairDeviceRequested extends DevicePairingEvent {
  final String code;
  final String? manufacturer;
  final String? model;
  final String? osVersion;
  final String? appVersion;
  final String? deviceId;

  const PairDeviceRequested({
    required this.code,
    this.manufacturer,
    this.model,
    this.osVersion,
    this.appVersion,
    this.deviceId,
  });

  @override
  List<Object?> get props => [
        code,
        manufacturer,
        model,
        osVersion,
        appVersion,
        deviceId,
      ];
}
