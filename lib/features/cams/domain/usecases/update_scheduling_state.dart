import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/repositories/cams_repository_impl.dart';

class UpdateSchedulingStateParams {
  final String spaceId;
  final bool isScheduling;
  final bool usePlaybackDeviceScope;

  const UpdateSchedulingStateParams({
    required this.spaceId,
    required this.isScheduling,
    this.usePlaybackDeviceScope = false,
  });
}

class UpdateSchedulingState {
  final CamsRepository repository;

  UpdateSchedulingState(this.repository);

  Future<Either<Failure, void>> call(UpdateSchedulingStateParams params) {
    return repository.updateSchedulingState(
      spaceId: params.spaceId,
      isScheduling: params.isScheduling,
      usePlaybackDeviceScope: params.usePlaybackDeviceScope,
    );
  }
}
