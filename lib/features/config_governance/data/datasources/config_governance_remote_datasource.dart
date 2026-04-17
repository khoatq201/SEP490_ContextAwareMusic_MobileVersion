import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/models/pagination_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/config_query.dart';
import '../../domain/entities/config_value_upsert_request.dart';
import '../models/config_flat_row_model.dart';

abstract class ConfigGovernanceRemoteDataSource {
  Future<PaginationResult<ConfigFlatRowModel>> getBrandConfig({
    ConfigQuery query = const ConfigQuery(),
  });

  Future<PaginationResult<ConfigFlatRowModel>> getStoreConfig({
    String? storeId,
    ConfigQuery query = const ConfigQuery(),
  });

  Future<PaginationResult<ConfigFlatRowModel>> getSpaceConfig({
    required String spaceId,
    ConfigQuery query = const ConfigQuery(),
  });

  Future<String> upsertStoreValue({
    String? storeId,
    required ConfigValueUpsertRequest request,
  });

  Future<String> upsertBrandValue({
    required ConfigValueUpsertRequest request,
  });

  Future<String> upsertSpaceValue({
    required String spaceId,
    required ConfigValueUpsertRequest request,
  });

  Future<String> setStoreGovernanceMode({
    required SetStoreGovernanceModeRequest request,
  });

  Future<String> publishConfigVersion({
    required PublishConfigVersionRequest request,
  });

  Future<String> rollbackConfigVersion({
    required RollbackConfigVersionRequest request,
  });
}

