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
}
