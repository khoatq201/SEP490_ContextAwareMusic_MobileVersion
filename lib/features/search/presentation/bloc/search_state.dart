import 'package:equatable/equatable.dart';
import '../../domain/entities/search_category.dart';
import '../../domain/entities/search_result.dart';

enum SearchStatus { initial, loading, success, failure }

class SearchState extends Equatable {
  final SearchStatus status;
  final List<SearchCategory> categories;
  final List<SearchResult> results;
  final String query;
  final String? errorMessage;

  const SearchState({
    this.status = SearchStatus.initial,
    this.categories = const [],
    this.results = const [],
    this.query = '',
    this.errorMessage,
  });

  bool get isSearching => query.isNotEmpty;

  SearchState copyWith({
    SearchStatus? status,
    List<SearchCategory>? categories,
    List<SearchResult>? results,
    String? query,
    String? errorMessage,
  }) {
    return SearchState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      results: results ?? this.results,
      query: query ?? this.query,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, categories, results, query, errorMessage];
}
