import 'dart:typed_data';

import '../models/api_track_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import 'package:dio/dio.dart';

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

  /// Create a new manual-upload track.
  Future<void> createTrack(CreateTrackRequest request);
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

class TrackUploadFile {
  final String fileName;
  final String? filePath;
  final Uint8List? bytes;

  const TrackUploadFile({
    required this.fileName,
    this.filePath,
    this.bytes,
  }) : assert(filePath != null || bytes != null);
}

class CreateTrackRequest {
  final String title;
  final String? artist;
  final String? moodId;
  final int? durationSec;
  final int? bpm;
  final String? genre;
  final double? energyLevel;
  final double? valence;
  final int? provider;
  final TrackUploadFile audioFile;
  final TrackUploadFile? coverImageFile;

  const CreateTrackRequest({
    required this.title,
    required this.audioFile,
    this.artist,
    this.moodId,
    this.durationSec,
    this.bpm,
    this.genre,
    this.energyLevel,
    this.valence,
    this.provider,
    this.coverImageFile,
  });
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

  @override
  Future<void> createTrack(CreateTrackRequest request) async {
    try {
      final audioMultipart = await _toMultipartFile(request.audioFile);
      final coverMultipart = request.coverImageFile != null
          ? await _toMultipartFile(request.coverImageFile!)
          : null;

      final formData = FormData.fromMap({
        'title': request.title,
        if (request.artist != null && request.artist!.isNotEmpty)
          'artist': request.artist,
        if (request.moodId != null && request.moodId!.isNotEmpty)
          'moodId': request.moodId,
        if (request.durationSec != null) 'durationSec': request.durationSec,
        if (request.bpm != null) 'bpm': request.bpm,
        if (request.genre != null && request.genre!.isNotEmpty)
          'genre': request.genre,
        if (request.energyLevel != null) 'energyLevel': request.energyLevel,
        if (request.valence != null) 'valence': request.valence,
        if (request.provider != null) 'provider': request.provider,
        'audioFile': audioMultipart,
        if (coverMultipart != null) 'coverImageFile': coverMultipart,
      });

      final response = await dioClient.post(
        ApiConstants.getTracks,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: const {
            'Accept': 'application/json',
          },
        ),
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
      throw ServerException('Failed to upload track: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to upload track: $e');
    }
  }

  Future<MultipartFile> _toMultipartFile(TrackUploadFile file) async {
    if (file.bytes != null) {
      return MultipartFile.fromBytes(
        file.bytes!,
        filename: file.fileName,
      );
    }
    if (file.filePath != null && file.filePath!.isNotEmpty) {
      return MultipartFile.fromFile(
        file.filePath!,
        filename: file.fileName,
      );
    }
    throw ServerException('Invalid upload file payload.');
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
