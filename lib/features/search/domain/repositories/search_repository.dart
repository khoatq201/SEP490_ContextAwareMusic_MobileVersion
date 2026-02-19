import '../entities/search_category.dart';
import '../entities/search_result.dart';

/// Contract that the data layer must fulfil.
abstract class SearchRepository {
  /// Returns all browsable categories.
  Future<List<SearchCategory>> getCategories();

  /// Returns search results for [query].
  Future<List<SearchResult>> search(String query);
}
