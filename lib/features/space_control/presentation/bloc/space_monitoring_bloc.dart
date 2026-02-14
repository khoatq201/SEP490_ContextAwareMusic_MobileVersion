import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/sensor_data.dart';
import '../../domain/usecases/get_space_by_id.dart';
import '../../domain/usecases/subscribe_to_sensor_data.dart';
import '../../domain/usecases/subscribe_to_space_status.dart';
import 'space_monitoring_event.dart';
import 'space_monitoring_state.dart';

class SpaceMonitoringBloc
    extends Bloc<SpaceMonitoringEvent, SpaceMonitoringState> {
  final GetSpaceById getSpaceById;
  final SubscribeToSpaceStatus subscribeToSpaceStatus;
  final SubscribeToSensorData subscribeToSensorData;

  StreamSubscription? _spaceStatusSubscription;
  StreamSubscription? _sensorDataSubscription;

  SpaceMonitoringBloc({
    required this.getSpaceById,
    required this.subscribeToSpaceStatus,
    required this.subscribeToSensorData,
  }) : super(const SpaceMonitoringState()) {
    on<StartMonitoring>(_onStartMonitoring);
    on<StopMonitoring>(_onStopMonitoring);
    on<SpaceStatusUpdated>(_onSpaceStatusUpdated);
    on<SensorDataUpdated>(_onSensorDataUpdated);
  }

  Future<void> _onStartMonitoring(
    StartMonitoring event,
    Emitter<SpaceMonitoringState> emit,
  ) async {
    emit(state.copyWith(status: SpaceMonitoringStatus.loading));

    // Get initial space data
    final result = await getSpaceById(event.spaceId);

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: SpaceMonitoringStatus.error,
          errorMessage: failure.message,
        ));
      },
      (space) {
        emit(state.copyWith(
          status: SpaceMonitoringStatus.monitoring,
          space: space,
        ));

        // Subscribe to real-time updates
        _spaceStatusSubscription = subscribeToSpaceStatus(
          event.storeId,
          event.spaceId,
        ).listen(
          (space) => add(SpaceStatusUpdated(space)),
          onError: (error) {
            emit(state.copyWith(
              status: SpaceMonitoringStatus.error,
              errorMessage: 'Failed to receive space updates: $error',
            ));
          },
        );

        _sensorDataSubscription = subscribeToSensorData(
          event.storeId,
          event.spaceId,
        ).listen(
          (sensorData) => add(SensorDataUpdated(sensorData)),
          onError: (error) {
            emit(state.copyWith(
              status: SpaceMonitoringStatus.error,
              errorMessage: 'Failed to receive sensor data: $error',
            ));
          },
        );
      },
    );
  }

  void _onStopMonitoring(
    StopMonitoring event,
    Emitter<SpaceMonitoringState> emit,
  ) {
    _spaceStatusSubscription?.cancel();
    _sensorDataSubscription?.cancel();
    emit(state.copyWith(status: SpaceMonitoringStatus.stopped));
  }

  void _onSpaceStatusUpdated(
    SpaceStatusUpdated event,
    Emitter<SpaceMonitoringState> emit,
  ) {
    emit(state.copyWith(space: event.space));
  }

  void _onSensorDataUpdated(
    SensorDataUpdated event,
    Emitter<SpaceMonitoringState> emit,
  ) {
    final updatedHistory = List<SensorData>.from(state.sensorHistory)
      ..add(event.sensorData);

    // Keep only the last N data points
    if (updatedHistory.length > AppConstants.maxSensorDataPoints) {
      updatedHistory.removeAt(0);
    }

    emit(state.copyWith(
      latestSensorData: event.sensorData,
      sensorHistory: updatedHistory,
    ));
  }

  @override
  Future<void> close() {
    _spaceStatusSubscription?.cancel();
    _sensorDataSubscription?.cancel();
    return super.close();
  }
}
