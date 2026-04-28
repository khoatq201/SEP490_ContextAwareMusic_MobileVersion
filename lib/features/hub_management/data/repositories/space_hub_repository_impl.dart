import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/space_hub_binding.dart';
import '../../domain/repositories/space_hub_repository.dart';
import '../datasources/space_hub_remote_datasource.dart';
import '../datasources/space_hub_stub_datasource.dart';
import '../models/space_hub_binding_model.dart';

class SpaceHubRepositoryImpl implements SpaceHubRepository {
  SpaceHubRepositoryImpl({
    required this.remoteDataSource,
    required this.stubDataSource,
    required this.networkInfo,
  });

  final SpaceHubRemoteDataSource remoteDataSource;
  final SpaceHubStubDataSource stubDataSource;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, SpaceHubBinding?>> getBinding(String spaceId) async {
    try {
      final localBinding = await stubDataSource.getBinding(spaceId);
      if (localBinding?.isSyncPending ?? false) {
        final boundBinding = localBinding!.copyWith(
          status: SpaceHubBindingStatus.bound,
          clearLastError: true,
        );
        await stubDataSource.upsertBinding(
          SpaceHubBindingModel.fromEntity(boundBinding),
        );
        return Right(boundBinding);
      }
      return Right(localBinding);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Failed to fetch hub binding: $error'));
    }
  }

  @override
  Future<Either<Failure, SpaceHubBinding>> upsertBinding(
    SpaceHubBinding binding,
  ) async {
    final boundBinding = binding.copyWith(
      status: SpaceHubBindingStatus.bound,
      clearLastError: true,
    );

    try {
      await stubDataSource.upsertBinding(
        SpaceHubBindingModel.fromEntity(boundBinding),
      );
      return Right(boundBinding);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Failed to save hub binding: $error'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBinding(String spaceId) async {
    try {
      await stubDataSource.deleteBinding(spaceId);
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        return const Right(null);
      }

      try {
        await remoteDataSource.deleteBinding(spaceId);
      } on ServerException {
        // Keep local state authoritative until the backend contract is ready.
      }
      return const Right(null);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Failed to delete hub binding: $error'));
    }
  }

  @override
  Future<Either<Failure, void>> restartHub(String spaceId) async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        await stubDataSource.restartHub(spaceId);
        return const Right(null);
      }

      try {
        await remoteDataSource.restartHub(spaceId);
      } on ServerException {
        await stubDataSource.restartHub(spaceId);
      }
      return const Right(null);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Failed to restart hub: $error'));
    }
  }
}
