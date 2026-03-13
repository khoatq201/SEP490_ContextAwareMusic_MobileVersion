import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/repositories/cams_repository_impl.dart';
import '../entities/space_playback_state.dart';

class GetSpaceState {
  final CamsRepository repository;

  GetSpaceState(this.repository);

  Future<Either<Failure, SpacePlaybackState>> call(String spaceId) {
    return repository.getSpaceState(spaceId);
  }
}
