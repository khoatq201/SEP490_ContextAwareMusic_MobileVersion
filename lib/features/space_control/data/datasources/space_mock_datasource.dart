import 'dart:async';
import 'dart:convert';
import '../models/sensor_data_model.dart';
import '../models/space_model.dart';
import 'space_remote_datasource.dart';

/// Mock implementation of SpaceRemoteDataSource for development and testing
/// Provides realistic data without requiring API server or MQTT broker
class SpaceMockDataSource implements SpaceRemoteDataSource {
  final _statusController = StreamController<SpaceModel>.broadcast();
  final _sensorController = StreamController<SensorDataModel>.broadcast();
  Timer? _mockDataTimer;

  @override
  Future<List<SpaceModel>> getSpaces(String storeId) async {
    await Future.delayed(const Duration(milliseconds: 400));

    return [
      _getMockSpace('space-1', 'Main Floor', storeId, 'energetic'),
      _getMockSpace('space-2', 'VIP Lounge', storeId, 'calm'),
      _getMockSpace('space-3', 'Storage Room', storeId, 'offline',
          isOnline: false),
      _getMockSpace('space-4', 'Staff Area', storeId, 'relaxed'),
    ];
  }

  @override
  Future<SpaceModel> getSpaceById(String spaceId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Return appropriate mock data based on space ID
    switch (spaceId) {
      case 'space-1':
        return _getMockSpace('space-1', 'Main Floor', 'store-001', 'energetic',
            customerCount: 12, temperature: 24.5, humidity: 65.0);
      case 'space-2':
        return _getMockSpace('space-2', 'VIP Lounge', 'store-001', 'calm',
            customerCount: 3, temperature: 22.0, humidity: 60.0);
      case 'space-3':
        return _getMockSpace('space-3', 'Storage Room', 'store-001', 'offline',
            isOnline: false,
            customerCount: 0,
            temperature: 26.0,
            humidity: 70.0);
      case 'space-4':
        return _getMockSpace('space-4', 'Staff Area', 'store-001', 'relaxed',
            customerCount: 5, temperature: 23.0, humidity: 62.0);
      default:
        return _getMockSpace(
            spaceId, 'Unknown Space', 'store-001', 'energetic');
    }
  }

  @override
  Stream<SpaceModel> subscribeToSpaceStatus(String storeId, String spaceId) {
    // Start sending periodic updates
    _startMockUpdates(spaceId);
    return _statusController.stream;
  }

  @override
  Stream<SensorDataModel> subscribeToSensorData(
      String storeId, String spaceId) {
    // Start sending periodic sensor updates
    _startMockSensorUpdates(spaceId);
    return _sensorController.stream;
  }

  @override
  void unsubscribeFromSpace(String storeId, String spaceId) {
    _mockDataTimer?.cancel();
  }

  void _startMockUpdates(String spaceId) {
    _mockDataTimer?.cancel();
    _mockDataTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // Simulate random customer count changes
      final space = _getMockSpace(
        spaceId,
        'Main Floor',
        'store-001',
        'energetic',
        customerCount: 10 + (timer.tick % 5),
      );
      _statusController.add(space);
    });
  }

  void _startMockSensorUpdates(String spaceId) {
    Timer.periodic(const Duration(seconds: 2), (timer) {
      final sensorData = SensorDataModel(
        temperature: 23.0 + (timer.tick % 3),
        noiseLevel: 45.0 + (timer.tick % 15), // dB level
        humidity: 60.0 + (timer.tick % 10),
        lightLevel: 700 + (timer.tick % 100),
        timestamp: DateTime.now(),
      );
      _sensorController.add(sensorData);
    });
  }

  SpaceModel _getMockSpace(
    String id,
    String name,
    String storeId,
    String mood, {
    bool isOnline = true,
    int customerCount = 8,
    double temperature = 24.0,
    double humidity = 65.0,
  }) {
    return SpaceModel(
      id: id,
      name: name,
      storeId: storeId,
      status: isOnline ? 'Online' : 'Offline',
      currentMood: mood,
      assignedHubId: 'hub-001',
    );
  }

  void dispose() {
    _mockDataTimer?.cancel();
    _statusController.close();
    _sensorController.close();
  }
}
