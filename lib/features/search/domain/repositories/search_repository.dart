import '../../../home/domain/entities/playlist_entity.dart';
import '../entities/album_entity.dart';
import '../entities/artist_entity.dart';
import '../entities/search_category.dart';
import '../entities/search_result.dart';

/// Contract that the data layer must fulfil.
abstract class SearchRepository {
  /// Returns all browsable categories.
  Future<List<SearchCategory>> getCategories();

  /// Returns search results for [query] (mixed — all types).
  Future<List<SearchResult>> search(String query);

  /// Returns search results filtered to a specific [type].
  Future<List<SearchResult>> searchByType(String query, SearchResultType type);

  /// Returns full artist details including popular songs & albums.
  Future<ArtistEntity> getArtistDetail(String artistId);

  /// Returns full album details including song list.
  Future<AlbumEntity> getAlbumDetail(String albumId);

  /// Returns full playlist details including song list.
  Future<PlaylistEntity> getPlaylistDetail(String playlistId);

  /// Returns playlists belonging to a specific category.
  Future<List<PlaylistEntity>> getCategoryPlaylists(String categoryId);

  /// Returns featured / curated playlists for the "Featuring" tab.
  Future<List<PlaylistEntity>> getFeaturedPlaylists();
}
