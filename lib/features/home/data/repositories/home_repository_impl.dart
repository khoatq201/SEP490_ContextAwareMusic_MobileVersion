import 'package:dartz/dartz.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/session_data_cache.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/sensor_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

/// Real implementation of [HomeRepository].
/// Delegates to [HomeRemoteDataSource] which fetches from Moods + Playlists API.
class HomeRepositoryImpl implements HomeRepository {
  static const String _categoriesCacheKey = 'home.categories';

  final HomeRemoteDataSource dataSource;
  final SessionDataCache? sessionDataCache;

  HomeRepositoryImpl({
    required this.dataSource,
    this.sessionDataCache,
  });

  @override
  Future<Either<Failure, List<SensorEntity>>> getSensorData({
    String? storeId,
    String? spaceId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _sensorCacheKey(storeId: storeId, spaceId: spaceId);
    if (!forceRefresh) {
      final cached = sessionDataCache?.get<List<SensorEntity>>(cacheKey);
      if (cached != null) {
        return Right(cached);
      }
    }

    try {
      final sensors = await dataSource.getSensorData(
        storeId: storeId,
        spaceId: spaceId,
      );
      sessionDataCache?.put(cacheKey, sensors);
      return Right(sensors);
    } catch (e) {
      return Left(
        ErrorMapper.toFailure(
          e,
          fallbackMessage: 'Unable to load sensor data right now.',
        ),
      );
    }
  }

  String _sensorCacheKey({
    String? storeId,
    String? spaceId,
  }) {
    return 'home.sensors.${storeId ?? ''}.${spaceId ?? ''}';
  }

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached =
          sessionDataCache?.get<List<CategoryEntity>>(_categoriesCacheKey);
      if (cached != null) {
        return Right(cached);
      }
    }

    try {
      final categories = await dataSource.getCategories();
      sessionDataCache?.put(_categoriesCacheKey, categories);
      return Right(categories);
    } catch (e) {
      return Left(
        ErrorMapper.toFailure(
          e,
          fallbackMessage: 'Unable to load music categories right now.',
        ),
      );
    }
  }
}
