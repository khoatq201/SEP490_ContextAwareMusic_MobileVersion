import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/models/api_result.dart';
import '../models/suno_config_model.dart';
import '../models/suno_generation_model.dart';

abstract class SunoRemoteDataSource {
  Future<String> createGeneration(CreateSunoGenerationRequest request);

  Future<SunoGenerationModel> getGeneration(String id);

  Future<void> cancelGeneration(String id);

  Future<SunoConfigModel> getConfig();

  Future<SunoConfigModel> updateConfig(UpdateSunoConfigRequest request);
}

class CreateSunoGenerationRequest {
  final String? prompt;
  final String title;
  final String? artist;
  final String? moodId;
  final String? targetPlaylistId;
  final bool autoAddToTargetPlaylist;

  const CreateSunoGenerationRequest({
    this.prompt,
    required this.title,
    this.artist,
    this.moodId,
    this.targetPlaylistId,
    this.autoAddToTargetPlaylist = false,
  });

  Map<String, dynamic> toJson() {
    return {
      if (prompt != null && prompt!.trim().isNotEmpty) 'prompt': prompt!.trim(),
      'title': title.trim(),
      if (artist != null && artist!.trim().isNotEmpty) 'artist': artist!.trim(),
      if (moodId != null && moodId!.trim().isNotEmpty) 'moodId': moodId!.trim(),
      if (targetPlaylistId != null && targetPlaylistId!.trim().isNotEmpty)
        'targetPlaylistId': targetPlaylistId!.trim(),
      'autoAddToTargetPlaylist': autoAddToTargetPlaylist,
    };
  }
}

class UpdateSunoConfigRequest {
  final String? sunoPromptTemplate;
  final String? sunoDefaultPlaylistId;

  const UpdateSunoConfigRequest({
    this.sunoPromptTemplate,
    this.sunoDefaultPlaylistId,
  });

  Map<String, dynamic> toJson() {
    return {
      'sunoPromptTemplate': sunoPromptTemplate,
      'sunoDefaultPlaylistId': sunoDefaultPlaylistId,
    };
  }
}

class SunoRemoteDataSourceImpl implements SunoRemoteDataSource {
  final DioClient dioClient;

  SunoRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<String> createGeneration(CreateSunoGenerationRequest request) async {
    try {
      final response = await dioClient.post(
        ApiConstants.sunoGenerations,
        data: request.toJson(),
      );
      final payload = _requireResultMap(response.data);
      final result = ApiResult<String>.fromJson(
        payload,
        fromData: (data) => (data as Map)['id'].toString(),
      );
      if (!result.isSuccess || result.data == null || result.data!.isEmpty) {
        throw ServerException(result.userFriendlyError);
      }
      return result.data!;
    } on DioException catch (e) {
      throw ServerException('Failed to create Suno generation: ${e.message}');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to create Suno generation: $e');
    }
  }

  @override
  Future<SunoGenerationModel> getGeneration(String id) async {
    try {
      final response =
          await dioClient.get(ApiConstants.sunoGenerationDetail(id));
      final payload = _requireResultMap(response.data);
      final result = ApiResult<SunoGenerationModel>.fromJson(
        payload,
        fromData: (data) => SunoGenerationModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
      );
      if (!result.isSuccess || result.data == null) {
        throw ServerException(result.userFriendlyError);
      }
      return result.data!;
    } on DioException catch (e) {
      throw ServerException('Failed to get Suno generation: ${e.message}');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to get Suno generation: $e');
    }
  }

  @override
  Future<void> cancelGeneration(String id) async {
    try {
      final response =
          await dioClient.post(ApiConstants.sunoGenerationCancel(id));
      final payload = _requireResultMap(response.data);
      final result = ApiResult<void>.fromJson(payload);
      if (!result.isSuccess) {
        throw ServerException(result.userFriendlyError);
      }
    } on DioException catch (e) {
      throw ServerException('Failed to cancel Suno generation: ${e.message}');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to cancel Suno generation: $e');
    }
  }

  @override
  Future<SunoConfigModel> getConfig() async {
    try {
      final response = await dioClient.get(ApiConstants.sunoConfig);
      final payload = _requireResultMap(response.data);
      final result = ApiResult<SunoConfigModel>.fromJson(
        payload,
        fromData: (data) => SunoConfigModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
      );
      if (!result.isSuccess || result.data == null) {
        throw ServerException(result.userFriendlyError);
      }
      return result.data!;
    } on DioException catch (e) {
      throw ServerException('Failed to get Suno config: ${e.message}');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to get Suno config: $e');
    }
  }

  @override
  Future<SunoConfigModel> updateConfig(UpdateSunoConfigRequest request) async {
    try {
      final response = await dioClient.put(
        ApiConstants.sunoConfig,
        data: request.toJson(),
      );
      final payload = _requireResultMap(response.data);
      final result = ApiResult<SunoConfigModel>.fromJson(
        payload,
        fromData: (data) => SunoConfigModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
      );
      if (!result.isSuccess || result.data == null) {
        throw ServerException(result.userFriendlyError);
      }
      return result.data!;
    } on DioException catch (e) {
      throw ServerException('Failed to update Suno config: ${e.message}');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to update Suno config: $e');
    }
  }

  Map<String, dynamic> _requireResultMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw ServerException('Invalid Suno API response.');
  }
}
