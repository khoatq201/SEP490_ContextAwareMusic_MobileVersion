import 'package:equatable/equatable.dart';

class BleCandidate extends Equatable {
  const BleCandidate({
    required this.bleDeviceName,
    String? displayName,
  }) : displayName = displayName ?? bleDeviceName;

  final String bleDeviceName;
  final String displayName;

  @override
  List<Object?> get props => [bleDeviceName, displayName];
}
