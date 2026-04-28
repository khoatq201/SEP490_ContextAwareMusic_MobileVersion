import 'package:dartz/dartz.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/offline_playlist.dart';
import '../../domain/repositories/offline_playlist_repository.dart';
import '../datasources/offline_playlist_datasource.dart';

class OfflinePlaylistRepositoryImpl implements OfflinePlaylistRepository {
  final OfflinePlaylistDataSource dataSource;

  OfflinePlaylistRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<OfflinePlaylist>>> getAvailablePlaylists() async {
    try {
      final playlists = await dataSource.getAvailablePlaylists();
      return Right(playlists);
    } catch (e) {
      return Left(
        ErrorMapper.toFailure(
          e,
          fallbackMessage: 'Unable to load offline playlists right now.',
        ),
      );
    }
  }

  @override
  Stream<Either<Failure, double>> downloadPlaylist(String playlistId) async* {
    try {
      await for (final progress in dataSource.downloadPlaylist(playlistId)) {
        yield Right(progress);
      }
    } catch (e) {
      yield Left(
        ErrorMapper.toFailure(
          e,
          fallbackMessage: 'Unable to download this playlist right now.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteLocalPlaylist(String playlistId) async {
    try {
      await dataSource.deletePlaylist(playlistId);
      return const Right(null);
    } catch (e) {
      return Left(
        ErrorMapper.toFailure(
          e,
          fallbackMessage: 'Unable to remove the downloaded playlist.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<OfflinePlaylist>>>
      getDownloadedPlaylists() async {
    try {
      // Filter downloaded playlists from local storage
      final allPlaylists = await dataSource.getAvailablePlaylists();
      final downloaded = allPlaylists
          .where((p) => p.downloadStatus == DownloadStatus.downloaded)
          .toList();
      return Right(downloaded);
    } catch (e) {
      return Left(
        ErrorMapper.toFailure(
          e,
          fallbackMessage: 'Unable to load downloaded playlists right now.',
        ),
      );
    }
  }
}
