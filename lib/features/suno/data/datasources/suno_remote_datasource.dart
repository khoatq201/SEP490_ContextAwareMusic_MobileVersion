import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/enums/ai_generation_mode_enum.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/models/pagination_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/models/api_result.dart';
import '../models/suno_config_model.dart';
import '../models/suno_generation_model.dart';

abstract class SunoRemoteDataSource {
  Future<String> createGeneration(CreateSunoGenerationRequest request);

  Future<PaginationResult<SunoGenerationModel>> getGenerations({
    int page = 1,
    int pageSize = 10,
  });

  Future<SunoGenerationModel> getGeneration(String id);

  Future<void> cancelGeneration(String id);

  Future<SunoConfigModel> getConfig();

  Future<SunoConfigModel> updateConfig(UpdateSunoConfigRequest request);
}

class CreateSunoGenerationRequest {
  final String? prompt;
  final String? title;
  final String? artist;
  final String? moodId;
  final String? targetPlaylistId;
  final bool autoAddToTargetPlaylist;
  final AiGenerationModeEnum? aiGenerationMode;
  final String? fuzzyProfileTemplate;
  final int? recommendedBpmMin;
  final int? recommendedBpmMax;
  final int? recommendedBpmTarget;

  const CreateSunoGenerationRequest({
    this.prompt,
    this.title,
    this.artist,
    this.moodId,
    this.targetPlaylistId,
    this.autoAddToTargetPlaylist = true,
    this.aiGenerationMode,
    this.fuzzyProfileTemplate,
    this.recommendedBpmMin,
    this.recommendedBpmMax,
    this.recommendedBpmTarget,
  });

  Map<String, dynamic> toJson() {
    return {
      if (prompt != null && prompt!.trim().isNotEmpty) 'prompt': prompt!.trim(),
      if (title != null && title!.trim().isNotEmpty) 'title': title!.trim(),
      if (artist != null && artist!.trim().isNotEmpty) 'artist': artist!.trim(),
      if (moodId != null && moodId!.trim().isNotEmpty) 'moodId': moodId!.trim(),
      if (targetPlaylistId != null && targetPlaylistId!.trim().isNotEmpty)
        'targetPlaylistId': targetPlaylistId!.trim(),
      if (aiGenerationMode != null) 'aiGenerationMode': aiGenerationMode!.value,
      if (fuzzyProfileTemplate != null &&
          fuzzyProfileTemplate!.trim().isNotEmpty)
        'fuzzyProfileTemplate': fuzzyProfileTemplate!.trim(),
      if (recommendedBpmMin != null) ...{
        'recommendedBpmMin': recommendedBpmMin,
        'bpmMin': recommendedBpmMin,
      },
      if (recommendedBpmMax != null) ...{
        'recommendedBpmMax': recommendedBpmMax,
        'bpmMax': recommendedBpmMax,
      },
      if (recommendedBpmTarget != null) ...{
        'recommendedBpmTarget': recommendedBpmTarget,
        'bpmTarget': recommendedBpmTarget,
      },
      'autoAddToTargetPlaylist': autoAddToTargetPlaylist,
    };
  }
}

class UpdateSunoConfigRequest {
  final String? sunoPromptTemplate;
  final String? sunoDefaultPlaylistId;
  final AiGenerationModeEnum? aiGenerationMode;

  const UpdateSunoConfigRequest({
    this.sunoPromptTemplate,
    this.sunoDefaultPlaylistId,
    this.aiGenerationMode,
  });

  Map<String, dynamic> toJson() {
    return {
      'sunoPromptTemplate': sunoPromptTemplate,
      'sunoDefaultPlaylistId': sunoDefaultPlaylistId,
      if (aiGenerationMode != null) 'aiGenerationMode': aiGenerationMode!.value,
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
      throw ServerException(
        _extractDioErrorMessage(
          e,
          fallback: 'Failed to create Suno generation.',
        ),
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to create Suno generation: $e');
    }
  }

  @override
  Future<PaginationResult<SunoGenerationModel>> getGenerations({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await dioClient.get(
        ApiConstants.sunoGenerations,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      final payload = _requirePaginationMap(response.data);
      return PaginationResult<SunoGenerationModel>.fromJson(
        payload,
        fromItemJson: SunoGenerationModel.fromJson,
      );
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMessage(
          e,
          fallback: 'Failed to load Suno generation history.',
        ),
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to load Suno generation history: $e');
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
    throw const ServerException('Invalid Suno API response.');
  }

  Map<String, dynamic> _requirePaginationMap(dynamic data) {
    final payload = _requireResultMap(data);
    if (payload['items'] is List) {
      return payload;
    }

    final nestedData = payload['data'];
    if (nestedData is Map<String, dynamic> && nestedData['items'] is List) {
      return nestedData;
    }
    if (nestedData is Map) {
      final nestedMap = Map<String, dynamic>.from(nestedData);
      if (nestedMap['items'] is List) {
        return nestedMap;
      }
    }

    if (payload['isSuccess'] == false) {
      throw ServerException(_extractErrorMessage(payload));
    }

    throw const ServerException('Invalid Suno generation history response.');
  }

  String _extractDioErrorMessage(
    DioException error, {
    required String fallback,
  }) {
    final payload = error.response?.data;
    if (payload is Map<String, dynamic>) {
      return _extractErrorMessage(payload);
    }
    if (payload is Map) {
      return _extractErrorMessage(Map<String, dynamic>.from(payload));
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
    if (message != null && message.trim().isNotEmpty) {
      return message;
    }
    return 'Request failed.';
  }
}
