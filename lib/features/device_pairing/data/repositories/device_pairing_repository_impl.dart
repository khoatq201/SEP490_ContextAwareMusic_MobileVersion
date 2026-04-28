import 'package:dartz/dartz.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../cams/data/datasources/cams_remote_datasource.dart';
import '../../domain/entities/pairing_result.dart';
import '../../domain/repositories/device_pairing_repository.dart';
import '../datasources/device_pairing_remote_datasource.dart';

class DevicePairingRepositoryImpl implements DevicePairingRepository {
  DevicePairingRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.localStorage,
    required this.dioClient,
    required this.camsRemoteDataSource,
  });

  final DevicePairingRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final LocalStorageService localStorage;
  final DioClient dioClient;
  final CamsRemoteDataSource camsRemoteDataSource;

  @override
  Future<Either<Failure, DeviceAuthSession>> pairDevice({
    required String code,
    String? manufacturer,
    String? model,
    String? osVersion,
    String? appVersion,
    String? deviceId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      var result = await remoteDataSource.pairDevice(
        code: code,
        manufacturer: manufacturer,
        model: model,
        osVersion: osVersion,
        appVersion: appVersion,
        deviceId: deviceId,
      );
      await localStorage.clearManagerSession();
      await dioClient.clearCookies();
      await localStorage.saveDeviceSession(result.toJson());
      await localStorage.saveActiveSessionMode(
        LocalStorageService.sessionModePlaybackDevice,
      );

      try {
        final pairInfo =
            await camsRemoteDataSource.getPairDeviceInfoForPlaybackDevice();
        result = result.copyWith(
          brandId: pairInfo.brandId,
          storeId: pairInfo.storeId,
          spaceId: pairInfo.spaceId,
          deviceId: pairInfo.deviceId ?? result.deviceId,
        );
        await localStorage.updateDeviceSession({
          'brandId': pairInfo.brandId,
          'storeId': pairInfo.storeId,
          'spaceId': pairInfo.spaceId,
          if ((pairInfo.deviceId ?? '').isNotEmpty)
            'deviceId': pairInfo.deviceId,
        });
      } catch (_) {}

      return Right(result);
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not pair this device right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
