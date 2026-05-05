import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/search_result.dart';
import '../repositories/search_repository.dart';

class SearchByTypeUseCase {
  SearchByTypeUseCase(this.repository);

  final SearchRepository repository;

  Future<Either<Failure, List<SearchResult>>> call(
    String query,
    SearchResultType type, {
    bool playableTracksOnly = false,
  }) =>
      repository.searchByType(
        query,
        type,
        playableTracksOnly: playableTracksOnly,
      );
}
