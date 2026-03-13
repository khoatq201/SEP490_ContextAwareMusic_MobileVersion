import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/mood.dart';
import '../../data/repositories/mood_repository_impl.dart';

class GetMoods {
  final MoodRepository repository;

  GetMoods(this.repository);

  Future<Either<Failure, List<Mood>>> call() {
    return repository.getMoods();
  }
}
