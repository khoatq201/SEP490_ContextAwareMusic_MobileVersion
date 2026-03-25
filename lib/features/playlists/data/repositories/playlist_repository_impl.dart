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
    String? sortBy,
    bool? isAscending,
    int? status,
    String? brandId,
    String? storeId,
    String? moodId,
    bool? isDynamic,
    bool? isDefault,
    DateTime? createdFrom,
    DateTime? createdTo,
  });

  Future<Either<Failure, ApiPlaylist>> getPlaylistById(String playlistId);

  Future<Either<Failure, PlaylistMutationResult>> createPlaylist(
    PlaylistMutationRequest request,
  );

  Future<Either<Failure, PlaylistMutationResult>> updatePlaylist(
    String playlistId,
    PlaylistMutationRequest request,
  );

  Future<Either<Failure, PlaylistMutationResult>> deletePlaylist(
    String playlistId,
  );

  Future<Either<Failure, PlaylistMutationResult>> togglePlaylistStatus(
    String playlistId,
  );

  Future<Either<Failure, PlaylistMutationResult>> addTracksToPlaylist({
    required String playlistId,
    required List<String> trackIds,
  });

  Future<Either<Failure, PlaylistMutationResult>> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  });

  Future<Either<Failure, PlaylistMutationResult>> retranscodePlaylist(
    String playlistId,
  );
}

class PlaylistRepositoryImpl implements PlaylistRepository {
  final PlaylistRemoteDataSource remoteDataSource;

  PlaylistRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, PlaylistListResponse>> getPlaylists({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? sortBy,
    bool? isAscending,
    int? status,
    String? brandId,
    String? storeId,
    String? moodId,
    bool? isDynamic,
    bool? isDefault,
    DateTime? createdFrom,
    DateTime? createdTo,
  }) async {
    try {
      final result = await remoteDataSource.getPlaylists(
        page: page,
        pageSize: pageSize,
        search: search,
        sortBy: sortBy,
        isAscending: isAscending,
        status: status,
        brandId: brandId,
        storeId: storeId,
        moodId: moodId,
        isDynamic: isDynamic,
        isDefault: isDefault,
        createdFrom: createdFrom,
        createdTo: createdTo,
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

  @override
  Future<Either<Failure, PlaylistMutationResult>> createPlaylist(
    PlaylistMutationRequest request,
  ) async {
    try {
      final result = await remoteDataSource.createPlaylist(request);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to create playlist: $e'));
    }
  }

  @override
  Future<Either<Failure, PlaylistMutationResult>> updatePlaylist(
    String playlistId,
    PlaylistMutationRequest request,
  ) async {
    try {
      final result = await remoteDataSource.updatePlaylist(playlistId, request);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to update playlist: $e'));
    }
  }

  @override
  Future<Either<Failure, PlaylistMutationResult>> deletePlaylist(
    String playlistId,
  ) async {
    try {
      final result = await remoteDataSource.deletePlaylist(playlistId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to delete playlist: $e'));
    }
  }

  @override
  Future<Either<Failure, PlaylistMutationResult>> togglePlaylistStatus(
    String playlistId,
  ) async {
    try {
      final result = await remoteDataSource.togglePlaylistStatus(playlistId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to toggle playlist status: $e'));
    }
  }

  @override
  Future<Either<Failure, PlaylistMutationResult>> addTracksToPlaylist({
    required String playlistId,
    required List<String> trackIds,
  }) async {
    try {
      final result = await remoteDataSource.addTracksToPlaylist(
        playlistId: playlistId,
        trackIds: trackIds,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to add tracks to playlist: $e'));
    }
  }

  @override
  Future<Either<Failure, PlaylistMutationResult>> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    try {
      final result = await remoteDataSource.removeTrackFromPlaylist(
        playlistId: playlistId,
        trackId: trackId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to remove track from playlist: $e'));
    }
  }

  @override
  Future<Either<Failure, PlaylistMutationResult>> retranscodePlaylist(
    String playlistId,
  ) async {
    try {
      final result = await remoteDataSource.retranscodePlaylist(playlistId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to retranscode playlist: $e'));
    }
  }
}
