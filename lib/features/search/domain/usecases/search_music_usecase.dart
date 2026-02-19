import '../entities/search_result.dart';
import '../repositories/search_repository.dart';

class SearchMusicUseCase {
  final SearchRepository repository;
  SearchMusicUseCase(this.repository);

  Future<List<SearchResult>> call(String query) => repository.search(query);
}
