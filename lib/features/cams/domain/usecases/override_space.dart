import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/override_response_model.dart';
import '../../data/repositories/cams_repository_impl.dart';

class OverrideSpace {
  final CamsRepository repository;

  OverrideSpace(this.repository);

  Future<Either<Failure, OverrideResponse>> call({
    required String spaceId,
    List<String>? trackIds,
    String? playlistId,
    String? moodId,
    bool? isClearManagerSelectedQueues,
    String? reason,
    bool usePlaybackDeviceScope = false,
  }) {
    return repository.overrideSpace(
      spaceId: spaceId,
      trackIds: trackIds,
      playlistId: playlistId,
      moodId: moodId,
      isClearManagerSelectedQueues: isClearManagerSelectedQueues,
      reason: reason,
      usePlaybackDeviceScope: usePlaybackDeviceScope,
    );
  }
}
