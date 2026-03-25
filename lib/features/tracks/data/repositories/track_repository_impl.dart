import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/api_track.dart';
import '../../domain/entities/track_filter.dart';
import '../datasources/track_remote_datasource.dart';

abstract class TrackRepository {
  Future<Either<Failure, TrackListResponse>> getTracks({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? moodId,
    String? genre,
    TrackFilter? filter,
  });

  Future<Either<Failure, ApiTrack>> getTrackById(String trackId);

  Future<Either<Failure, TrackMutationResult>> createTrack(
    CreateTrackRequest request,
  );

  Future<Either<Failure, TrackMutationResult>> updateTrack(
    String trackId,
    UpdateTrackRequest request,
  );

  Future<Either<Failure, TrackMutationResult>> deleteTrack(String trackId);

  Future<Either<Failure, TrackMutationResult>> toggleTrackStatus(
    String trackId,
  );

  Future<Either<Failure, TrackMutationResult>> retranscodeTrack(String trackId);
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
    TrackFilter? filter,
  }) async {
    try {
      final result = await remoteDataSource.getTracks(
        page: page,
        pageSize: pageSize,
        search: search,
        moodId: moodId,
        genre: genre,
        filter: filter,
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

  @override
  Future<Either<Failure, TrackMutationResult>> createTrack(
    CreateTrackRequest request,
  ) async {
    try {
      final result = await remoteDataSource.createTrack(request);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to create track: $e'));
    }
  }

  @override
  Future<Either<Failure, TrackMutationResult>> updateTrack(
    String trackId,
    UpdateTrackRequest request,
  ) async {
    try {
      final result = await remoteDataSource.updateTrack(trackId, request);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to update track: $e'));
    }
  }

  @override
  Future<Either<Failure, TrackMutationResult>> deleteTrack(
    String trackId,
  ) async {
    try {
      final result = await remoteDataSource.deleteTrack(trackId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to delete track: $e'));
    }
  }

  @override
  Future<Either<Failure, TrackMutationResult>> toggleTrackStatus(
    String trackId,
  ) async {
    try {
      final result = await remoteDataSource.toggleTrackStatus(trackId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to toggle track status: $e'));
    }
  }

  @override
  Future<Either<Failure, TrackMutationResult>> retranscodeTrack(
    String trackId,
  ) async {
    try {
      final result = await remoteDataSource.retranscodeTrack(trackId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to retranscode track: $e'));
    }
  }
}
