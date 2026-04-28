/// Filter tags for the search screen — maps to the horizontal chip row.
enum SearchFilterTag {
  all('All'),
  featuring('Featuring'),
  playlists('Playlists'),
  artists('Artists'),
  songs('Songs'),
  albums('Albums'),
  categories('Categories');

  const SearchFilterTag(this.label);
  final String label;
}
