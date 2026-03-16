import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/enums/playback_command_enum.dart';
import '../../domain/entities/pair_code_snapshot.dart';
import '../../domain/entities/pair_device_info.dart';
import '../../domain/entities/space_playback_state.dart';
import '../models/override_response_model.dart';
import '../datasources/cams_remote_datasource.dart';

abstract class CamsRepository {
  /// Override Space music.
  Future<Either<Failure, OverrideResponse>> overrideSpace({
    required String spaceId,
    String? playlistId,
    String? moodId,
    String? reason,
    bool usePlaybackDeviceScope = false,
  });

  /// Cancel active override.
  Future<Either<Failure, void>> cancelOverride(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  });

  /// Send playback command.
  Future<Either<Failure, void>> sendPlaybackCommand({
    required String spaceId,
    required PlaybackCommandEnum command,
    double? seekPositionSeconds,
    String? targetTrackId,
    bool usePlaybackDeviceScope = false,
  });

  /// Get current playback state.
  Future<Either<Failure, SpacePlaybackState>> getSpaceState(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  });

  Future<Either<Failure, SpacePlaybackState>> getSpaceStateForPlaybackDevice();

  Future<Either<Failure, PairDeviceInfo>> getPairDeviceInfoForManager(
    String spaceId,
  );

  Future<Either<Failure, PairDeviceInfo>> getPairDeviceInfoForPlaybackDevice();

  Future<Either<Failure, PairCodeSnapshot>> generatePairCode(String spaceId);

  Future<Either<Failure, void>> revokePairCode(String spaceId);

  Future<Either<Failure, void>> unpairDevice(String spaceId);
}

class CamsRepositoryImpl implements CamsRepository {
  final CamsRemoteDataSource remoteDataSource;

  CamsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, OverrideResponse>> overrideSpace({
    required String spaceId,
    String? playlistId,
    String? moodId,
    String? reason,
    bool usePlaybackDeviceScope = false,
  }) async {
    try {
      final result = await remoteDataSource.overrideSpace(
        spaceId: spaceId,
        playlistId: playlistId,
        moodId: moodId,
        reason: reason,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to override space: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelOverride(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  }) async {
    try {
      await remoteDataSource.cancelOverride(
        spaceId,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to cancel override: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> sendPlaybackCommand({
    required String spaceId,
    required PlaybackCommandEnum command,
    double? seekPositionSeconds,
    String? targetTrackId,
    bool usePlaybackDeviceScope = false,
  }) async {
    try {
      await remoteDataSource.sendPlaybackCommand(
        spaceId: spaceId,
        command: command,
        seekPositionSeconds: seekPositionSeconds,
        targetTrackId: targetTrackId,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to send playback command: $e'));
    }
  }

  @override
  Future<Either<Failure, SpacePlaybackState>> getSpaceState(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  }) async {
    try {
      final state = await remoteDataSource.getSpaceState(
        spaceId,
        usePlaybackDeviceScope: usePlaybackDeviceScope,
      );
      return Right(state);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get space state: $e'));
    }
  }

  @override
  Future<Either<Failure, SpacePlaybackState>> getSpaceStateForPlaybackDevice() async {
    try {
      final state = await remoteDataSource.getSpaceStateForPlaybackDevice();
      return Right(state);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get playback device state: $e'));
    }
  }

  @override
  Future<Either<Failure, PairDeviceInfo>> getPairDeviceInfoForManager(
    String spaceId,
  ) async {
    try {
      final result = await remoteDataSource.getPairDeviceInfoForManager(spaceId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get pair device info: $e'));
    }
  }

  @override
  Future<Either<Failure, PairDeviceInfo>> getPairDeviceInfoForPlaybackDevice() async {
    try {
      final result = await remoteDataSource.getPairDeviceInfoForPlaybackDevice();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get pair device info: $e'));
    }
  }

  @override
  Future<Either<Failure, PairCodeSnapshot>> generatePairCode(
    String spaceId,
  ) async {
    try {
      final result = await remoteDataSource.generatePairCode(spaceId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to generate pair code: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> revokePairCode(String spaceId) async {
    try {
      await remoteDataSource.revokePairCode(spaceId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to revoke pair code: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> unpairDevice(String spaceId) async {
    try {
      await remoteDataSource.unpairDevice(spaceId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to unpair device: $e'));
    }
  }
}
