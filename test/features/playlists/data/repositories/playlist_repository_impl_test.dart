import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/error/exceptions.dart';
import 'package:cams_store_manager/core/error/failures.dart';
import 'package:cams_store_manager/features/playlists/data/datasources/playlist_remote_datasource.dart';
import 'package:cams_store_manager/features/playlists/data/models/api_playlist_model.dart';
import 'package:cams_store_manager/features/playlists/data/repositories/playlist_repository_impl.dart';

void main() {
  group('PlaylistRepositoryImpl write path', () {
    late _FakePlaylistRemoteDataSource remoteDataSource;
    late PlaylistRepositoryImpl repository;

    setUp(() {
      remoteDataSource = _FakePlaylistRemoteDataSource();
      repository = PlaylistRepositoryImpl(remoteDataSource: remoteDataSource);
    });

    test('createPlaylist forwards success payload', () async {
      remoteDataSource.createResult = const PlaylistMutationResult(
        isSuccess: true,
        message: 'Created',
        id: 'playlist-1',
      );

      final result = await repository.createPlaylist(
        const PlaylistMutationRequest(name: 'Morning'),
      );

      expect(result, isA<Right<Failure, PlaylistMutationResult>>());
      result.fold(
        (_) => fail('Expected success'),
        (success) {
          expect(success.message, 'Created');
          expect(success.id, 'playlist-1');
        },
      );
    });

    test('updatePlaylist maps ServerException to ServerFailure', () async {
      remoteDataSource.updateError = const ServerException('Playlist locked');

      final result = await repository.updatePlaylist(
        'playlist-2',
        const PlaylistMutationRequest(name: 'Updated'),
      );

      expect(result, isA<Left<Failure, PlaylistMutationResult>>());
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Playlist locked');
        },
        (_) => fail('Expected failure'),
      );
    });

    test('addTracksToPlaylist forwards IDs to datasource', () async {
      await repository.addTracksToPlaylist(
        playlistId: 'playlist-3',
        trackIds: const ['track-1', 'track-2'],
      );

      expect(remoteDataSource.lastAddTracksPlaylistId, 'playlist-3');
      expect(remoteDataSource.lastAddedTrackIds, const ['track-1', 'track-2']);
    });
  });
}

class _FakePlaylistRemoteDataSource implements PlaylistRemoteDataSource {
  PlaylistMutationResult createResult =
      const PlaylistMutationResult(isSuccess: true);
  Exception? updateError;
  String? lastAddTracksPlaylistId;
  List<String>? lastAddedTrackIds;

  @override
  Future<PlaylistMutationResult> createPlaylist(
    PlaylistMutationRequest request,
  ) async {
    return createResult;
  }

  @override
  Future<PlaylistMutationResult> updatePlaylist(
    String playlistId,
    PlaylistMutationRequest request,
  ) async {
    if (updateError != null) {
      throw updateError!;
    }
    return const PlaylistMutationResult(isSuccess: true);
  }

  @override
  Future<PlaylistMutationResult> addTracksToPlaylist({
    required String playlistId,
    required List<String> trackIds,
  }) async {
    lastAddTracksPlaylistId = playlistId;
    lastAddedTrackIds = trackIds;
    return const PlaylistMutationResult(isSuccess: true);
  }

  @override
  Future<PlaylistMutationResult> deletePlaylist(String playlistId) async {
    return const PlaylistMutationResult(isSuccess: true);
  }

  @override
  Future<PlaylistMutationResult> togglePlaylistStatus(String playlistId) async {
    return const PlaylistMutationResult(isSuccess: true);
  }

  @override
  Future<PlaylistMutationResult> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    return const PlaylistMutationResult(isSuccess: true);
  }

  @override
  Future<ApiPlaylistModel> getPlaylistById(String playlistId) async {
    throw UnimplementedError();
  }

  @override
  Future<PlaylistListResponse> getPlaylists({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? sortBy,
    bool? isAscending,
    int? status,
    String? brandId,
    String? storeId,
    String? moodId,
    bool? isDefault,
    DateTime? createdFrom,
    DateTime? createdTo,
  }) async {
    throw UnimplementedError();
  }
}
