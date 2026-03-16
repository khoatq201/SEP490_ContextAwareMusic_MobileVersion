import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/repositories/cams_repository_impl.dart';
import '../entities/pair_code_snapshot.dart';
import '../entities/pair_device_info.dart';
import '../entities/space_playback_state.dart';

class GetPairDeviceInfoForManager {
  final CamsRepository repository;

  GetPairDeviceInfoForManager(this.repository);

  Future<Either<Failure, PairDeviceInfo>> call(String spaceId) {
    return repository.getPairDeviceInfoForManager(spaceId);
  }
}

class GetPairDeviceInfoForPlaybackDevice {
  final CamsRepository repository;

  GetPairDeviceInfoForPlaybackDevice(this.repository);

  Future<Either<Failure, PairDeviceInfo>> call() {
    return repository.getPairDeviceInfoForPlaybackDevice();
  }
}

class GeneratePairCode {
  final CamsRepository repository;

  GeneratePairCode(this.repository);

  Future<Either<Failure, PairCodeSnapshot>> call(String spaceId) {
    return repository.generatePairCode(spaceId);
  }
}

class RevokePairCode {
  final CamsRepository repository;

  RevokePairCode(this.repository);

  Future<Either<Failure, void>> call(String spaceId) {
    return repository.revokePairCode(spaceId);
  }
}

class UnpairPlaybackDevice {
  final CamsRepository repository;

  UnpairPlaybackDevice(this.repository);

  Future<Either<Failure, void>> call(String spaceId) {
    return repository.unpairDevice(spaceId);
  }
}

class GetCurrentDeviceSpaceState {
  final CamsRepository repository;

  GetCurrentDeviceSpaceState(this.repository);

  Future<Either<Failure, SpacePlaybackState>> call() {
    return repository.getSpaceStateForPlaybackDevice();
  }
}
