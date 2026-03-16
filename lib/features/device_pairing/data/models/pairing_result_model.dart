import '../../domain/entities/pairing_result.dart';

/// Data model for the playback-device auth session.
class DeviceAuthSessionModel extends DeviceAuthSession {
  const DeviceAuthSessionModel({
    required super.deviceAccessToken,
    required super.deviceRefreshToken,
    required super.accessTokenExpiresAt,
    required super.storeId,
    required super.spaceId,
    required super.storeName,
    required super.spaceName,
    super.deviceId,
    super.manufacturer,
    super.model,
    super.osVersion,
    super.appVersion,
  });

  factory DeviceAuthSessionModel.fromJson(Map<String, dynamic> json) {
    return DeviceAuthSessionModel(
      deviceAccessToken: json['deviceAccessToken'] as String? ?? '',
      deviceRefreshToken: json['deviceRefreshToken'] as String? ?? '',
      accessTokenExpiresAt: DateTime.tryParse(
            json['accessTokenExpiresAt'] as String? ??
                json['expiresAt'] as String? ??
                '',
          ) ??
          DateTime.now().toUtc(),
      storeId: json['storeId'] as String? ?? '',
      spaceId: json['spaceId'] as String? ?? '',
      storeName: json['storeName'] as String? ?? 'Unknown Store',
      spaceName: json['spaceName'] as String? ?? 'Unknown Space',
      deviceId: json['deviceId'] as String?,
      manufacturer: json['manufacturer'] as String?,
      model: json['model'] as String?,
      osVersion: json['osVersion'] as String?,
      appVersion: json['appVersion'] as String?,
    );
  }

  DeviceAuthSessionModel copyWith({
    String? deviceAccessToken,
    String? deviceRefreshToken,
    DateTime? accessTokenExpiresAt,
    String? storeId,
    String? spaceId,
    String? storeName,
    String? spaceName,
    String? deviceId,
    String? manufacturer,
    String? model,
    String? osVersion,
    String? appVersion,
  }) {
    return DeviceAuthSessionModel(
      deviceAccessToken: deviceAccessToken ?? this.deviceAccessToken,
      deviceRefreshToken: deviceRefreshToken ?? this.deviceRefreshToken,
      accessTokenExpiresAt: accessTokenExpiresAt ?? this.accessTokenExpiresAt,
      storeId: storeId ?? this.storeId,
      spaceId: spaceId ?? this.spaceId,
      storeName: storeName ?? this.storeName,
      spaceName: spaceName ?? this.spaceName,
      deviceId: deviceId ?? this.deviceId,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceAccessToken': deviceAccessToken,
      'deviceRefreshToken': deviceRefreshToken,
      'accessTokenExpiresAt': accessTokenExpiresAt.toIso8601String(),
      'storeId': storeId,
      'spaceId': spaceId,
      'storeName': storeName,
      'spaceName': spaceName,
      'deviceId': deviceId,
      'manufacturer': manufacturer,
      'model': model,
      'osVersion': osVersion,
      'appVersion': appVersion,
    };
  }
}

typedef PairingResultModel = DeviceAuthSessionModel;
