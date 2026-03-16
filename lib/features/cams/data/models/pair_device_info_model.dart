import '../../domain/entities/pair_device_info.dart';

class PairDeviceInfoModel extends PairDeviceInfo {
  const PairDeviceInfoModel({
    required super.spaceId,
    required super.storeId,
    required super.brandId,
    super.deviceSessionId,
    super.isPlaybackDeviceCaller,
    super.manufacturer,
    super.model,
    super.osVersion,
    super.appVersion,
    super.deviceId,
    super.pairedAtUtc,
    super.lastActiveAtUtc,
  });

  factory PairDeviceInfoModel.fromJson(Map<String, dynamic> json) {
    return PairDeviceInfoModel(
      spaceId: json['spaceId'] as String,
      storeId: json['storeId'] as String,
      brandId: json['brandId'] as String,
      deviceSessionId: json['deviceSessionId'] as String?,
      isPlaybackDeviceCaller:
          json['isPlaybackDeviceCaller'] as bool? ?? false,
      manufacturer: json['manufacturer'] as String?,
      model: json['model'] as String?,
      osVersion: json['osVersion'] as String?,
      appVersion: json['appVersion'] as String?,
      deviceId: json['deviceId'] as String?,
      pairedAtUtc: json['pairedAtUtc'] != null
          ? DateTime.tryParse(json['pairedAtUtc'] as String)
          : null,
      lastActiveAtUtc: json['lastActiveAtUtc'] != null
          ? DateTime.tryParse(json['lastActiveAtUtc'] as String)
          : null,
    );
  }
}
