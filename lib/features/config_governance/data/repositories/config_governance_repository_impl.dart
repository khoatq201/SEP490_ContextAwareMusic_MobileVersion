import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/pagination_result.dart';
import '../../domain/entities/config_flat_row.dart';
import '../../domain/entities/config_query.dart';
import '../../domain/entities/config_value_upsert_request.dart';
import '../../domain/repositories/config_governance_repository.dart';
import '../datasources/config_governance_remote_datasource.dart';

class ConfigGovernanceRepositoryImpl implements ConfigGovernanceRepository {
  final ConfigGovernanceRemoteDataSource remoteDataSource;

  ConfigGovernanceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, PaginationResult<ConfigFlatRow>>> getBrandConfig({
    ConfigQuery query = const ConfigQuery(),
  }) async {
    try {
      final result = await remoteDataSource.getBrandConfig(query: query);
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Failed to load brand config: $error'));
    }
  }

  @override
  Future<Either<Failure, PaginationResult<ConfigFlatRow>>> getStoreConfig({
    String? storeId,
    ConfigQuery query = const ConfigQuery(),
  }) async {
    try {
      final result = await remoteDataSource.getStoreConfig(
        storeId: storeId,
        query: query,
      );
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Failed to load store config: $error'));
    }
  }

  @override
  Future<Either<Failure, PaginationResult<ConfigFlatRow>>> getSpaceConfig({
    required String spaceId,
    ConfigQuery query = const ConfigQuery(),
  }) async {
    try {
      final result = await remoteDataSource.getSpaceConfig(
        spaceId: spaceId,
        query: query,
      );
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Failed to load space config: $error'));
    }
  }

  @override
  Future<Either<Failure, String>> upsertStoreValue({
    String? storeId,
    required ConfigValueUpsertRequest request,
  }) async {
    try {
      final message = await remoteDataSource.upsertStoreValue(
        storeId: storeId,
        request: request,
      );
      return Right(message);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Failed to update store config: $error'));
    }
  }

  @override
  Future<Either<Failure, String>> upsertBrandValue({
    required ConfigValueUpsertRequest request,
  }) async {
    try {
      final message = await remoteDataSource.upsertBrandValue(request: request);
      return Right(message);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Failed to update brand config: $error'));
    }
  }

  @override
  Future<Either<Failure, String>> upsertSpaceValue({
    required String spaceId,
    required ConfigValueUpsertRequest request,
  }) async {
    try {
      final message = await remoteDataSource.upsertSpaceValue(
        spaceId: spaceId,
        request: request,
      );
      return Right(message);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Failed to update space config: $error'));
    }
  }

  @override
  Future<Either<Failure, String>> setStoreGovernanceMode({
    required SetStoreGovernanceModeRequest request,
  }) async {
    try {
      final message = await remoteDataSource.setStoreGovernanceMode(
        request: request,
      );
      return Right(message);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Failed to update governance mode: $error'));
    }
  }

  @override
  Future<Either<Failure, String>> publishConfigVersion({
    required PublishConfigVersionRequest request,
  }) async {
    try {
      final message = await remoteDataSource.publishConfigVersion(
        request: request,
      );
      return Right(message);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Failed to publish config version: $error'));
    }
  }

  @override
  Future<Either<Failure, String>> rollbackConfigVersion({
    required RollbackConfigVersionRequest request,
  }) async {
    try {
      final message = await remoteDataSource.rollbackConfigVersion(
        request: request,
      );
      return Right(message);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Failed to rollback config version: $error'));
    }
  }
}
