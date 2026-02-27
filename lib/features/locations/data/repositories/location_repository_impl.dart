import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
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
  Future<Either<Failure, List<LocationSpace>>> getSpacesForStore(String storeId) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getSpacesForStore(storeId);
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
  Future<Either<Failure, Map<String, List<LocationSpace>>>> getSpacesForBrand(List<String> storeIds) async {
     if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getSpacesForBrand(storeIds);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Unexpected error: $e'));
      }
    }
    return const Left(NetworkFailure('No internet connection'));
  }
}
