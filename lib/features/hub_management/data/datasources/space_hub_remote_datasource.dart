import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/space_hub_binding_model.dart';

abstract class SpaceHubRemoteDataSource {
  Future<SpaceHubBindingModel?> getBinding(String spaceId);

  Future<SpaceHubBindingModel> upsertBinding(SpaceHubBindingModel binding);

  Future<void> deleteBinding(String spaceId);

  Future<void> restartHub(String spaceId);
}

class SpaceHubRemoteDataSourceImpl implements SpaceHubRemoteDataSource {
  SpaceHubRemoteDataSourceImpl({required this.dioClient});

  final DioClient dioClient;
  static final Options _missingEndpointTolerantOptions = Options(
    validateStatus: (status) => status != null && status < 500,
  );

  @override
  Future<SpaceHubBindingModel?> getBinding(String spaceId) async {
    try {
      final response = await dioClient.get(
        ApiConstants.spaceHubBinding(spaceId),
        options: _missingEndpointTolerantOptions,
      );
      if (response.statusCode == 404) {
        return null;
      }
      return _parseBinding(response.data);
    } on DioException catch (error) {
      throw ServerException(_extractErrorMessage(error));
    } catch (error) {
      throw ServerException('Failed to fetch hub binding: $error');
    }
  }

  @override
  Future<SpaceHubBindingModel> upsertBinding(
      SpaceHubBindingModel binding) async {
    try {
      final response = await dioClient.put(
        ApiConstants.spaceHubBinding(binding.spaceId),
        data: binding.toJson(),
        options: _missingEndpointTolerantOptions,
      );
      if (response.statusCode == 404) {
        throw ServerException(
          'Hub binding endpoint is not available on the backend yet.',
        );
      }
      return _parseBinding(response.data) ?? binding;
    } on DioException catch (error) {
      throw ServerException(_extractErrorMessage(error));
    } catch (error) {
      throw ServerException('Failed to save hub binding: $error');
    }
  }

  @override
  Future<void> deleteBinding(String spaceId) async {
    try {
      final response = await dioClient.delete(
        ApiConstants.spaceHubBinding(spaceId),
        options: _missingEndpointTolerantOptions,
      );
      if (response.statusCode == 404) return;
    } on DioException catch (error) {
      throw ServerException(_extractErrorMessage(error));
    } catch (error) {
      throw ServerException('Failed to delete hub binding: $error');
    }
  }

  @override
  Future<void> restartHub(String spaceId) async {
    try {
      final response = await dioClient.post(
        ApiConstants.restartSpaceHub(spaceId),
        options: _missingEndpointTolerantOptions,
      );
      if (response.statusCode == 404) {
        throw ServerException(
          'Hub restart endpoint is not available on the backend yet.',
        );
      }
    } on DioException catch (error) {
      throw ServerException(_extractErrorMessage(error));
    } catch (error) {
      throw ServerException('Failed to restart hub: $error');
    }
  }

  SpaceHubBindingModel? _parseBinding(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final nestedData = payload['data'];
      if (nestedData is Map<String, dynamic>) {
        return SpaceHubBindingModel.fromJson(nestedData);
      }
      if (payload['spaceId'] != null) {
        return SpaceHubBindingModel.fromJson(payload);
      }
    }
    return null;
  }

  String _extractErrorMessage(DioException error) {
    final payload = error.response?.data;
    if (payload is Map<String, dynamic>) {
      final errors = payload['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is Map<String, dynamic>) {
          final message = first['message']?.toString();
          if (message != null && message.trim().isNotEmpty) {
            return message;
          }
        }
        final message = first.toString();
        if (message.trim().isNotEmpty) return message;
      }

      final message = payload['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
    }

    if (error.message != null && error.message!.trim().isNotEmpty) {
      return error.message!;
    }
    return 'Hub request failed.';
  }
}
