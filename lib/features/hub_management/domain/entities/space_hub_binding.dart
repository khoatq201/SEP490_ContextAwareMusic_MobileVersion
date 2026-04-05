import 'package:equatable/equatable.dart';

enum SpaceHubBindingStatus {
  bound,
  syncPending,
  failed,
}

extension SpaceHubBindingStatusX on SpaceHubBindingStatus {
  String get apiValue {
    switch (this) {
      case SpaceHubBindingStatus.bound:
        return 'bound';
      case SpaceHubBindingStatus.syncPending:
        return 'syncPending';
      case SpaceHubBindingStatus.failed:
        return 'failed';
    }
  }

  String get displayLabel {
    switch (this) {
      case SpaceHubBindingStatus.bound:
        return 'Bound';
      case SpaceHubBindingStatus.syncPending:
        return 'Sync pending';
      case SpaceHubBindingStatus.failed:
        return 'Attention needed';
    }
  }
}

enum HubProvisioningMethod {
  blePrefixScan,
  qrCode,
  backendInventory,
}

extension HubProvisioningMethodX on HubProvisioningMethod {
  String get apiValue {
    switch (this) {
      case HubProvisioningMethod.blePrefixScan:
        return 'blePrefixScan';
      case HubProvisioningMethod.qrCode:
        return 'qrCode';
      case HubProvisioningMethod.backendInventory:
        return 'backendInventory';
    }
  }
}

class SpaceHubBinding extends Equatable {
  const SpaceHubBinding({
    required this.spaceId,
    required this.bleDeviceName,
    required this.wifiSsid,
    required this.provisioningMethod,
    required this.provisionedAtUtc,
    required this.status,
    this.lastError,
  });

  final String spaceId;
  final String bleDeviceName;
  final String wifiSsid;
  final HubProvisioningMethod provisioningMethod;
  final DateTime provisionedAtUtc;
  final SpaceHubBindingStatus status;
  final String? lastError;

  SpaceHubBinding copyWith({
    String? spaceId,
    String? bleDeviceName,
    String? wifiSsid,
    HubProvisioningMethod? provisioningMethod,
    DateTime? provisionedAtUtc,
    SpaceHubBindingStatus? status,
    String? lastError,
    bool clearLastError = false,
  }) {
    return SpaceHubBinding(
      spaceId: spaceId ?? this.spaceId,
      bleDeviceName: bleDeviceName ?? this.bleDeviceName,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      provisioningMethod: provisioningMethod ?? this.provisioningMethod,
      provisionedAtUtc: provisionedAtUtc ?? this.provisionedAtUtc,
      status: status ?? this.status,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }

  bool get isBound => status == SpaceHubBindingStatus.bound;
  bool get isSyncPending => status == SpaceHubBindingStatus.syncPending;
  bool get hasFailure => status == SpaceHubBindingStatus.failed;

  @override
  List<Object?> get props => [
        spaceId,
        bleDeviceName,
        wifiSsid,
        provisioningMethod,
        provisionedAtUtc,
        status,
        lastError,
      ];
}
