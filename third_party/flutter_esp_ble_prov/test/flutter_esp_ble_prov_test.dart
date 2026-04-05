import 'package:flutter_esp_ble_prov/flutter_esp_ble_prov.dart';
import 'package:flutter_esp_ble_prov/src/flutter_esp_ble_prov_method_channel.dart';
import 'package:flutter_esp_ble_prov/src/flutter_esp_ble_prov_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:typed_data';

class MockFlutterEspBleProvPlatform
    with MockPlatformInterfaceMixin
    implements FlutterEspBleProvPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<List<String>> scanBleDevices(String prefix) => Future.value(const []);

  @override
  Future<List<String>> scanWifiNetworks(
    String deviceName,
    String proofOfPossession,
  ) {
    return Future.value(const []);
  }

  @override
  Future<bool?> provisionWifi(
    String deviceName,
    String proofOfPossession,
    String ssid,
    String passphrase,
  ) {
    return Future.value(true);
  }

  @override
  Future<Uint8List> sendReceiveCustomData(
    String deviceName,
    String proofOfPossession,
    String endpointName,
    Uint8List data,
  ) {
    return Future.value(Uint8List.fromList(const [123, 125]));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final FlutterEspBleProvPlatform initialPlatform =
      FlutterEspBleProvPlatform.instance;

  test('$MethodChannelFlutterEspBleProv is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterEspBleProv>());
  });

  test('getPlatformVersion', () async {
    FlutterEspBleProv flutterEspBleProvPlugin = FlutterEspBleProv();
    MockFlutterEspBleProvPlatform fakePlatform =
        MockFlutterEspBleProvPlatform();
    FlutterEspBleProvPlatform.instance = fakePlatform;

    expect(await flutterEspBleProvPlugin.getPlatformVersion(), '42');
  });
}
