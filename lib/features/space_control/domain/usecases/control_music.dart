import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/music_control_repository.dart';

class ControlMusic {
  final MusicControlRepository repository;

  ControlMusic(this.repository);

  Future<Either<Failure, void>> play(String spaceId) {
    return repository.play(spaceId);
  }

  Future<Either<Failure, void>> pause(String spaceId) {
    return repository.pause(spaceId);
  }

  Future<Either<Failure, void>> skip(String spaceId) {
    return repository.skip(spaceId);
  }
}
