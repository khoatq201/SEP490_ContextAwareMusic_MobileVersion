import '../entities/space.dart';
import '../repositories/space_repository.dart';

class SubscribeToSpaceStatus {
  final SpaceRepository repository;

  SubscribeToSpaceStatus(this.repository);

  Stream<Space> call(String storeId, String spaceId) {
    return repository.subscribeToSpaceStatus(storeId, spaceId);
  }
}
