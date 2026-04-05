import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/space.dart';
import '../../domain/entities/sensor_data.dart';
import '../../domain/repositories/space_repository.dart';
import '../datasources/space_remote_datasource.dart';

class SpaceRepositoryImpl implements SpaceRepository {
  final SpaceRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  SpaceRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Space>>> getSpaces(String storeId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final spaces = await remoteDataSource.getSpaces(storeId);
      return Right(
          spaces.map((model) => model.toEntity()).toList().cast<Space>());
    } on ServerException catch (e) {
      return Left(
        ErrorMapper.toFailure(
          e,
          fallbackMessage: 'Unable to load spaces right now.',
        ),
      );
    } on NetworkException catch (e) {
      return Left(
        ErrorMapper.toFailure(
          e,
          fallbackMessage: 'Check your internet connection and try again.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Space>> getSpaceById(String spaceId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final space = await remoteDataSource.getSpaceById(spaceId);
      return Right(space.toEntity());
    } on ServerException catch (e) {
      return Left(
        ErrorMapper.toFailure(
          e,
          fallbackMessage: 'Unable to load this space right now.',
        ),
      );
    } on NetworkException catch (e) {
      return Left(
        ErrorMapper.toFailure(
          e,
          fallbackMessage: 'Check your internet connection and try again.',
        ),
      );
    }
  }

  @override
  Stream<Space> subscribeToSpaceStatus(String storeId, String spaceId) {
    return remoteDataSource
        .subscribeToSpaceStatus(storeId, spaceId)
        .map((model) => model.toEntity());
  }

  @override
  Stream<SensorData> subscribeToSensorData(String storeId, String spaceId) {
    return remoteDataSource
        .subscribeToSensorData(storeId, spaceId)
        .map((model) => model.toEntity());
  }

  @override
  void unsubscribeFromSpace(String storeId, String spaceId) {
    remoteDataSource.unsubscribeFromSpace(storeId, spaceId);
  }
}
