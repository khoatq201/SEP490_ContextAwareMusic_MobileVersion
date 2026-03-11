import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/api_playlist.dart';
import '../datasources/playlist_remote_datasource.dart';

abstract class PlaylistRepository {
  Future<Either<Failure, PlaylistListResponse>> getPlaylists({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? storeId,
    String? moodId,
    bool? isDynamic,
    bool? isDefault,
  });

  Future<Either<Failure, ApiPlaylist>> getPlaylistById(String playlistId);
}

class PlaylistRepositoryImpl implements PlaylistRepository {
  final PlaylistRemoteDataSource remoteDataSource;

  PlaylistRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, PlaylistListResponse>> getPlaylists({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? storeId,
    String? moodId,
    bool? isDynamic,
    bool? isDefault,
  }) async {
    try {
      final result = await remoteDataSource.getPlaylists(
        page: page,
        pageSize: pageSize,
        search: search,
        storeId: storeId,
        moodId: moodId,
        isDynamic: isDynamic,
        isDefault: isDefault,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch playlists: $e'));
    }
  }

  @override
  Future<Either<Failure, ApiPlaylist>> getPlaylistById(
      String playlistId) async {
    try {
      final playlist = await remoteDataSource.getPlaylistById(playlistId);
      return Right(playlist);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch playlist detail: $e'));
    }
  }
}
