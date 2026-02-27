import 'package:equatable/equatable.dart';

/// The result returned when a playback device is successfully paired.
class PairingResult extends Equatable {
  final String deviceId;
  final String storeId;
  final String spaceId;
  final String storeName;
  final String spaceName;

  const PairingResult({
    required this.deviceId,
    required this.storeId,
    required this.spaceId,
    required this.storeName,
    required this.spaceName,
  });

  @override
  List<Object?> get props => [
        deviceId,
        storeId,
        spaceId,
        storeName,
        spaceName,
      ];
}
