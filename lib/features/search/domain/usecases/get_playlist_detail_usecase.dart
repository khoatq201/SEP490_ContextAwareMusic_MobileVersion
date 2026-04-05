import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../home/domain/entities/playlist_entity.dart';
import '../repositories/search_repository.dart';

class GetPlaylistDetailUseCase {
  GetPlaylistDetailUseCase(this.repository);

  final SearchRepository repository;

  Future<Either<Failure, PlaylistEntity>> call(String playlistId) =>
      repository.getPlaylistDetail(playlistId);
}
