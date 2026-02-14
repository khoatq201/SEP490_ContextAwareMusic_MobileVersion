import 'package:dartz/dartz.dart';
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
    required int duration,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await remoteDataSource.overrideMood(
        spaceId: spaceId,
        moodId: moodId,
        duration: duration,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
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
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
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
