import 'dart:async';

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
        ApiConstants.getSpacesEndpoint,
        queryParameters: {'storeId': storeId},
      );

      if (response.statusCode != 200) {
        throw const ServerException('Failed to load spaces');
      }

      final data = response.data;
      final rawItems = <dynamic>[
        if (data is Map<String, dynamic>)
          ...(data['items'] as List<dynamic>? ??
              data['spaces'] as List<dynamic>? ??
              data['data'] as List<dynamic>? ??
              const <dynamic>[])
        else if (data is List)
          ...data,
      ];

      return rawItems
          .map(
            (json) => SpaceModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to load spaces: $e');
    }
  }

  @override
  Future<SpaceModel> getSpaceById(String spaceId) async {
    try {
      final response = await dioClient.get(
        ApiConstants.getSpaceDetailEndpoint.replaceAll('{spaceId}', spaceId),
      );

      if (response.statusCode != 200) {
        throw const ServerException('Failed to load space details');
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ServerException('Unexpected space details response format');
      }

      final rawSpace = data['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(data['data'] as Map)
          : data;

      return SpaceModel.fromJson(rawSpace);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to load space details: $e');
    }
  }

  @override
  Stream<SpaceModel> subscribeToSpaceStatus(String storeId, String spaceId) {
    final topic = ApiConstants.spaceStatusTopic(storeId, spaceId);

    mqttService.subscribe(topic);

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
    String storeId,
    String spaceId,
  ) {
    final topic = ApiConstants.spaceSensorTopic(storeId, spaceId);

    mqttService.subscribe(topic);

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
