/// A lightweight result item returned by a song/artist search.
class SearchResult {
  final String id;
  final String title;
  final String subtitle; // artist name or type label
  final String? thumbnailUrl;
  final String? imageUrl;
  final SearchResultType type;

  /// Optional duration string for songs (e.g. "3:25")
  final String? duration;

  const SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    this.thumbnailUrl,
    this.imageUrl,
    required this.type,
    this.duration,
  });
}

enum SearchResultType { song, artist, playlist, album, category }
