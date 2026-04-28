import 'package:flutter/services.dart';
import 'package:flutter_esp_ble_prov/flutter_esp_ble_prov.dart';

import '../../domain/entities/ble_candidate.dart';
import '../../domain/entities/esp_provisioning_identity.dart';
import '../../domain/entities/wifi_candidate.dart';

abstract class BleProvisioningService {
  Future<List<BleCandidate>> scanDevices(String prefix);

  Future<List<WifiCandidate>> scanWifiNetworks(
    EspProvisioningIdentity identity,
  );

  Future<bool> provisionWifi(
    EspProvisioningIdentity identity, {
    required String ssid,
    required String passphrase,
  });

  Future<Uint8List> sendCustomData(
    EspProvisioningIdentity identity, {
    required String endpoint,
    required Uint8List payload,
  });
}

class FlutterBleProvisioningService implements BleProvisioningService {
  FlutterBleProvisioningService({FlutterEspBleProv? plugin})
      : _plugin = plugin ?? FlutterEspBleProv();

  final FlutterEspBleProv _plugin;

  @override
  Future<List<BleCandidate>> scanDevices(String prefix) async {
    try {
      final devices = await _plugin.scanBleDevices(prefix);
      return devices
          .where((device) => device.trim().isNotEmpty)
          .map(
            (device) => BleCandidate(
              bleDeviceName: device,
            ),
          )
          .toList(growable: false);
    } on PlatformException catch (error) {
      throw BleProvisioningException(_describeError(error));
    } catch (error) {
      throw BleProvisioningException(error.toString());
    }
  }

  @override
  Future<List<WifiCandidate>> scanWifiNetworks(
    EspProvisioningIdentity identity,
  ) async {
    try {
      final networks = await _plugin.scanWifiNetworks(
        identity.bleDeviceName,
        identity.proofOfPossession,
      );
      return networks
          .where((ssid) => ssid.trim().isNotEmpty)
          .map((ssid) => WifiCandidate(ssid: ssid))
          .toList(growable: false);
    } on PlatformException catch (error) {
      throw BleProvisioningException(_describeError(error));
    } catch (error) {
      throw BleProvisioningException(error.toString());
    }
  }

  @override
  Future<bool> provisionWifi(
    EspProvisioningIdentity identity, {
    required String ssid,
    required String passphrase,
  }) async {
    try {
      final result = await _plugin.provisionWifi(
        identity.bleDeviceName,
        identity.proofOfPossession,
        ssid,
        passphrase,
      );
      return result ?? false;
    } on PlatformException catch (error) {
      throw BleProvisioningException(_describeError(error));
    } catch (error) {
      throw BleProvisioningException(error.toString());
    }
  }

  @override
  Future<Uint8List> sendCustomData(
    EspProvisioningIdentity identity, {
    required String endpoint,
    required Uint8List payload,
  }) async {
    try {
      return await _plugin.sendReceiveCustomData(
        identity.bleDeviceName,
        identity.proofOfPossession,
        endpoint,
        payload,
      );
    } on PlatformException catch (error) {
      throw BleProvisioningException(_describeError(error));
    } catch (error) {
      throw BleProvisioningException(error.toString());
    }
  }

  String _describeError(PlatformException error) {
    final details = error.details?.toString();
    if (details != null && details.trim().isNotEmpty) {
      return details;
    }
    if (error.message != null && error.message!.trim().isNotEmpty) {
      return error.message!;
    }
    return error.code;
  }
}

class BleProvisioningException implements Exception {
  BleProvisioningException(this.message);

  final String message;

  @override
  String toString() => message;
}
