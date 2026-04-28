import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/offline_playlist.dart';
import 'offline_playlist_datasource.dart';

/// Real API implementation of [OfflinePlaylistDataSource].
class OfflinePlaylistRemoteDataSourceImpl implements OfflinePlaylistDataSource {
  final DioClient dioClient;

  OfflinePlaylistRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<OfflinePlaylist>> getAvailablePlaylists() async {
    try {
      final response = await dioClient.get('/api/playlists/offline');
      final data = response.data;
      final List<dynamic> list =
          data is Map<String, dynamic> && data['data'] != null
              ? data['data'] as List
              : data as List;

      return list.map((json) {
        final map = json as Map<String, dynamic>;
        return OfflinePlaylist(
          id: map['id'] as String,
          moodName: map['moodName'] as String,
          coverUrl: map['coverUrl'] as String?,
          trackCount: map['trackCount'] as int? ?? 0,
          totalSizeMB: (map['totalSizeMB'] as num?)?.toDouble() ?? 0.0,
          downloadStatus: DownloadStatus.notDownloaded,
        );
      }).toList();
    } catch (e) {
      throw ServerException('Failed to fetch offline playlists: $e');
    }
  }

  @override
  Stream<double> downloadPlaylist(String playlistId) async* {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/offline_playlists/$playlistId.zip';

      await Directory('${dir.path}/offline_playlists').create(recursive: true);

      final controller = StreamController<double>();

      dioClient.dio.download(
        '/api/playlists/$playlistId/download',
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            controller.add(received / total);
          }
        },
      ).then((_) {
        controller.close();
      }).catchError((e) {
        controller.addError(ServerException('Failed to download playlist: $e'));
        controller.close();
      });

      yield* controller.stream;
    } catch (e) {
      throw ServerException('Failed to start playlist download: $e');
    }
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/offline_playlists/$playlistId.zip');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw ServerException('Failed to delete playlist: $e');
    }
  }
}
