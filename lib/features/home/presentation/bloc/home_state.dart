import 'package:equatable/equatable.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/entities/sensor_entity.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final List<SensorEntity> sensors;
  final List<CategoryEntity> categories;
  final String? errorMessage;
  final bool autoModeEnabled;

  const HomeState({
    this.status = HomeStatus.initial,
    this.sensors = const [],
    this.categories = const [],
    this.errorMessage,
    this.autoModeEnabled = true,
  });

  HomeState copyWith({
    HomeStatus? status,
    List<SensorEntity>? sensors,
    List<CategoryEntity>? categories,
    String? errorMessage,
    bool? autoModeEnabled,
  }) {
    return HomeState(
      status: status ?? this.status,
      sensors: sensors ?? this.sensors,
      categories: categories ?? this.categories,
      errorMessage: errorMessage ?? this.errorMessage,
      autoModeEnabled: autoModeEnabled ?? this.autoModeEnabled,
    );
  }

  @override
  List<Object?> get props =>
      [status, sensors, categories, errorMessage, autoModeEnabled];
}
