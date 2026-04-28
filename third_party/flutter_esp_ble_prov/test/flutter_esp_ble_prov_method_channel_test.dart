import 'package:flutter/services.dart';
import 'package:flutter_esp_ble_prov/src/flutter_esp_ble_prov_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MethodChannelFlutterEspBleProv platform = MethodChannelFlutterEspBleProv();
  const MethodChannel channel = MethodChannel('flutter_esp_ble_prov');

  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('sendReceiveCustomData', () async {
    messenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      expect(methodCall.method, 'sendReceiveCustomData');
      expect(methodCall.arguments, {
        'deviceName': 'CAM-ESP32-01',
        'proofOfPossession': 'secret-123',
        'endpointName': 'custom-location',
        'data': Uint8List.fromList(const [1, 2, 3]),
      });
      return Uint8List.fromList(const [123, 125]);
    });

    final response = await platform.sendReceiveCustomData(
      'CAM-ESP32-01',
      'secret-123',
      'custom-location',
      Uint8List.fromList(const [1, 2, 3]),
    );

    expect(response, Uint8List.fromList(const [123, 125]));
  });
}
