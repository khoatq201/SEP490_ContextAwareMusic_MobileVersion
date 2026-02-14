import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/offline_playlist.dart';
import '../../domain/repositories/offline_playlist_repository.dart';
import '../datasources/offline_playlist_mock_datasource.dart';

class OfflinePlaylistRepositoryImpl implements OfflinePlaylistRepository {
  final OfflinePlaylistMockDatasource mockDatasource;

  OfflinePlaylistRepositoryImpl({required this.mockDatasource});

  @override
  Future<Either<Failure, List<OfflinePlaylist>>> getAvailablePlaylists() async {
    try {
      final playlists = await mockDatasource.getAvailablePlaylists();
      return Right(playlists);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, double>> downloadPlaylist(String playlistId) async* {
    try {
      await for (final progress
          in mockDatasource.downloadPlaylist(playlistId)) {
        yield Right(progress);
      }
    } catch (e) {
      yield Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLocalPlaylist(String playlistId) async {
    try {
      await mockDatasource.deletePlaylist(playlistId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<OfflinePlaylist>>>
      getDownloadedPlaylists() async {
    try {
      // Mock: filter downloaded playlists from local storage
      final allPlaylists = await mockDatasource.getAvailablePlaylists();
      final downloaded = allPlaylists
          .where((p) => p.downloadStatus == DownloadStatus.downloaded)
          .toList();
      return Right(downloaded);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
