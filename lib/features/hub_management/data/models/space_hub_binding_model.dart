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
      if (lastError != null && lastError!.trim().isNotEmpty)
        'lastError': lastError,
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
}
