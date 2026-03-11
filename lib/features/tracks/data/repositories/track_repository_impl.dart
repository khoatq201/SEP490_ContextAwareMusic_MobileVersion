import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/api_track.dart';
import '../datasources/track_remote_datasource.dart';

abstract class TrackRepository {
  Future<Either<Failure, TrackListResponse>> getTracks({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? moodId,
    String? genre,
  });

  Future<Either<Failure, ApiTrack>> getTrackById(String trackId);
}

class TrackRepositoryImpl implements TrackRepository {
  final TrackRemoteDataSource remoteDataSource;

  TrackRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, TrackListResponse>> getTracks({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? moodId,
    String? genre,
  }) async {
    try {
      final result = await remoteDataSource.getTracks(
        page: page,
        pageSize: pageSize,
        search: search,
        moodId: moodId,
        genre: genre,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch tracks: $e'));
    }
  }

  @override
  Future<Either<Failure, ApiTrack>> getTrackById(String trackId) async {
    try {
      final track = await remoteDataSource.getTrackById(trackId);
      return Right(track);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch track detail: $e'));
    }
  }
}
