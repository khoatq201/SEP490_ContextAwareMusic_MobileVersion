import 'package:equatable/equatable.dart';

import 'hub_device_location.dart';

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

enum HubDeviceLocationStatus {
  unknown,
  configured,
  deviceSyncPending,
}

extension HubDeviceLocationStatusX on HubDeviceLocationStatus {
  String get apiValue {
    switch (this) {
      case HubDeviceLocationStatus.unknown:
        return 'unknown';
      case HubDeviceLocationStatus.configured:
        return 'configured';
      case HubDeviceLocationStatus.deviceSyncPending:
        return 'deviceSyncPending';
    }
  }

  String get displayLabel {
    switch (this) {
      case HubDeviceLocationStatus.unknown:
        return 'Not configured';
      case HubDeviceLocationStatus.configured:
        return 'Configured';
      case HubDeviceLocationStatus.deviceSyncPending:
        return 'Device sync pending';
    }
  }

  bool get isConfigured => this == HubDeviceLocationStatus.configured;

  bool get isPending => this == HubDeviceLocationStatus.deviceSyncPending;
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
    this.deviceLocation,
    this.deviceLocationStatus = HubDeviceLocationStatus.unknown,
    this.deviceLocationLastError,
    this.deviceLocationUpdatedAtUtc,
  });

  final String spaceId;
  final String bleDeviceName;
  final String wifiSsid;
  final HubProvisioningMethod provisioningMethod;
  final DateTime provisionedAtUtc;
  final SpaceHubBindingStatus status;
  final String? lastError;
  final HubDeviceLocation? deviceLocation;
  final HubDeviceLocationStatus deviceLocationStatus;
  final String? deviceLocationLastError;
  final DateTime? deviceLocationUpdatedAtUtc;

  SpaceHubBinding copyWith({
    String? spaceId,
    String? bleDeviceName,
    String? wifiSsid,
    HubProvisioningMethod? provisioningMethod,
    DateTime? provisionedAtUtc,
    SpaceHubBindingStatus? status,
    String? lastError,
    HubDeviceLocation? deviceLocation,
    bool clearDeviceLocation = false,
    HubDeviceLocationStatus? deviceLocationStatus,
    String? deviceLocationLastError,
    bool clearDeviceLocationLastError = false,
    DateTime? deviceLocationUpdatedAtUtc,
    bool clearDeviceLocationUpdatedAtUtc = false,
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
      deviceLocation:
          clearDeviceLocation ? null : (deviceLocation ?? this.deviceLocation),
      deviceLocationStatus: deviceLocationStatus ?? this.deviceLocationStatus,
      deviceLocationLastError: clearDeviceLocationLastError
          ? null
          : (deviceLocationLastError ?? this.deviceLocationLastError),
      deviceLocationUpdatedAtUtc: clearDeviceLocationUpdatedAtUtc
          ? null
          : (deviceLocationUpdatedAtUtc ?? this.deviceLocationUpdatedAtUtc),
    );
  }

  bool get isBound => status == SpaceHubBindingStatus.bound;
  bool get isSyncPending => status == SpaceHubBindingStatus.syncPending;
  bool get hasFailure => status == SpaceHubBindingStatus.failed;
  bool get hasConfiguredDeviceLocation => deviceLocation != null;
  bool get isDeviceLocationConfigured => deviceLocationStatus.isConfigured;
  bool get isDeviceLocationSyncPending => deviceLocationStatus.isPending;

  @override
  List<Object?> get props => [
        spaceId,
        bleDeviceName,
        wifiSsid,
        provisioningMethod,
        provisionedAtUtc,
        status,
        lastError,
        deviceLocation,
        deviceLocationStatus,
        deviceLocationLastError,
        deviceLocationUpdatedAtUtc,
      ];
}
