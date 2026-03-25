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

  /// Fetch single playlist detail by ID (includes tracks with seekOffsetSeconds).
  Future<ApiPlaylistModel> getPlaylistById(String playlistId);

  /// Create a playlist using backend PlaylistRequest contract.
  Future<PlaylistMutationResult> createPlaylist(
    PlaylistMutationRequest request,
  );

  /// Update a playlist with partial-update semantics.
  Future<PlaylistMutationResult> updatePlaylist(
    String playlistId,
    PlaylistMutationRequest request,
  );

  /// Soft-delete a playlist.
  Future<PlaylistMutationResult> deletePlaylist(String playlistId);

  /// Toggle playlist status Active <-> Inactive.
  Future<PlaylistMutationResult> togglePlaylistStatus(String playlistId);

  /// Add one or many tracks to an existing playlist.
  Future<PlaylistMutationResult> addTracksToPlaylist({
    required String playlistId,
    required List<String> trackIds,
  });

  /// Remove a single track from playlist.
  Future<PlaylistMutationResult> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  });

  /// Force queueing a retranscode for playlist.
  Future<PlaylistMutationResult> retranscodePlaylist(String playlistId);
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

class PlaylistMutationRequest {
  final String? name;
  final String? storeId;
  final String? moodId;
  final String? description;
  final bool? isDynamic;
  final bool? isDefault;
  final List<String>? trackIds;

  const PlaylistMutationRequest({
    this.name,
    this.storeId,
    this.moodId,
    this.description,
    this.isDynamic,
    this.isDefault,
    this.trackIds,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
      if (storeId != null && storeId!.trim().isNotEmpty) 'storeId': storeId,
      if (moodId != null && moodId!.trim().isNotEmpty) 'moodId': moodId,
      if (description != null) 'description': description,
      if (isDynamic != null) 'isDynamic': isDynamic,
      if (isDefault != null) 'isDefault': isDefault,
      if (trackIds != null) 'trackIds': trackIds,
    };
  }
}

class PlaylistMutationResult {
  final bool isSuccess;
  final String? message;
  final String? errorCode;
  final String? id;

  const PlaylistMutationResult({
    required this.isSuccess,
    this.message,
    this.errorCode,
    this.id,
  });

  factory PlaylistMutationResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    String? parsedId;
    if (data is Map<String, dynamic>) {
      parsedId = data['id']?.toString();
    } else if (data is String && data.trim().isNotEmpty) {
      parsedId = data;
    }

    return PlaylistMutationResult(
      isSuccess: json['isSuccess'] as bool? ?? false,
      message: json['message']?.toString(),
      errorCode: json['errorCode']?.toString(),
      id: parsedId,
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
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
        if (isAscending != null) 'isAscending': isAscending,
        if (status != null) 'status': status,
        if (brandId != null && brandId.isNotEmpty) 'brandId': brandId,
        if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        if (moodId != null && moodId.isNotEmpty) 'moodId': moodId,
        if (isDynamic != null) 'isDynamic': isDynamic,
        if (isDefault != null) 'isDefault': isDefault,
        if (createdFrom != null) 'createdFrom': createdFrom.toIso8601String(),
        if (createdTo != null) 'createdTo': createdTo.toIso8601String(),
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
  Future<PlaylistMutationResult> createPlaylist(
    PlaylistMutationRequest request,
  ) async {
    try {
      final response = await dioClient.post(
        ApiConstants.createPlaylist,
        data: request.toJson(),
      );
      return _parseMutationResult(response.data);
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMessage(
        e,
        fallback: 'Failed to create playlist.',
      ));
    } catch (e) {
      throw ServerException('Failed to create playlist: $e');
    }
  }

