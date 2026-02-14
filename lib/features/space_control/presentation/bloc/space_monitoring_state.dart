import 'package:equatable/equatable.dart';
import '../../domain/entities/sensor_data.dart';
import '../../domain/entities/space.dart';

enum SpaceMonitoringStatus { initial, loading, monitoring, error, stopped }

class SpaceMonitoringState extends Equatable {
  final SpaceMonitoringStatus status;
  final Space? space;
  final SensorData? latestSensorData;
  final List<SensorData> sensorHistory;
  final String? errorMessage;

  const SpaceMonitoringState({
    this.status = SpaceMonitoringStatus.initial,
    this.space,
    this.latestSensorData,
    this.sensorHistory = const [],
    this.errorMessage,
  });

  SpaceMonitoringState copyWith({
    SpaceMonitoringStatus? status,
    Space? space,
    SensorData? latestSensorData,
    List<SensorData>? sensorHistory,
    String? errorMessage,
  }) {
    return SpaceMonitoringState(
      status: status ?? this.status,
      space: space ?? this.space,
      latestSensorData: latestSensorData ?? this.latestSensorData,
      sensorHistory: sensorHistory ?? this.sensorHistory,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        space,
        latestSensorData,
        sensorHistory,
        errorMessage,
      ];
}
