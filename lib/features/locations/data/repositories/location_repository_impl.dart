import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/pagination_result.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/location_space.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_remote_datasource.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  LocationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, LocationSpace>> getPairedSpace(String spaceId, String storeId) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getSpace(spaceId, storeId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Unexpected error: $e'));
      }
    }
    return const Left(NetworkFailure('No internet connection'));
  }

  @override
  Future<Either<Failure, PaginationResult<LocationSpace>>> getSpacesForStore(String storeId, {int page = 1, int pageSize = 10}) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getSpacesForStore(storeId, page: page, pageSize: pageSize);
        // Cast the paginated model list to entity list without mapping, 
        // since LocationSpaceModel extends LocationSpace and the type is covariant.
        return Right(PaginationResult<LocationSpace>(
          currentPage: result.currentPage,
          pageSize: result.pageSize,
          totalItems: result.totalItems,
          totalPages: result.totalPages,
          hasPrevious: result.hasPrevious,
          hasNext: result.hasNext,
          items: result.items, // covariant casting
        ));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Unexpected error: $e'));
      }
    }
    return const Left(NetworkFailure('No internet connection'));
  }

  @override
  Future<Either<Failure, Map<String, PaginationResult<LocationSpace>>>> getSpacesForBrand(List<String> storeIds, {int page = 1, int pageSize = 10}) async {
     if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getSpacesForBrand(storeIds, page: page, pageSize: pageSize);
        final resultMap = result.map((key, paginationModel) => MapEntry(
            key, 
            PaginationResult<LocationSpace>(
              currentPage: paginationModel.currentPage,
              pageSize: paginationModel.pageSize,
              totalItems: paginationModel.totalItems,
              totalPages: paginationModel.totalPages,
              hasPrevious: paginationModel.hasPrevious,
              hasNext: paginationModel.hasNext,
              items: paginationModel.items,
            )
        ));
        return Right(resultMap);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Unexpected error: $e'));
      }
    }
    return const Left(NetworkFailure('No internet connection'));
  }
}

