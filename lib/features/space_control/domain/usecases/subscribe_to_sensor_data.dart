import '../entities/sensor_data.dart';
import '../repositories/space_repository.dart';

class SubscribeToSensorData {
  final SpaceRepository repository;

  SubscribeToSensorData(this.repository);

  Stream<SensorData> call(String storeId, String spaceId) {
    return repository.subscribeToSensorData(storeId, spaceId);
  }
}
