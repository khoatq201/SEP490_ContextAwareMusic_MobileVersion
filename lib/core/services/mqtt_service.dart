// ignore_for_file: avoid_print, prefer_const_constructors

import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import '../constants/api_constants.dart';
import '../error/exceptions.dart';

const bool _isE2ERun = bool.fromEnvironment('E2E_RUN', defaultValue: false);

class MqttService {
  MqttServerClient? _client;
  final _messageController = StreamController<MqttMessage>.broadcast();
  final _connectionController =
      StreamController<MqttConnectionState>.broadcast();
  final Set<String> _desiredTopics = <String>{};
  final Set<String> _subscribedTopics = <String>{};
  StreamSubscription? _updatesSubscription;

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
      await _updatesSubscription?.cancel();
      _updatesSubscription = null;
      _subscribedTopics.clear();

      _client = MqttServerClient(ApiConstants.mqttBrokerUrl, clientId);
      _client!.port = ApiConstants.mqttPort;
      _client!.logging(on: !_isE2ERun);
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

      await _client!.connect();
      if (!isConnected) {
        throw const MqttConnectionException(
          'MQTT broker rejected the connection.',
        );
      }

      _updatesSubscription = _client!.updates?.listen(
        (List<mqtt.MqttReceivedMessage<mqtt.MqttMessage>> messages) {
          _onMessage(messages);
        },
      );
      _restoreSubscriptions();
    } catch (e) {
      throw MqttConnectionException('Failed to connect to MQTT broker: $e');
    }
  }

  Future<void> disconnect() async {
    await _updatesSubscription?.cancel();
    _updatesSubscription = null;
    _client?.disconnect();
  }

  void subscribe(String topic) {
    _desiredTopics.add(topic);
    if (!isConnected) {
      if (!_isE2ERun) {
        print('MQTT subscribe deferred until connected: $topic');
      }
      return;
    }
    _subscribeNow(topic);
  }

  void unsubscribe(String topic) {
    _desiredTopics.remove(topic);
    _subscribedTopics.remove(topic);
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
    if (!_isE2ERun) {
      print('MQTT Connected');
    }
    _connectionController.add(MqttConnectionState.connected);
    _restoreSubscriptions();
  }

  void _onDisconnected() {
    if (!_isE2ERun) {
      print('MQTT Disconnected');
    }
    _subscribedTopics.clear();
    _connectionController.add(MqttConnectionState.disconnected);
  }

  void _onSubscribed(String topic) {
    if (!_isE2ERun) {
      print('MQTT Subscribed to: $topic');
    }
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
    _updatesSubscription?.cancel();
    _messageController.close();
    _connectionController.close();
  }

  void _restoreSubscriptions() {
    if (!isConnected) {
      return;
    }
    for (final topic in _desiredTopics) {
      _subscribeNow(topic);
    }
  }

  void _subscribeNow(String topic) {
    if (!isConnected || _subscribedTopics.contains(topic)) {
      return;
    }
    _client!.subscribe(topic, MqttQos.atLeastOnce);
    _subscribedTopics.add(topic);
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
