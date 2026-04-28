import 'package:equatable/equatable.dart';

/// Auth/session payload returned when a playback device is successfully paired.
class DeviceAuthSession extends Equatable {
  final String deviceAccessToken;
  final String deviceRefreshToken;
  final DateTime accessTokenExpiresAt;
  final String brandId;
  final String storeId;
  final String spaceId;
  final String storeName;
  final String spaceName;
  final String? deviceId;
  final String? manufacturer;
  final String? model;
  final String? osVersion;
  final String? appVersion;

  const DeviceAuthSession({
    required this.deviceAccessToken,
    required this.deviceRefreshToken,
    required this.accessTokenExpiresAt,
    required this.brandId,
    required this.storeId,
    required this.spaceId,
    required this.storeName,
    required this.spaceName,
    this.deviceId,
    this.manufacturer,
    this.model,
    this.osVersion,
    this.appVersion,
  });

  String get pairedDeviceId => deviceId ?? spaceId;

  @override
  List<Object?> get props => [
        deviceAccessToken,
        deviceRefreshToken,
        accessTokenExpiresAt,
        brandId,
        storeId,
        spaceId,
        storeName,
        spaceName,
        deviceId,
        manufacturer,
        model,
        osVersion,
        appVersion,
      ];
}

typedef PairingResult = DeviceAuthSession;
