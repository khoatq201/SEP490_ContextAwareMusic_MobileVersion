import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/override_response_model.dart';
import '../../data/repositories/cams_repository_impl.dart';

class OverrideSpace {
  final CamsRepository repository;

  OverrideSpace(this.repository);

  Future<Either<Failure, OverrideResponse>> call({
    required String spaceId,
    String? playlistId,
    String? moodId,
    String? reason,
    bool usePlaybackDeviceScope = false,
  }) {
    return repository.overrideSpace(
      spaceId: spaceId,
      playlistId: playlistId,
      moodId: moodId,
      reason: reason,
      usePlaybackDeviceScope: usePlaybackDeviceScope,
    );
  }
}
