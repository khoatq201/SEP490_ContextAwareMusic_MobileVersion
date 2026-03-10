import '../entities/search_result.dart';
import '../repositories/search_repository.dart';

class SearchByTypeUseCase {
  final SearchRepository repository;
  SearchByTypeUseCase(this.repository);

  Future<List<SearchResult>> call(String query, SearchResultType type) =>
      repository.searchByType(query, type);
}
