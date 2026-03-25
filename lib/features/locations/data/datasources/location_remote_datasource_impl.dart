import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/models/pagination_result.dart';
import '../../../../core/network/dio_client.dart';
import '../models/location_space_model.dart';
import 'location_remote_datasource.dart';
import 'package:dio/dio.dart';

/// Real API implementation of [LocationRemoteDataSource].
class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final DioClient dioClient;

  LocationRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<LocationSpaceModel> getSpace(String spaceId, String storeId) async {
    try {
      final endpoint = ApiConstants.getSpaceDetailEndpoint
          .replaceFirst('{spaceId}', spaceId);
      final response = await dioClient.get(endpoint);
      final data = response.data;
      if (data != null && data['data'] != null) {
        return LocationSpaceModel.fromJson(
            data['data'] as Map<String, dynamic>);
      }
      return LocationSpaceModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException('Failed to fetch space: $e');
    }
  }

  @override
  Future<PaginationResult<LocationSpaceModel>> getSpacesForStore(String storeId,
      {int page = 1, int pageSize = 10}) async {
    try {
      final response = await dioClient.get(
        ApiConstants.getSpacesEndpoint,
        queryParameters: {
          'storeId': storeId,
          'page': page,
          'pageSize': pageSize,
        },
      );

      return PaginationResult.fromJson(
        response.data as Map<String, dynamic>,
        fromItemJson: (json) => LocationSpaceModel.fromJson(json),
      );
    } catch (e) {
      throw ServerException('Failed to fetch spaces for store: $e');
    }
  }

  @override
  Future<Map<String, PaginationResult<LocationSpaceModel>>> getSpacesForBrand(
      List<String> storeIds,
      {int page = 1,
      int pageSize = 10}) async {
    try {
      final result = <String, PaginationResult<LocationSpaceModel>>{};
      // Future-proofing: Normally you'd want to request all by brandId in a single call,
      // but following the existing pattern we fetch per store.
      for (final storeId in storeIds) {
        result[storeId] =
            await getSpacesForStore(storeId, page: page, pageSize: pageSize);
      }
      return result;
    } catch (e) {
      throw ServerException('Failed to fetch spaces for brand: $e');
    }
  }

  @override
  Future<SpaceMutationResult> createSpace(SpaceMutationRequest request) async {
    try {
      final response = await dioClient.post(
        ApiConstants.getSpacesEndpoint,
        data: request.toJson(),
      );
      return _parseMutationResult(response.data);
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMessage(e, fallback: 'Failed to create space.'),
      );
    } catch (e) {
      throw ServerException('Failed to create space: $e');
    }
  }

  @override
  Future<SpaceMutationResult> updateSpace(
    String spaceId,
    SpaceMutationRequest request,
  ) async {
    try {
      final response = await dioClient.put(
        ApiConstants.updateSpace(spaceId),
        data: request.toJson(),
      );
      return _parseMutationResult(response.data);
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMessage(e, fallback: 'Failed to update space.'),
      );
    } catch (e) {
      throw ServerException('Failed to update space: $e');
    }
  }

  @override
  Future<SpaceMutationResult> deleteSpace(String spaceId) async {
    try {
      final response =
          await dioClient.delete(ApiConstants.deleteSpace(spaceId));
      return _parseMutationResult(response.data);
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMessage(e, fallback: 'Failed to delete space.'),
      );
    } catch (e) {
      throw ServerException('Failed to delete space: $e');
    }
  }

  @override
  Future<SpaceMutationResult> toggleSpaceStatus(String spaceId) async {
    try {
      final response =
          await dioClient.put(ApiConstants.toggleSpaceStatus(spaceId));
      return _parseMutationResult(response.data);
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMessage(
          e,
          fallback: 'Failed to toggle space status.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to toggle space status: $e');
    }
  }

  SpaceMutationResult _parseMutationResult(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['isSuccess'] == false) {
        throw ServerException(_extractErrorMessage(data));
      }
      return SpaceMutationResult.fromJson(data);
    }
    return const SpaceMutationResult(isSuccess: true);
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
    final message = payload['message']?.toString();
    if (message != null && message.trim().isNotEmpty) {
      return message;
    }
    return 'Request failed.';
  }
}
