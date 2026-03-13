import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/sensor_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

/// Real implementation of [HomeRepository].
/// Delegates to [HomeRemoteDataSource] which fetches from Moods + Playlists API.
class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource dataSource;

  HomeRepositoryImpl({required this.dataSource});

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
