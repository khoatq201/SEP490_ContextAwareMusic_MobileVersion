import 'package:equatable/equatable.dart';
import '../../../home/domain/entities/playlist_entity.dart';
import '../../domain/entities/search_category.dart';
import '../../domain/entities/search_filter_tag.dart';
import '../../domain/entities/search_result.dart';

enum SearchStatus { initial, loading, success, failure }

class SearchState extends Equatable {
  final SearchStatus status;
  final List<SearchCategory> categories;
  final List<SearchResult> results;
  final String query;
  final String? errorMessage;
  final SearchFilterTag activeTag;
  final List<PlaylistEntity> featuredPlaylists;

  const SearchState({
    this.status = SearchStatus.initial,
    this.categories = const [],
    this.results = const [],
    this.query = '',
    this.errorMessage,
    this.activeTag = SearchFilterTag.all,
    this.featuredPlaylists = const [],
  });

  bool get isSearching => query.isNotEmpty;

  /// Convenience getters to filter results by type.
  List<SearchResult> get artistResults =>
      results.where((r) => r.type == SearchResultType.artist).toList();

  List<SearchResult> get playlistResults =>
      results.where((r) => r.type == SearchResultType.playlist).toList();

  List<SearchResult> get songResults =>
      results.where((r) => r.type == SearchResultType.song).toList();

  List<SearchResult> get albumResults =>
      results.where((r) => r.type == SearchResultType.album).toList();

  List<SearchResult> get categoryResults =>
      results.where((r) => r.type == SearchResultType.category).toList();

  SearchState copyWith({
    SearchStatus? status,
    List<SearchCategory>? categories,
    List<SearchResult>? results,
    String? query,
    String? errorMessage,
    SearchFilterTag? activeTag,
    List<PlaylistEntity>? featuredPlaylists,
  }) {
    return SearchState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      results: results ?? this.results,
      query: query ?? this.query,
      errorMessage: errorMessage ?? this.errorMessage,
      activeTag: activeTag ?? this.activeTag,
      featuredPlaylists: featuredPlaylists ?? this.featuredPlaylists,
    );
  }

  @override
  List<Object?> get props => [
        status,
        categories,
        results,
        query,
        errorMessage,
        activeTag,
        featuredPlaylists,
      ];
}
