import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/sensor_entity.dart';
import '../entities/category_entity.dart';

/// Contract for the Home dashboard data layer.
/// Implementations can be mock (for dev/test) or real (API / MQTT).
abstract class HomeRepository {
  /// Returns a list of sensor readings for the overview cards.
  Future<Either<Failure, List<SensorEntity>>> getSensorData();

  /// Returns a list of music categories, each containing playlists.
  Future<Either<Failure, List<CategoryEntity>>> getCategories();
}
