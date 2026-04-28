import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PairingDeviceMetadata {
  final String? manufacturer;
  final String? model;
  final String? osVersion;
  final String? appVersion;
  final String? deviceId;

  const PairingDeviceMetadata({
    this.manufacturer,
    this.model,
    this.osVersion,
    this.appVersion,
    this.deviceId,
  });
}

class DeviceMetadataService {
  static Future<PairingDeviceMetadata> collect() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final appVersion = packageInfo.version;
    final deviceInfo = DeviceInfoPlugin();

    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final info = await deviceInfo.androidInfo;
          return PairingDeviceMetadata(
            manufacturer: info.manufacturer,
            model: info.model,
            osVersion: 'Android ${info.version.release}',
            appVersion: appVersion,
            deviceId: info.id,
          );
        case TargetPlatform.iOS:
          final info = await deviceInfo.iosInfo;
          return PairingDeviceMetadata(
            manufacturer: 'Apple',
            model: info.model,
            osVersion: '${info.systemName} ${info.systemVersion}',
            appVersion: appVersion,
            deviceId: info.identifierForVendor,
          );
        default:
          return PairingDeviceMetadata(
            manufacturer: Platform.operatingSystem,
            model: Platform.localHostname,
            osVersion: Platform.operatingSystemVersion,
            appVersion: appVersion,
          );
      }
    } catch (_) {
      return PairingDeviceMetadata(
        osVersion: Platform.operatingSystemVersion,
        appVersion: appVersion,
      );
    }
  }
}
