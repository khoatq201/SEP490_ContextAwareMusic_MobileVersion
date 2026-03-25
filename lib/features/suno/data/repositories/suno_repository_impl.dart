import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/suno_config.dart';
import '../../domain/entities/suno_generation.dart';
import '../datasources/suno_remote_datasource.dart';

abstract class SunoRepository {
  Future<Either<Failure, String>> createGeneration(
    CreateSunoGenerationRequest request,
  );

  Future<Either<Failure, SunoGeneration>> getGeneration(String id);

  Future<Either<Failure, void>> cancelGeneration(String id);

  Future<Either<Failure, SunoConfig>> getConfig();

  Future<Either<Failure, SunoConfig>> updateConfig(
    UpdateSunoConfigRequest request,
  );
}

class SunoRepositoryImpl implements SunoRepository {
  final SunoRemoteDataSource remoteDataSource;

  SunoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, String>> createGeneration(
    CreateSunoGenerationRequest request,
  ) async {
    try {
      final result = await remoteDataSource.createGeneration(request);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to create Suno generation: $e'));
    }
  }

  @override
  Future<Either<Failure, SunoGeneration>> getGeneration(String id) async {
    try {
      final result = await remoteDataSource.getGeneration(id);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get Suno generation: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelGeneration(String id) async {
    try {
      await remoteDataSource.cancelGeneration(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to cancel Suno generation: $e'));
    }
  }

  @override
  Future<Either<Failure, SunoConfig>> getConfig() async {
    try {
      final result = await remoteDataSource.getConfig();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get Suno config: $e'));
    }
  }

  @override
  Future<Either<Failure, SunoConfig>> updateConfig(
    UpdateSunoConfigRequest request,
  ) async {
    try {
      final result = await remoteDataSource.updateConfig(request);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to update Suno config: $e'));
    }
  }
}
