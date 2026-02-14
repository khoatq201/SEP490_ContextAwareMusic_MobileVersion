import '../../domain/entities/sensor_data.dart';

class SensorDataModel extends SensorData {
  const SensorDataModel({
    required super.temperature,
    required super.noiseLevel,
    required super.humidity,
    super.lightLevel,
    required super.timestamp,
  });

  factory SensorDataModel.fromJson(Map<String, dynamic> json) {
    return SensorDataModel(
      temperature: (json['temperature'] as num).toDouble(),
      noiseLevel: (json['noiseLevel'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      lightLevel: json['lightLevel'] != null
          ? (json['lightLevel'] as num).toDouble()
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'noiseLevel': noiseLevel,
      'humidity': humidity,
      'lightLevel': lightLevel,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  SensorData toEntity() {
    return SensorData(
      temperature: temperature,
      noiseLevel: noiseLevel,
      humidity: humidity,
      lightLevel: lightLevel,
      timestamp: timestamp,
    );
  }

  factory SensorDataModel.fromEntity(SensorData data) {
    return SensorDataModel(
      temperature: data.temperature,
      noiseLevel: data.noiseLevel,
      humidity: data.humidity,
      lightLevel: data.lightLevel,
      timestamp: data.timestamp,
    );
  }
}
