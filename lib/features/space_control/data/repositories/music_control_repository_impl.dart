import 'package:dartz/dartz.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/music_player_state.dart';
import '../../domain/repositories/music_control_repository.dart';
import '../datasources/music_control_remote_datasource.dart';

class MusicControlRepositoryImpl implements MusicControlRepository {
  final MusicControlRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  MusicControlRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, void>> overrideMood({
    required String spaceId,
    required String moodId,
    required int manualOverrideTtlSeconds,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await remoteDataSource.overrideMood(
        spaceId: spaceId,
        moodId: moodId,
        manualOverrideTtlSeconds: manualOverrideTtlSeconds,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ErrorMapper.toFailure(
          e,
          fallbackMessage: 'Unable to change the mood right now.',
        ),
      );
    } on NetworkException catch (e) {
      return Left(
        ErrorMapper.toFailure(
          e,
          fallbackMessage: 'Check your internet connection and try again.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> play(String spaceId) async {
    return _sendMusicControl(spaceId, 'play');
  }

  @override
  Future<Either<Failure, void>> pause(String spaceId) async {
    return _sendMusicControl(spaceId, 'pause');
  }

  @override
  Future<Either<Failure, void>> skip(String spaceId) async {
    return _sendMusicControl(spaceId, 'skip');
  }

  Future<Either<Failure, void>> _sendMusicControl(
    String spaceId,
    String action,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await remoteDataSource.sendMusicControl(spaceId, action);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ErrorMapper.toFailure(
          e,
          fallbackMessage: 'Unable to control playback right now.',
        ),
      );
    } on NetworkException catch (e) {
      return Left(
        ErrorMapper.toFailure(
          e,
          fallbackMessage: 'Check your internet connection and try again.',
        ),
      );
    }
  }

  @override
  Stream<MusicPlayerState> subscribeMusicPlayerState(
    String storeId,
    String spaceId,
  ) {
    return remoteDataSource
        .subscribeMusicPlayerState(storeId, spaceId)
        .map((model) => model.toEntity());
  }

  @override
  void unsubscribeMusicPlayerState(String storeId, String spaceId) {
    remoteDataSource.unsubscribeMusicPlayerState(storeId, spaceId);
  }
}
