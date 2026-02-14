import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/space.dart';
import '../entities/sensor_data.dart';

abstract class SpaceRepository {
  /// Get all spaces for a store
  Future<Either<Failure, List<Space>>> getSpaces(String storeId);

  /// Get space details by ID
  Future<Either<Failure, Space>> getSpaceById(String spaceId);

  /// Subscribe to real-time space status updates via MQTT
  Stream<Space> subscribeToSpaceStatus(String storeId, String spaceId);

  /// Subscribe to real-time sensor data via MQTT
  Stream<SensorData> subscribeToSensorData(String storeId, String spaceId);

  /// Unsubscribe from all topics for a space
  void unsubscribeFromSpace(String storeId, String spaceId);
}
