import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/models/pagination_result.dart';
import '../../../../core/network/dio_client.dart';
import '../models/location_space_model.dart';
import 'location_remote_datasource.dart';

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
        return LocationSpaceModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return LocationSpaceModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException('Failed to fetch space: $e');
    }
  }

  @override
  Future<PaginationResult<LocationSpaceModel>> getSpacesForStore(String storeId, {int page = 1, int pageSize = 10}) async {
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
      List<String> storeIds, {int page = 1, int pageSize = 10}) async {
    try {
      final result = <String, PaginationResult<LocationSpaceModel>>{};
      // Future-proofing: Normally you'd want to request all by brandId in a single call,
      // but following the existing pattern we fetch per store.
      for (final storeId in storeIds) {
        result[storeId] = await getSpacesForStore(storeId, page: page, pageSize: pageSize);
      }
      return result;
    } catch (e) {
      throw ServerException('Failed to fetch spaces for brand: $e');
    }
  }
}

