import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/mood.dart';
import '../datasources/mood_remote_datasource.dart';

abstract class MoodRepository {
  Future<Either<Failure, List<Mood>>> getMoods();
}

class MoodRepositoryImpl implements MoodRepository {
  final MoodRemoteDataSource remoteDataSource;

  MoodRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Mood>>> getMoods() async {
    try {
      final moods = await remoteDataSource.getMoods();
      return Right(moods);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch moods: $e'));
    }
  }
}
