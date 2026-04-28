import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../home/domain/entities/playlist_entity.dart';
import '../../domain/entities/search_category.dart';
import '../../domain/entities/search_filter_tag.dart';
import '../../domain/entities/search_result.dart';

enum SearchStatus { initial, loading, success, failure }

class SearchState extends Equatable {
  const SearchState({
    this.status = SearchStatus.initial,
    this.categories = const [],
    this.results = const [],
    this.query = '',
    this.failure,
    this.activeTag = SearchFilterTag.all,
    this.featuredPlaylists = const [],
  });

  final SearchStatus status;
  final List<SearchCategory> categories;
  final List<SearchResult> results;
  final String query;
  final Failure? failure;
  final SearchFilterTag activeTag;
  final List<PlaylistEntity> featuredPlaylists;

  bool get isSearching => query.isNotEmpty;
  String? get errorMessage => failure?.message;

  List<SearchResult> get artistResults =>
      results.where((result) => result.type == SearchResultType.artist).toList();

  List<SearchResult> get playlistResults => results
      .where((result) => result.type == SearchResultType.playlist)
      .toList();

  List<SearchResult> get songResults =>
      results.where((result) => result.type == SearchResultType.song).toList();

  List<SearchResult> get albumResults =>
      results.where((result) => result.type == SearchResultType.album).toList();

  List<SearchResult> get categoryResults => results
      .where((result) => result.type == SearchResultType.category)
      .toList();

  SearchState copyWith({
    SearchStatus? status,
    List<SearchCategory>? categories,
    List<SearchResult>? results,
    String? query,
    Failure? failure,
    bool clearFailure = false,
    SearchFilterTag? activeTag,
    List<PlaylistEntity>? featuredPlaylists,
  }) {
    return SearchState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      results: results ?? this.results,
      query: query ?? this.query,
      failure: clearFailure ? null : (failure ?? this.failure),
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
        failure,
        activeTag,
        featuredPlaylists,
      ];
}
