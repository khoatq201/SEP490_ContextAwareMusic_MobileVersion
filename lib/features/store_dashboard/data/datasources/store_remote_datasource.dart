import '../models/store_model.dart';
import '../models/space_summary_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';

abstract class StoreRemoteDataSource {
  Future<StoreModel> getStoreDetails(String storeId);
  Future<List<SpaceSummaryModel>> getSpaceSummaries(String storeId);
}

/// Real API implementation of [StoreRemoteDataSource].
class StoreRemoteDataSourceImpl implements StoreRemoteDataSource {
  final DioClient dioClient;

  StoreRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<StoreModel> getStoreDetails(String storeId) async {
    try {
      final response = await dioClient.get(
        '${ApiConstants.getStoresEndpoint}/$storeId',
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return StoreModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return StoreModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException('Failed to get store details: $e');
    }
  }

  @override
  Future<List<SpaceSummaryModel>> getSpaceSummaries(String storeId) async {
    try {
      final endpoint =
          ApiConstants.getSpacesEndpoint.replaceFirst('{storeId}', storeId);
      final response = await dioClient.get(endpoint);
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return (data['data'] as List)
            .map((e) => SpaceSummaryModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return (data as List)
          .map((e) => SpaceSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get space summaries: $e');
    }
  }
}
