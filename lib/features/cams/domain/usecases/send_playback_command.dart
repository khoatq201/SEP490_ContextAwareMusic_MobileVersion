import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/enums/playback_command_enum.dart';
import '../../data/repositories/cams_repository_impl.dart';

class SendPlaybackCommand {
  final CamsRepository repository;

  SendPlaybackCommand(this.repository);

  Future<Either<Failure, void>> call({
    required String spaceId,
    required PlaybackCommandEnum command,
    double? seekPositionSeconds,
    String? targetTrackId,
  }) {
    return repository.sendPlaybackCommand(
      spaceId: spaceId,
      command: command,
      seekPositionSeconds: seekPositionSeconds,
      targetTrackId: targetTrackId,
    );
  }
}
