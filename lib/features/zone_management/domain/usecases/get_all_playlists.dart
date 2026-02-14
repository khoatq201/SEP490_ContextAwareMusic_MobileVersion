import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/playlist.dart';
import '../repositories/music_profile_repository.dart';

/// Use case to get all available playlists
class GetAllPlaylists {
  final MusicProfileRepository repository;

  GetAllPlaylists(this.repository);

  Future<Either<Failure, List<Playlist>>> call() async {
    return await repository.getAllPlaylists();
  }
}