  @override
  Future<PlaylistMutationResult> updatePlaylist(
    String playlistId,
    PlaylistMutationRequest request,
  ) async {
    try {
      final response = await dioClient.put(
        ApiConstants.updatePlaylist(playlistId),
        data: request.toJson(),
      );
      return _parseMutationResult(response.data);
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMessage(
        e,
        fallback: 'Failed to update playlist.',
      ));
    } catch (e) {
      throw ServerException('Failed to update playlist: $e');
    }
  }

  @override
  Future<PlaylistMutationResult> deletePlaylist(String playlistId) async {
    try {
      final response =
          await dioClient.delete(ApiConstants.deletePlaylist(playlistId));
      return _parseMutationResult(response.data);
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMessage(
        e,
        fallback: 'Failed to delete playlist.',
      ));
    } catch (e) {
      throw ServerException('Failed to delete playlist: $e');
    }
  }

  @override
  Future<PlaylistMutationResult> togglePlaylistStatus(String playlistId) async {
    try {
      final response =
          await dioClient.put(ApiConstants.togglePlaylistStatus(playlistId));
      return _parseMutationResult(response.data);
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMessage(
        e,
        fallback: 'Failed to toggle playlist status.',
      ));
    } catch (e) {
      throw ServerException('Failed to toggle playlist status: $e');
    }
  }

  @override
  Future<PlaylistMutationResult> addTracksToPlaylist({
    required String playlistId,
    required List<String> trackIds,
  }) async {
    if (trackIds.isEmpty) {
      return const PlaylistMutationResult(isSuccess: true);
    }

    try {
      final response = await dioClient.post(
        ApiConstants.addTracksToPlaylist(playlistId),
        data: {
          'trackIds': trackIds,
        },
      );
      return _parseMutationResult(response.data);
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMessage(
        e,
        fallback: 'Failed to add tracks to playlist.',
      ));
    } catch (e) {
      throw ServerException('Failed to add tracks to playlist: $e');
    }
  }

  @override
  Future<PlaylistMutationResult> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    try {
      final response = await dioClient.delete(
        ApiConstants.removeTrackFromPlaylist(playlistId, trackId),
      );
      return _parseMutationResult(response.data);
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMessage(
        e,
        fallback: 'Failed to remove track from playlist.',
      ));
    } catch (e) {
      throw ServerException('Failed to remove track from playlist: $e');
    }
  }

  @override
  Future<PlaylistMutationResult> retranscodePlaylist(String playlistId) async {
    try {
      final response =
          await dioClient.post(ApiConstants.retranscodePlaylist(playlistId));
      return _parseMutationResult(response.data);
    } on DioException catch (e) {
      throw ServerException(_extractDioErrorMessage(
        e,
        fallback: 'Failed to retranscode playlist.',
      ));
    } catch (e) {
      throw ServerException('Failed to retranscode playlist: $e');
    }
  }

  PlaylistMutationResult _parseMutationResult(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['isSuccess'] == false) {
        throw ServerException(_extractErrorMessage(data));
      }
      return PlaylistMutationResult.fromJson(data);
    }
    return const PlaylistMutationResult(isSuccess: true);
  }

  String _extractDioErrorMessage(
    DioException error, {
    required String fallback,
  }) {
    final payload = error.response?.data;
    if (payload is Map<String, dynamic>) {
      return _extractErrorMessage(payload);
    }
    final message = error.message;
    if (message != null && message.trim().isNotEmpty) {
      return message;
    }
    return fallback;
  }

  String _extractErrorMessage(Map<String, dynamic> payload) {
    final errors = payload['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is Map<String, dynamic>) {
        final detail = first['message']?.toString();
        if (detail != null && detail.trim().isNotEmpty) {
          return detail;
        }
      }
      final detail = first.toString();
      if (detail.trim().isNotEmpty) {
        return detail;
      }
    }
    if (errors is Map<String, dynamic> && errors.isNotEmpty) {
      final firstValue = errors.values.first;
      if (firstValue is List && firstValue.isNotEmpty) {
        final detail = firstValue.first.toString();
        if (detail.trim().isNotEmpty) {
          return detail;
        }
      }
    }
    final message = payload['message']?.toString();
    return (message != null && message.isNotEmpty)
        ? message
        : 'Request failed.';
  }
}
