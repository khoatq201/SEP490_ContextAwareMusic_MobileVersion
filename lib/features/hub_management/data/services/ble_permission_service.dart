import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum BlePermissionRequirementStatus {
  granted,
  denied,
  permanentlyDenied,
  unsupported,
}

abstract class BlePermissionService {
  Future<BlePermissionRequirementStatus> checkStatus();

  Future<BlePermissionRequirementStatus> requestPermissions();

  Future<bool> openSettings();
}

class PermissionHandlerBlePermissionService implements BlePermissionService {
  PermissionHandlerBlePermissionService({
    DeviceInfoPlugin? deviceInfo,
  }) : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _deviceInfo;

  @override
  Future<BlePermissionRequirementStatus> checkStatus() async {
    final permissions = await _requiredPermissions();
    if (permissions.isEmpty) return BlePermissionRequirementStatus.unsupported;

    final statuses = await Future.wait(
      permissions.map((permission) => permission.status),
    );
    return _mapStatuses(statuses);
  }

  @override
  Future<BlePermissionRequirementStatus> requestPermissions() async {
    final permissions = await _requiredPermissions();
    if (permissions.isEmpty) return BlePermissionRequirementStatus.unsupported;

    final statuses = await permissions.request();
    return _mapStatuses(statuses.values);
  }

  @override
  Future<bool> openSettings() => openAppSettings();

  Future<List<Permission>> _requiredPermissions() async {
    if (!Platform.isAndroid) {
      return const <Permission>[];
    }

    final androidInfo = await _deviceInfo.androidInfo;
    if (androidInfo.version.sdkInt >= 31) {
      return const <Permission>[
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ];
    }

    return const <Permission>[
      Permission.locationWhenInUse,
    ];
  }

  BlePermissionRequirementStatus _mapStatuses(
    Iterable<PermissionStatus> statuses,
  ) {
    if (statuses.isEmpty) return BlePermissionRequirementStatus.unsupported;
    if (statuses.every((status) => status.isGranted)) {
      return BlePermissionRequirementStatus.granted;
    }
    if (statuses.any((status) => status.isPermanentlyDenied)) {
      return BlePermissionRequirementStatus.permanentlyDenied;
    }
    return BlePermissionRequirementStatus.denied;
  }
}
