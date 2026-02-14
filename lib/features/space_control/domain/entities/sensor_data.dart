import 'package:equatable/equatable.dart';

class SensorData extends Equatable {
  final double temperature;
  final double noiseLevel;
  final double humidity;
  final double? lightLevel;
  final DateTime timestamp;

  const SensorData({
    required this.temperature,
    required this.noiseLevel,
    required this.humidity,
    this.lightLevel,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        temperature,
        noiseLevel,
        humidity,
        lightLevel,
        timestamp,
      ];
}
