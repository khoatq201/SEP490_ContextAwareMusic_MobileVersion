import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import '../constants/api_constants.dart';
import '../error/exceptions.dart';

class MqttService {
  MqttServerClient? _client;
  final _messageController = StreamController<MqttMessage>.broadcast();
  final _connectionController =
      StreamController<MqttConnectionState>.broadcast();

  Stream<MqttMessage> get messages => _messageController.stream;
  Stream<MqttConnectionState> get connectionState =>
      _connectionController.stream;

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<void> connect({
    required String clientId,
    String? username,
    String? password,
  }) async {
    try {
      _client = MqttServerClient(ApiConstants.mqttBrokerUrl, clientId);
      _client!.port = ApiConstants.mqttPort;
      _client!.logging(on: true);
      _client!.keepAlivePeriod = 60;
      _client!.autoReconnect = true;

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      if (username != null && password != null) {
        connMessage.authenticateAs(username, password);
      }

      _client!.connectionMessage = connMessage;

      // Setup callbacks
      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onSubscribed = _onSubscribed;
      _client!.updates!
          .listen((List<mqtt.MqttReceivedMessage<mqtt.MqttMessage>> messages) {
        _onMessage(messages);
      });

      await _client!.connect();
    } catch (e) {
      throw MqttConnectionException('Failed to connect to MQTT broker: $e');
    }
  }

  Future<void> disconnect() async {
    _client?.disconnect();
  }

  void subscribe(String topic) {
    if (!isConnected) {
      throw MqttConnectionException('MQTT client is not connected');
    }
    _client!.subscribe(topic, MqttQos.atLeastOnce);
  }

  void unsubscribe(String topic) {
    if (!isConnected) return;
    _client!.unsubscribe(topic);
  }

  void publish(String topic, Map<String, dynamic> message) {
    if (!isConnected) {
      throw MqttConnectionException('MQTT client is not connected');
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(message));
    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void _onConnected() {
    print('MQTT Connected');
    _connectionController.add(MqttConnectionState.connected);
  }

  void _onDisconnected() {
    print('MQTT Disconnected');
    _connectionController.add(MqttConnectionState.disconnected);
  }

  void _onSubscribed(String topic) {
    print('MQTT Subscribed to: $topic');
  }

  void _onMessage(List<mqtt.MqttReceivedMessage<mqtt.MqttMessage>> messages) {
    for (final message in messages) {
      final payload = message.payload as MqttPublishMessage;
      final payloadString = MqttPublishPayload.bytesToStringAsString(
        payload.payload.message,
      );

      _messageController.add(MqttMessage(
        topic: message.topic,
        payload: payloadString,
        timestamp: DateTime.now(),
      ));
    }
  }

  void dispose() {
    _client?.disconnect();
    _messageController.close();
    _connectionController.close();
  }
}

class MqttMessage {
  final String topic;
  final String payload;
  final DateTime timestamp;

  MqttMessage({
    required this.topic,
    required this.payload,
    required this.timestamp,
  });

  Map<String, dynamic> get payloadAsJson {
    try {
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }
}
