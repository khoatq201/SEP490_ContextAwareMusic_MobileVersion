import '../models/api_track_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';

abstract class TrackRemoteDataSource {
  /// Fetch paginated list of tracks.
  /// [page] and [pageSize] for pagination.
  /// [search] for text search (title, artist, genre).
  /// [moodId] to filter by mood.
  Future<TrackListResponse> getTracks({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? moodId,
    String? genre,
  });

  /// Fetch single track detail by ID.
  Future<ApiTrackModel> getTrackById(String trackId);
}

/// Wrapper for paginated track list response.
class TrackListResponse {
  final List<ApiTrackModel> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNext;
  final bool hasPrevious;

  TrackListResponse({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory TrackListResponse.fromJson(Map<String, dynamic> json) {
    return TrackListResponse(
      items: ApiTrackModel.fromPaginatedResponse(json),
      currentPage: json['currentPage'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 1,
      totalItems: json['totalItems'] as int? ?? 0,
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrevious: json['hasPrevious'] as bool? ?? false,
    );
  }
}

class TrackRemoteDataSourceImpl implements TrackRemoteDataSource {
  final DioClient dioClient;

  TrackRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<TrackListResponse> getTracks({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? moodId,
    String? genre,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (moodId != null) 'moodId': moodId,
        if (genre != null && genre.isNotEmpty) 'genre': genre,
      };

      final response = await dioClient.get(
        ApiConstants.getTracks,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return TrackListResponse.fromJson(data);
      }
      return TrackListResponse(
        items: [],
        currentPage: 1,
        totalPages: 1,
        totalItems: 0,
        hasNext: false,
        hasPrevious: false,
      );
    } catch (e) {
      throw ServerException('Failed to fetch tracks: $e');
    }
  }

  @override
  Future<ApiTrackModel> getTrackById(String trackId) async {
    try {
      final response = await dioClient.get(
        ApiConstants.getTrackDetail(trackId),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return ApiTrackModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return ApiTrackModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException('Failed to fetch track detail: $e');
    }
  }
}
