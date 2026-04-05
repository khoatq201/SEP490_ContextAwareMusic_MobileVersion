import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/album_entity.dart';
import '../repositories/search_repository.dart';

class GetAlbumDetailUseCase {
  GetAlbumDetailUseCase(this.repository);

  final SearchRepository repository;

  Future<Either<Failure, AlbumEntity>> call(String albumId) =>
      repository.getAlbumDetail(albumId);
}
