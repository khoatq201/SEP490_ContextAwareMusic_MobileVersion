import '../entities/music_player_state.dart';
import '../repositories/music_control_repository.dart';

class SubscribeMusicPlayerState {
  final MusicControlRepository repository;

  SubscribeMusicPlayerState(this.repository);

  Stream<MusicPlayerState> call(String storeId, String spaceId) {
    return repository.subscribeMusicPlayerState(storeId, spaceId);
  }
}
