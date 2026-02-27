import 'dart:async';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/mqtt_service.dart';
import '../models/music_player_state_model.dart';

abstract class MusicControlRemoteDataSource {
  Future<void> overrideMood({
    required String spaceId,
    required String moodId,
    required int duration,
  });

  Future<void> sendMusicControl(String spaceId, String action);
  Stream<MusicPlayerStateModel> subscribeMusicPlayerState(
      String storeId, String spaceId);
  void unsubscribeMusicPlayerState(String storeId, String spaceId);
}

class MusicControlRemoteDataSourceImpl implements MusicControlRemoteDataSource {
  final DioClient dioClient;
  final MqttService mqttService;

  MusicControlRemoteDataSourceImpl({
    required this.dioClient,
    required this.mqttService,
  });

  @override
  Future<void> overrideMood({
    required String spaceId,
    required String moodId,
    required int duration,
  }) async {
    try {
      final response = await dioClient.post(
        ApiConstants.overrideMoodEndpoint.replaceAll('{spaceId}', spaceId),
        data: {
          'moodId': moodId,
          'duration': duration,
        },
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to override mood');
      }
    } catch (e) {
      throw ServerException('Failed to override mood: $e');
    }
  }

  @override
  Future<void> sendMusicControl(String spaceId, String action) async {
    try {
      final response = await dioClient.post(
        ApiConstants.musicControlEndpoint.replaceAll('{spaceId}', spaceId),
        data: {
          'action': action,
        },
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to send music control command');
      }
    } catch (e) {
      throw ServerException('Failed to send music control command: $e');
    }
  }

  @override
  Stream<MusicPlayerStateModel> subscribeMusicPlayerState(
    String storeId,
    String spaceId,
  ) {
    final topic = ApiConstants.spaceMusicTopic(storeId, spaceId);

    // Subscribe to the topic
    mqttService.subscribe(topic);

    // Filter messages for this specific topic
    return mqttService.messages
        .where((message) => message.topic == topic)
        .map((message) {
      try {
        return MusicPlayerStateModel.fromJson(message.payloadAsJson);
      } catch (e) {
        throw ServerException('Failed to parse music player state: $e');
      }
    });
  }

  @override
  void unsubscribeMusicPlayerState(String storeId, String spaceId) {
    final topic = ApiConstants.spaceMusicTopic(storeId, spaceId);
    mqttService.unsubscribe(topic);
  }
}
