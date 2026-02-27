/// A lightweight result item returned by a song/artist search.
class SearchResult {
  final String id;
  final String title;
  final String subtitle; // artist name or type label
  final String? thumbnailUrl;
  final SearchResultType type;

  const SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    this.thumbnailUrl,
    required this.type,
  });
}

enum SearchResultType { song, artist, playlist }
