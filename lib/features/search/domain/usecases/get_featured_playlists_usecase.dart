import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../home/domain/entities/playlist_entity.dart';
import '../repositories/search_repository.dart';

class GetFeaturedPlaylistsUseCase {
  GetFeaturedPlaylistsUseCase(this.repository);

  final SearchRepository repository;

  Future<Either<Failure, List<PlaylistEntity>>> call() =>
      repository.getFeaturedPlaylists();
}
