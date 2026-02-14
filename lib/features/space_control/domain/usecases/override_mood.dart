import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/music_control_repository.dart';

class OverrideMood {
  final MusicControlRepository repository;

  OverrideMood(this.repository);

  Future<Either<Failure, void>> call({
    required String spaceId,
    required String moodId,
    required int duration,
  }) async {
    return await repository.overrideMood(
      spaceId: spaceId,
      moodId: moodId,
      duration: duration,
    );
  }
}
