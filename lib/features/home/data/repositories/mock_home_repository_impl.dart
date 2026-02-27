import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/sensor_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/mock_home_data_source.dart';

/// Mock implementation of [HomeRepository].
/// Delegates to [MockHomeDataSource] for fake data.
/// Swap in a real implementation once the backend is ready.
class MockHomeRepositoryImpl implements HomeRepository {
  final MockHomeDataSource dataSource;

  MockHomeRepositoryImpl({MockHomeDataSource? dataSource})
      : dataSource = dataSource ?? MockHomeDataSource();

  @override
  Future<Either<Failure, List<SensorEntity>>> getSensorData() async {
    try {
      final sensors = await dataSource.getSensorData();
      return Right(sensors);
    } catch (e) {
      return Left(ServerFailure('Failed to load sensor data: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    try {
      final categories = await dataSource.getCategories();
      return Right(categories);
    } catch (e) {
      return Left(ServerFailure('Failed to load categories: ${e.toString()}'));
    }
  }
}
