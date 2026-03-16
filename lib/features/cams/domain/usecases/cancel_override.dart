import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/repositories/cams_repository_impl.dart';

class CancelOverride {
  final CamsRepository repository;

  CancelOverride(this.repository);

  Future<Either<Failure, void>> call(
    String spaceId, {
    bool usePlaybackDeviceScope = false,
  }) {
    return repository.cancelOverride(
      spaceId,
      usePlaybackDeviceScope: usePlaybackDeviceScope,
    );
  }
}
