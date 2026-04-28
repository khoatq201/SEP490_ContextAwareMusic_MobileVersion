import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/repositories/cams_repository_impl.dart';

class UpdateAudioStateParams {
  final String spaceId;
  final int? volumePercent;
  final bool? isMuted;
  final int? queueEndBehavior;
  final bool usePlaybackDeviceScope;

  const UpdateAudioStateParams({
    required this.spaceId,
    this.volumePercent,
    this.isMuted,
    this.queueEndBehavior,
    this.usePlaybackDeviceScope = false,
  });
}

class UpdateAudioState {
  final CamsRepository repository;

  UpdateAudioState(this.repository);

  Future<Either<Failure, void>> call(UpdateAudioStateParams params) {
    return repository.updateAudioState(
      spaceId: params.spaceId,
      volumePercent: params.volumePercent,
      isMuted: params.isMuted,
      queueEndBehavior: params.queueEndBehavior,
      usePlaybackDeviceScope: params.usePlaybackDeviceScope,
    );
  }
}
