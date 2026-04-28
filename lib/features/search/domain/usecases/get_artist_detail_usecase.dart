import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/artist_entity.dart';
import '../repositories/search_repository.dart';

class GetArtistDetailUseCase {
  GetArtistDetailUseCase(this.repository);

  final SearchRepository repository;

  Future<Either<Failure, ArtistEntity>> call(String artistId) =>
      repository.getArtistDetail(artistId);
}