class ConfigGovernanceRemoteDataSourceImpl
    implements ConfigGovernanceRemoteDataSource {
  final DioClient dioClient;

  ConfigGovernanceRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<PaginationResult<ConfigFlatRowModel>> getBrandConfig({
    ConfigQuery query = const ConfigQuery(),
  }) {
    return _getConfig(path: ApiConstants.cmsConfigBrand, query: query);
  }

  @override
  Future<PaginationResult<ConfigFlatRowModel>> getStoreConfig({
    String? storeId,
    ConfigQuery query = const ConfigQuery(),
  }) async {
    final normalizedStoreId = storeId?.trim();
    final path = normalizedStoreId == null || normalizedStoreId.isEmpty
        ? ApiConstants.cmsConfigStore
        : ApiConstants.cmsConfigStoreById(normalizedStoreId);
    return _getConfig(path: path, query: query);
  }

  @override
  Future<PaginationResult<ConfigFlatRowModel>> getSpaceConfig({
    required String spaceId,
    ConfigQuery query = const ConfigQuery(),
  }) async {
    final normalizedSpaceId = spaceId.trim();
    if (normalizedSpaceId.isEmpty) {
      throw const ServerException('Space id is required to load config.');
    }
    return _getConfig(
      path: ApiConstants.cmsConfigSpace(normalizedSpaceId),
      query: query,
    );
  }

  @override
  Future<String> upsertStoreValue({
    String? storeId,
    required ConfigValueUpsertRequest request,
  }) async {
    final normalizedStoreId = storeId?.trim();
    final path = normalizedStoreId == null || normalizedStoreId.isEmpty
        ? ApiConstants.cmsConfigStoreValue
        : ApiConstants.cmsConfigStoreValueById(normalizedStoreId);
    return _putConfigValue(
      path: path,
      data: request.toJson(includeStoreOverrideIntent: true),
      fallbackMessage: 'Store config value updated.',
    );
  }

  @override
  Future<String> upsertBrandValue({
    required ConfigValueUpsertRequest request,
  }) {
    return _putConfigValue(
      path: ApiConstants.cmsConfigBrandValue,
      data: request.toJson(includeBrandOverrideIntent: true),
      fallbackMessage: 'Brand config value updated.',
    );
  }

  @override
  Future<String> upsertSpaceValue({
    required String spaceId,
    required ConfigValueUpsertRequest request,
  }) async {
    final normalizedSpaceId = spaceId.trim();
    if (normalizedSpaceId.isEmpty) {
      throw const ServerException('Space id is required to update config.');
    }
    return _putConfigValue(
      path: ApiConstants.cmsConfigSpaceValue(normalizedSpaceId),
      data: request.toJson(
        includeSpaceOverrideIntent: true,
        spaceId: normalizedSpaceId,
      ),
      fallbackMessage: 'Space config value updated.',
    );
  }

  @override
  Future<String> setStoreGovernanceMode({
    required SetStoreGovernanceModeRequest request,
  }) {
    return _patch(
      path: ApiConstants.cmsConfigStoresGovernanceMode,
      data: request.toJson(),
      fallbackMessage: 'Store governance mode updated.',
    );
  }

  @override
  Future<String> publishConfigVersion({
    required PublishConfigVersionRequest request,
  }) {
    return _post(
      path: ApiConstants.cmsConfigVersionPublish,
      data: request.toJson(),
      fallbackMessage: 'Config version published.',
    );
  }

  @override
  Future<String> rollbackConfigVersion({
    required RollbackConfigVersionRequest request,
  }) {
    return _post(
      path: ApiConstants.cmsConfigVersionRollback,
      data: request.toJson(),
      fallbackMessage: 'Config version rolled back.',
    );
  }

  Future<PaginationResult<ConfigFlatRowModel>> _getConfig({
    required String path,
    required ConfigQuery query,
  }) async {
    try {
      final response = await dioClient.get(
        path,
        queryParameters: query.toQueryParameters(),
      );
      final payload = _requirePaginationMap(response.data);
      return PaginationResult<ConfigFlatRowModel>.fromJson(
        payload,
        fromItemJson: ConfigFlatRowModel.fromJson,
      );
    } on DioException catch (error) {
      throw ServerException(
        _extractDioErrorMessage(
          error,
          fallback: 'Failed to load config governance data.',
        ),
      );
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException('Failed to load config governance data: $error');
    }
  }

  Future<String> _putConfigValue({
    required String path,
    required Map<String, dynamic> data,
    required String fallbackMessage,
  }) async {
    try {
      final response = await dioClient.put(path, data: data);
      final payload = _requireMap(response.data);
      if (payload['isSuccess'] == false) {
        throw ServerException(_extractErrorMessage(payload));
      }

      final message = payload['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }

      final responseData = payload['data']?.toString().trim();
      if (responseData != null && responseData.isNotEmpty) {
        return fallbackMessage;
      }

      return fallbackMessage;
    } on DioException catch (error) {
      throw ServerException(
        _extractDioErrorMessage(
          error,
          fallback: 'Failed to update config governance value.',
        ),
      );
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException('Failed to update config governance value: $error');
    }
  }

  Future<String> _patch({
    required String path,
    required Map<String, dynamic> data,
    required String fallbackMessage,
  }) async {
    try {
      final response = await dioClient.patch(path, data: data);
      final payload = _requireMap(response.data);
      if (payload['isSuccess'] == false) {
        throw ServerException(_extractErrorMessage(payload));
      }

      final message = payload['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }

      return fallbackMessage;
    } on DioException catch (error) {
      throw ServerException(
        _extractDioErrorMessage(
          error,
          fallback: 'Failed to update governance mode.',
        ),
      );
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException('Failed to update governance mode: $error');
    }
  }

  Future<String> _post({
    required String path,
    required Map<String, dynamic> data,
    required String fallbackMessage,
  }) async {
    try {
      final response = await dioClient.post(path, data: data);
      final payload = _requireMap(response.data);
      if (payload['isSuccess'] == false) {
        throw ServerException(_extractErrorMessage(payload));
      }

      final message = payload['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        final responseData = payload['data']?.toString().trim();
        if (responseData != null &&
            responseData.isNotEmpty &&
            !message.contains(responseData)) {
          return '$message ($responseData)';
        }
        return message;
      }

      final responseData = payload['data']?.toString().trim();
      if (responseData != null && responseData.isNotEmpty) {
        return '$fallbackMessage ($responseData)';
      }

      return fallbackMessage;
    } on DioException catch (error) {
      throw ServerException(
        _extractDioErrorMessage(
          error,
          fallback: fallbackMessage,
        ),
      );
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException('$fallbackMessage: $error');
    }
  }

  Map<String, dynamic> _requirePaginationMap(dynamic data) {
    final payload = _requireMap(data);
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

    throw const ServerException('Invalid config governance response.');
  }

  Map<String, dynamic> _requireMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ServerException('Invalid config governance response.');
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
