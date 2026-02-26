import 'package:dartz/dartz.dart';
import '../../domain/entities/pairing_result.dart';
import '../../domain/repositories/device_pairing_repository.dart';
import '../datasources/device_pairing_remote_datasource.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';

class DevicePairingRepositoryImpl implements DevicePairingRepository {
  final DevicePairingRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  DevicePairingRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, PairingResult>> pairDevice(String pairCode) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.pairDevice(pairCode);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('An unexpected error occurred: $e'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}
