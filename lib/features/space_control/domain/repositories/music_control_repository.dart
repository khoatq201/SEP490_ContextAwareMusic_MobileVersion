import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/music_player_state.dart';

abstract class MusicControlRepository {
  /// Override mood for a space
  Future<Either<Failure, void>> overrideMood({
    required String spaceId,
    required String moodId,
    required int duration,
  });

  /// Send play command to Hub
  Future<Either<Failure, void>> play(String spaceId);

  /// Send pause command to Hub
  Future<Either<Failure, void>> pause(String spaceId);

  /// Send skip command to Hub
  Future<Either<Failure, void>> skip(String spaceId);

  /// Subscribe to music player state updates
  Stream<MusicPlayerState> subscribeMusicPlayerState(
      String storeId, String spaceId);

  /// Unsubscribe from music player state
  void unsubscribeMusicPlayerState(String storeId, String spaceId);
}
