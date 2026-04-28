import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../home/domain/entities/playlist_entity.dart';
import '../entities/album_entity.dart';
import '../entities/artist_entity.dart';
import '../entities/search_category.dart';
import '../entities/search_result.dart';

abstract class SearchRepository {
  Future<Either<Failure, List<SearchCategory>>> getCategories();

  Future<Either<Failure, List<SearchResult>>> search(String query);

  Future<Either<Failure, List<SearchResult>>> searchByType(
    String query,
    SearchResultType type,
  );

  Future<Either<Failure, ArtistEntity>> getArtistDetail(String artistId);

  Future<Either<Failure, AlbumEntity>> getAlbumDetail(String albumId);

  Future<Either<Failure, PlaylistEntity>> getPlaylistDetail(String playlistId);

  Future<Either<Failure, List<PlaylistEntity>>> getCategoryPlaylists(
    String categoryId,
  );

  Future<Either<Failure, List<PlaylistEntity>>> getFeaturedPlaylists();
}
