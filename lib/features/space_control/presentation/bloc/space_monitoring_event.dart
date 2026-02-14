import 'package:equatable/equatable.dart';
import '../../domain/entities/sensor_data.dart';
import '../../domain/entities/space.dart';

abstract class SpaceMonitoringEvent extends Equatable {
  const SpaceMonitoringEvent();

  @override
  List<Object?> get props => [];
}

class StartMonitoring extends SpaceMonitoringEvent {
  final String storeId;
  final String spaceId;

  const StartMonitoring({
    required this.storeId,
    required this.spaceId,
  });

  @override
  List<Object?> get props => [storeId, spaceId];
}

class StopMonitoring extends SpaceMonitoringEvent {
  const StopMonitoring();
}

class SpaceStatusUpdated extends SpaceMonitoringEvent {
  final Space space;

  const SpaceStatusUpdated(this.space);

  @override
  List<Object?> get props => [space];
}

class SensorDataUpdated extends SpaceMonitoringEvent {
  final SensorData sensorData;

  const SensorDataUpdated(this.sensorData);

  @override
  List<Object?> get props => [sensorData];
}
