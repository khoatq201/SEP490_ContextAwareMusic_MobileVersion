import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/enums/playback_command_enum.dart';
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
  });

  /// Cancel active override.
  Future<Either<Failure, void>> cancelOverride(String spaceId);

  /// Send playback command.
  Future<Either<Failure, void>> sendPlaybackCommand({
    required String spaceId,
    required PlaybackCommandEnum command,
    double? seekPositionSeconds,
    String? targetTrackId,
  });

  /// Get current playback state.
  Future<Either<Failure, SpacePlaybackState>> getSpaceState(String spaceId);
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
  }) async {
    try {
      final result = await remoteDataSource.overrideSpace(
        spaceId: spaceId,
        playlistId: playlistId,
        moodId: moodId,
        reason: reason,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to override space: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelOverride(String spaceId) async {
    try {
      await remoteDataSource.cancelOverride(spaceId);
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
  }) async {
    try {
      await remoteDataSource.sendPlaybackCommand(
        spaceId: spaceId,
        command: command,
        seekPositionSeconds: seekPositionSeconds,
        targetTrackId: targetTrackId,
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
      String spaceId) async {
    try {
      final state = await remoteDataSource.getSpaceState(spaceId);
      return Right(state);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get space state: $e'));
    }
  }
}
