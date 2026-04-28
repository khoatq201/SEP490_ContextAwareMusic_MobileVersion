import '../../domain/entities/hub_device_location.dart';
import '../../domain/entities/space_hub_binding.dart';

class SpaceHubBindingModel extends SpaceHubBinding {
  const SpaceHubBindingModel({
    required super.spaceId,
    required super.bleDeviceName,
    required super.wifiSsid,
    required super.provisioningMethod,
    required super.provisionedAtUtc,
    required super.status,
    super.lastError,
    super.deviceLocation,
    super.deviceLocationStatus,
    super.deviceLocationLastError,
    super.deviceLocationUpdatedAtUtc,
  });

  factory SpaceHubBindingModel.fromJson(Map<String, dynamic> json) {
    return SpaceHubBindingModel(
      spaceId: json['spaceId']?.toString() ?? '',
      bleDeviceName: json['bleDeviceName']?.toString() ?? '',
      wifiSsid: json['wifiSsid']?.toString() ?? '',
      provisioningMethod: _readProvisioningMethod(
        json['provisioningMethod']?.toString(),
      ),
      provisionedAtUtc: DateTime.tryParse(
            json['provisionedAtUtc']?.toString() ?? '',
          )?.toUtc() ??
          DateTime.now().toUtc(),
      status: _readStatus(json['status']?.toString()),
      lastError: json['lastError']?.toString(),
      deviceLocation: _readDeviceLocation(json['deviceLocation']),
      deviceLocationStatus: _readDeviceLocationStatus(
        json['deviceLocationStatus']?.toString(),
        hasLocation: json['deviceLocation'] is Map<String, dynamic>,
      ),
      deviceLocationLastError: json['deviceLocationLastError']?.toString(),
      deviceLocationUpdatedAtUtc: DateTime.tryParse(
        json['deviceLocationUpdatedAtUtc']?.toString() ?? '',
      )?.toUtc(),
    );
  }

  factory SpaceHubBindingModel.fromEntity(SpaceHubBinding binding) {
    return SpaceHubBindingModel(
      spaceId: binding.spaceId,
      bleDeviceName: binding.bleDeviceName,
      wifiSsid: binding.wifiSsid,
      provisioningMethod: binding.provisioningMethod,
      provisionedAtUtc: binding.provisionedAtUtc,
      status: binding.status,
      lastError: binding.lastError,
      deviceLocation: binding.deviceLocation,
      deviceLocationStatus: binding.deviceLocationStatus,
      deviceLocationLastError: binding.deviceLocationLastError,
      deviceLocationUpdatedAtUtc: binding.deviceLocationUpdatedAtUtc,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spaceId': spaceId,
      'bleDeviceName': bleDeviceName,
      'wifiSsid': wifiSsid,
      'provisioningMethod': provisioningMethod.apiValue,
      'provisionedAtUtc': provisionedAtUtc.toUtc().toIso8601String(),
      'status': status.apiValue,
      'deviceLocationStatus': deviceLocationStatus.apiValue,
      if (deviceLocation != null) 'deviceLocation': deviceLocation!.toJson(),
      if (lastError != null && lastError!.trim().isNotEmpty)
        'lastError': lastError,
      if (deviceLocationLastError != null &&
          deviceLocationLastError!.trim().isNotEmpty)
        'deviceLocationLastError': deviceLocationLastError,
      if (deviceLocationUpdatedAtUtc != null)
        'deviceLocationUpdatedAtUtc':
            deviceLocationUpdatedAtUtc!.toUtc().toIso8601String(),
    };
  }

  static SpaceHubBindingStatus _readStatus(String? raw) {
    switch (raw) {
      case 'bound':
        return SpaceHubBindingStatus.bound;
      case 'syncPending':
        return SpaceHubBindingStatus.syncPending;
      case 'failed':
        return SpaceHubBindingStatus.failed;
      default:
        return SpaceHubBindingStatus.bound;
    }
  }

  static HubProvisioningMethod _readProvisioningMethod(String? raw) {
    switch (raw) {
      case 'blePrefixScan':
        return HubProvisioningMethod.blePrefixScan;
      case 'qrCode':
        return HubProvisioningMethod.qrCode;
      case 'backendInventory':
        return HubProvisioningMethod.backendInventory;
      default:
        return HubProvisioningMethod.blePrefixScan;
    }
  }

  static HubDeviceLocation? _readDeviceLocation(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return HubDeviceLocation.fromJson(raw);
    }
    if (raw is Map) {
      return HubDeviceLocation.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  static HubDeviceLocationStatus _readDeviceLocationStatus(
    String? raw, {
    required bool hasLocation,
  }) {
    switch (raw) {
      case 'configured':
        return HubDeviceLocationStatus.configured;
      case 'deviceSyncPending':
        return HubDeviceLocationStatus.deviceSyncPending;
      case 'unknown':
        return HubDeviceLocationStatus.unknown;
      default:
        return hasLocation
            ? HubDeviceLocationStatus.configured
            : HubDeviceLocationStatus.unknown;
    }
  }
}
