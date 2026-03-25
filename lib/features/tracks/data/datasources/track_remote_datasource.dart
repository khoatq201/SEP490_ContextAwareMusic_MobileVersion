import 'dart:typed_data';

import '../models/api_track_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/track_filter.dart';
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
    TrackFilter? filter,
  });

  /// Fetch single track detail by ID.
  Future<ApiTrackModel> getTrackById(String trackId);

  /// Create a new manual-upload track.
  Future<TrackMutationResult> createTrack(CreateTrackRequest request);

  Future<TrackMutationResult> updateTrack(
    String trackId,
    UpdateTrackRequest request,
  );

  Future<TrackMutationResult> deleteTrack(String trackId);

  Future<TrackMutationResult> toggleTrackStatus(String trackId);

  Future<TrackMutationResult> retranscodeTrack(String trackId);
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

class UpdateTrackRequest {
  final String? title;
  final String? artist;
  final String? moodId;
  final int? durationSec;
  final int? bpm;
  final String? genre;
  final double? energyLevel;
  final double? valence;
  final int? provider;
  final TrackUploadFile? audioFile;
  final TrackUploadFile? coverImageFile;

  const UpdateTrackRequest({
    this.title,
    this.artist,
    this.moodId,
    this.durationSec,
    this.bpm,
    this.genre,
    this.energyLevel,
    this.valence,
    this.provider,
    this.audioFile,
    this.coverImageFile,
  });
}

class TrackMutationResult {
  final bool isSuccess;
  final String? message;
  final String? errorCode;

  const TrackMutationResult({
    required this.isSuccess,
    this.message,
    this.errorCode,
  });

  factory TrackMutationResult.fromJson(Map<String, dynamic> json) {
    return TrackMutationResult(
      isSuccess: json['isSuccess'] as bool? ?? false,
      message: json['message']?.toString(),
      errorCode: json['errorCode']?.toString(),
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
    TrackFilter? filter,
  }) async {
    try {
      final effectiveFilter = filter ??
          TrackFilter(
            page: page,
            pageSize: pageSize,
            search: search,
            moodId: moodId,
            genre: genre,
          );

      final response = await dioClient.get(
        ApiConstants.getTracks,
        queryParameters: effectiveFilter.toQueryParameters(),
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
  Future<TrackMutationResult> createTrack(CreateTrackRequest request) async {
    try {
      final formData = await _buildTrackFormData(
        title: request.title,
        artist: request.artist,
        moodId: request.moodId,
        durationSec: request.durationSec,
        bpm: request.bpm,
        genre: request.genre,
        energyLevel: request.energyLevel,
        valence: request.valence,
        provider: request.provider,
        audioFile: request.audioFile,
        coverImageFile: request.coverImageFile,
      );

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
      return data is Map<String, dynamic>
          ? TrackMutationResult.fromJson(data)
          : const TrackMutationResult(isSuccess: true);
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

  @override
  Future<TrackMutationResult> updateTrack(
    String trackId,
    UpdateTrackRequest request,
  ) async {
    try {
      final formData = await _buildTrackFormData(
        title: request.title,
        artist: request.artist,
        moodId: request.moodId,
        durationSec: request.durationSec,
        bpm: request.bpm,
        genre: request.genre,
        energyLevel: request.energyLevel,
        valence: request.valence,
        provider: request.provider,
        audioFile: request.audioFile,
        coverImageFile: request.coverImageFile,
      );

      final response = await dioClient.put(
        ApiConstants.updateTrack(trackId),
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

      return data is Map<String, dynamic>
          ? TrackMutationResult.fromJson(data)
          : const TrackMutationResult(isSuccess: true);
    } on DioException catch (e) {
      final payload = e.response?.data;
      if (payload is Map<String, dynamic>) {
        throw ServerException(_extractErrorMessage(payload));
      }
      throw ServerException('Failed to update track: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to update track: $e');
    }
  }

  @override
  Future<TrackMutationResult> deleteTrack(String trackId) async {
    try {
      final response =
          await dioClient.delete(ApiConstants.deleteTrack(trackId));
      final data = response.data;
      if (data is Map<String, dynamic> && data['isSuccess'] == false) {
        throw ServerException(_extractErrorMessage(data));
      }
      return data is Map<String, dynamic>
          ? TrackMutationResult.fromJson(data)
          : const TrackMutationResult(isSuccess: true);
    } on DioException catch (e) {
      final payload = e.response?.data;
      if (payload is Map<String, dynamic>) {
        throw ServerException(_extractErrorMessage(payload));
      }
      throw ServerException('Failed to delete track: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to delete track: $e');
    }
  }

  @override
  Future<TrackMutationResult> toggleTrackStatus(String trackId) async {
    try {
      final response =
          await dioClient.put(ApiConstants.toggleTrackStatus(trackId));
      final data = response.data;
      if (data is Map<String, dynamic> && data['isSuccess'] == false) {
        throw ServerException(_extractErrorMessage(data));
      }
      return data is Map<String, dynamic>
          ? TrackMutationResult.fromJson(data)
          : const TrackMutationResult(isSuccess: true);
    } on DioException catch (e) {
      final payload = e.response?.data;
      if (payload is Map<String, dynamic>) {
        throw ServerException(_extractErrorMessage(payload));
      }
      throw ServerException('Failed to toggle track status: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to toggle track status: $e');
    }
  }

  @override
  Future<TrackMutationResult> retranscodeTrack(String trackId) async {
    try {
      final response =
          await dioClient.post(ApiConstants.retranscodeTrack(trackId));
      final data = response.data;
      if (data is Map<String, dynamic> && data['isSuccess'] == false) {
        throw ServerException(_extractErrorMessage(data));
      }
      return data is Map<String, dynamic>
          ? TrackMutationResult.fromJson(data)
          : const TrackMutationResult(isSuccess: true);
    } on DioException catch (e) {
      final payload = e.response?.data;
      if (payload is Map<String, dynamic>) {
        throw ServerException(_extractErrorMessage(payload));
      }
      throw ServerException('Failed to retranscode track: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to retranscode track: $e');
    }
  }

  Future<FormData> _buildTrackFormData({
    String? title,
    String? artist,
    String? moodId,
    int? durationSec,
    int? bpm,
    String? genre,
    double? energyLevel,
    double? valence,
    int? provider,
    TrackUploadFile? audioFile,
    TrackUploadFile? coverImageFile,
  }) async {
    final audioMultipart =
        audioFile != null ? await _toMultipartFile(audioFile) : null;
    final coverMultipart =
        coverImageFile != null ? await _toMultipartFile(coverImageFile) : null;

    return FormData.fromMap({
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      if (artist != null && artist.trim().isNotEmpty) 'artist': artist.trim(),
      if (moodId != null && moodId.trim().isNotEmpty) 'moodId': moodId.trim(),
      if (durationSec != null) 'durationSec': durationSec,
      if (bpm != null) 'bpm': bpm,
      if (genre != null && genre.trim().isNotEmpty) 'genre': genre.trim(),
      if (energyLevel != null) 'energyLevel': energyLevel,
      if (valence != null) 'valence': valence,
      if (provider != null) 'provider': provider,
      if (audioMultipart != null) 'audioFile': audioMultipart,
      if (coverMultipart != null) 'coverImageFile': coverMultipart,
    });
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
