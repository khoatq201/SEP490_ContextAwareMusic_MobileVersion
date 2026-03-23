import '../models/api_playlist_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import 'package:dio/dio.dart';

abstract class PlaylistRemoteDataSource {
  /// Fetch paginated list of playlists.
  Future<PlaylistListResponse> getPlaylists({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? storeId,
    String? moodId,
    bool? isDynamic,
    bool? isDefault,
  });

  /// Fetch single playlist detail by ID (includes tracks with seekOffsetSeconds).
  Future<ApiPlaylistModel> getPlaylistById(String playlistId);

  /// Add one or many tracks to an existing playlist.
  Future<void> addTracksToPlaylist({
    required String playlistId,
    required List<String> trackIds,
  });
}

/// Wrapper for paginated playlist list response.
class PlaylistListResponse {
  final List<ApiPlaylistModel> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNext;
  final bool hasPrevious;

  PlaylistListResponse({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PlaylistListResponse.fromJson(Map<String, dynamic> json) {
    return PlaylistListResponse(
      items: ApiPlaylistModel.fromPaginatedResponse(json),
      currentPage: json['currentPage'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 1,
      totalItems: json['totalItems'] as int? ?? 0,
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrevious: json['hasPrevious'] as bool? ?? false,
    );
  }
}

class PlaylistRemoteDataSourceImpl implements PlaylistRemoteDataSource {
  final DioClient dioClient;

  PlaylistRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<PlaylistListResponse> getPlaylists({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? storeId,
    String? moodId,
    bool? isDynamic,
    bool? isDefault,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (storeId != null) 'storeId': storeId,
        if (moodId != null) 'moodId': moodId,
        if (isDynamic != null) 'isDynamic': isDynamic,
        if (isDefault != null) 'isDefault': isDefault,
      };

      final response = await dioClient.get(
        ApiConstants.getPlaylists,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return PlaylistListResponse.fromJson(data);
      }
      return PlaylistListResponse(
        items: [],
        currentPage: 1,
        totalPages: 1,
        totalItems: 0,
        hasNext: false,
        hasPrevious: false,
      );
    } catch (e) {
      throw ServerException('Failed to fetch playlists: $e');
    }
  }

  @override
  Future<ApiPlaylistModel> getPlaylistById(String playlistId) async {
    try {
      final response = await dioClient.get(
        ApiConstants.getPlaylistDetail(playlistId),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return ApiPlaylistModel.fromDetailJson(
            data['data'] as Map<String, dynamic>);
      }
      return ApiPlaylistModel.fromDetailJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException('Failed to fetch playlist detail: $e');
    }
  }

  @override
  Future<void> addTracksToPlaylist({
    required String playlistId,
    required List<String> trackIds,
  }) async {
    if (trackIds.isEmpty) return;

    try {
      final response = await dioClient.post(
        ApiConstants.addTracksToPlaylist(playlistId),
        data: {
          'trackIds': trackIds,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['isSuccess'] == false) {
        throw ServerException(_extractErrorMessage(data));
      }
    } on DioException catch (e) {
      final payload = e.response?.data;
      if (payload is Map<String, dynamic>) {
        throw ServerException(_extractErrorMessage(payload));
      }
      throw ServerException('Failed to add track to playlist: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to add track to playlist: $e');
    }
  }

  String _extractErrorMessage(Map<String, dynamic> payload) {
    final errors = payload['errors'];
    if (errors is List && errors.isNotEmpty) {
      return errors.first.toString();
    }
    final message = payload['message']?.toString();
    return (message != null && message.isNotEmpty)
        ? message
        : 'Request failed.';
  }
}
