import 'dart:async';
import 'dart:convert';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/mqtt_service.dart';
import '../models/sensor_data_model.dart';
import '../models/space_model.dart';

abstract class SpaceRemoteDataSource {
  Future<List<SpaceModel>> getSpaces(String storeId);
  Future<SpaceModel> getSpaceById(String spaceId);
  Stream<SpaceModel> subscribeToSpaceStatus(String storeId, String spaceId);
  Stream<SensorDataModel> subscribeToSensorData(String storeId, String spaceId);
  void unsubscribeFromSpace(String storeId, String spaceId);
}

class SpaceRemoteDataSourceImpl implements SpaceRemoteDataSource {
  final DioClient dioClient;
  final MqttService mqttService;

  SpaceRemoteDataSourceImpl({
    required this.dioClient,
    required this.mqttService,
  });

  @override
  Future<List<SpaceModel>> getSpaces(String storeId) async {
    try {
      final response = await dioClient.get(
        ApiConstants.getSpacesEndpoint.replaceAll('{storeId}', storeId),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['spaces'] as List<dynamic>;
        return data.map((json) => SpaceModel.fromJson(json)).toList();
      } else {
        throw ServerException('Failed to load spaces');
      }
    } catch (e) {
      throw ServerException('Failed to load spaces: $e');
    }
  }

  @override
  Future<SpaceModel> getSpaceById(String spaceId) async {
    try {
      final response = await dioClient.get(
        ApiConstants.getSpaceDetailEndpoint.replaceAll('{spaceId}', spaceId),
      );

      if (response.statusCode == 200) {
        return SpaceModel.fromJson(response.data);
      } else {
        throw ServerException('Failed to load space details');
      }
    } catch (e) {
      throw ServerException('Failed to load space details: $e');
    }
  }

  @override
  Stream<SpaceModel> subscribeToSpaceStatus(String storeId, String spaceId) {
    final topic = ApiConstants.spaceStatusTopic(storeId, spaceId);

    // Subscribe to the topic
    mqttService.subscribe(topic);

    // Filter messages for this specific topic
    return mqttService.messages
        .where((message) => message.topic == topic)
        .map((message) {
      try {
        return SpaceModel.fromJson(message.payloadAsJson);
      } catch (e) {
        throw ServerException('Failed to parse space status: $e');
      }
    });
  }

  @override
  Stream<SensorDataModel> subscribeToSensorData(
      String storeId, String spaceId) {
    final topic = ApiConstants.spaceSensorTopic(storeId, spaceId);

    // Subscribe to the topic
    mqttService.subscribe(topic);

    // Filter messages for this specific topic
    return mqttService.messages
        .where((message) => message.topic == topic)
        .map((message) {
      try {
        return SensorDataModel.fromJson(message.payloadAsJson);
      } catch (e) {
        throw ServerException('Failed to parse sensor data: $e');
      }
    });
  }

  @override
  void unsubscribeFromSpace(String storeId, String spaceId) {
    final statusTopic = ApiConstants.spaceStatusTopic(storeId, spaceId);
    final sensorTopic = ApiConstants.spaceSensorTopic(storeId, spaceId);

    mqttService.unsubscribe(statusTopic);
    mqttService.unsubscribe(sensorTopic);
  }
}
