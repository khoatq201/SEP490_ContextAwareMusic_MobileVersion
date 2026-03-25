import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/store.dart';
import '../../domain/entities/space_summary.dart';
import '../../domain/repositories/store_repository.dart';
import '../datasources/store_remote_datasource.dart';

class StoreRepositoryImpl implements StoreRepository {
  final StoreRemoteDataSource remoteDataSource;

  StoreRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Store>> getStoreDetails(String storeId) async {
    try {
      final storeModel = await remoteDataSource.getStoreDetails(storeId);
      return Right(storeModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('Failed to get store details: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<SpaceSummary>>> getSpaceSummaries(
      String storeId) async {
    try {
      final spaceModels = await remoteDataSource.getSpaceSummaries(storeId);
      return Right(spaceModels.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('Failed to get space summaries: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, StoreMutationResult>> createStore(
    StoreMutationRequest request,
  ) async {
    try {
      final result = await remoteDataSource.createStore(request);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to create store: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, StoreMutationResult>> updateStore(
    String storeId,
    StoreMutationRequest request,
  ) async {
    try {
      final result = await remoteDataSource.updateStore(storeId, request);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to update store: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, StoreMutationResult>> deleteStore(
    String storeId,
  ) async {
    try {
      final result = await remoteDataSource.deleteStore(storeId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to delete store: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, StoreMutationResult>> toggleStoreStatus(
    String storeId,
  ) async {
    try {
      final result = await remoteDataSource.toggleStoreStatus(storeId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('Failed to toggle store status: ${e.toString()}'));
    }
  }
}
