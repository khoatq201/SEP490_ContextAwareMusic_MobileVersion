import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
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
      if (data is Map<String, dynamic> && data['data'] != null) {
        return LocationSpaceModel.fromJson(
            data['data'] as Map<String, dynamic>);
      }
      return LocationSpaceModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException('Failed to fetch space: $e');
    }
  }

  @override
  Future<List<LocationSpaceModel>> getSpacesForStore(String storeId) async {
    try {
      final endpoint =
          ApiConstants.getSpacesEndpoint.replaceFirst('{storeId}', storeId);
      final response = await dioClient.get(endpoint);
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return (data['data'] as List)
            .map((json) =>
                LocationSpaceModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return (data as List)
          .map((json) =>
              LocationSpaceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch spaces for store: $e');
    }
  }

  @override
  Future<Map<String, List<LocationSpaceModel>>> getSpacesForBrand(
      List<String> storeIds) async {
    try {
      final result = <String, List<LocationSpaceModel>>{};
      for (final storeId in storeIds) {
        result[storeId] = await getSpacesForStore(storeId);
      }
      return result;
    } catch (e) {
      throw ServerException('Failed to fetch spaces for brand: $e');
    }
  }
}
