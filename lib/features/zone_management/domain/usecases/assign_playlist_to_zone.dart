import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../repositories/music_profile_repository.dart';

/// Use case to assign a playlist to a zone's music profile
class AssignPlaylistToZone {
  final MusicProfileRepository repository;

  AssignPlaylistToZone(this.repository);

  Future<Either<Failure, void>> call(AssignPlaylistParams params) async {
    return await repository.assignPlaylistToZone(
      zoneId: params.zoneId,
      playlistId: params.playlistId,
    );
  }
}

class AssignPlaylistParams extends Equatable {
  final String zoneId;
  final String playlistId;

  const AssignPlaylistParams({
    required this.zoneId,
    required this.playlistId,
  });

  @override
  List<Object?> get props => [zoneId, playlistId];
}
