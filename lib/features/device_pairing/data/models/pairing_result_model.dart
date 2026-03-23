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
    final parsedExpiry = _parseDateTime(
      json['accessTokenExpiresAt'] ??
          json['expiresAt'] ??
          json['deviceAccessTokenExpiresAt'],
    );

    return DeviceAuthSessionModel(
      deviceAccessToken:
          (json['deviceAccessToken'] ?? json['accessToken'])?.toString() ?? '',
      deviceRefreshToken:
          (json['deviceRefreshToken'] ?? json['refreshToken'])?.toString() ??
              '',
      accessTokenExpiresAt: parsedExpiry ??
          DateTime.now().toUtc().add(const Duration(minutes: 10)),
      storeId: json['storeId']?.toString() ?? '',
      spaceId: json['spaceId']?.toString() ?? '',
      storeName: json['storeName']?.toString() ?? 'Unknown Store',
      spaceName: json['spaceName']?.toString() ?? 'Unknown Space',
      deviceId: json['deviceId']?.toString(),
      manufacturer: json['manufacturer']?.toString(),
      model: json['model']?.toString(),
      osVersion: json['osVersion']?.toString(),
      appVersion: json['appVersion']?.toString(),
    );
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toUtc();
    return DateTime.tryParse(raw.toString())?.toUtc();
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
