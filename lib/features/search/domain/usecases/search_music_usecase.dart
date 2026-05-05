import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/search_result.dart';
import '../repositories/search_repository.dart';

class SearchMusicUseCase {
  SearchMusicUseCase(this.repository);

  final SearchRepository repository;

  Future<Either<Failure, List<SearchResult>>> call(
    String query, {
    bool playableTracksOnly = false,
  }) =>
      repository.search(
        query,
        playableTracksOnly: playableTracksOnly,
      );
}
