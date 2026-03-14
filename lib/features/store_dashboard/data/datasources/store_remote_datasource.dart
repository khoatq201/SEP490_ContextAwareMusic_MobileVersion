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
      final response = await dioClient.get(
        ApiConstants.getSpacesEndpoint,
        queryParameters: {'storeId': storeId},
      );
      final data = response.data;
      // API returns paginated response: {currentPage, items: [...], ...}
      final rawItems = <dynamic>[
        if (data is Map<String, dynamic>)
          ...(data['items'] as List<dynamic>? ?? [])
        else if (data is List)
          ...data,
      ];

      final summaries = rawItems
          .map((e) => SpaceSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return Future.wait(
        summaries.map((summary) async {
          final moodName = await _getMoodFromSpaceState(
            spaceId: summary.id,
            fallbackMood: summary.currentMood,
          );
          return summary.copyWith(currentMood: moodName);
        }),
      );
    } catch (e) {
      throw ServerException('Failed to get space summaries: $e');
    }
  }

  Future<String> _getMoodFromSpaceState({
    required String spaceId,
    required String fallbackMood,
  }) async {
    try {
      final response = await dioClient.get(ApiConstants.camsState(spaceId));
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final payload = data['data'];
        if (payload is Map<String, dynamic>) {
          final moodName = payload['moodName']?.toString();
          if (moodName != null && moodName.trim().isNotEmpty) {
            return moodName;
          }
        }
      }
    } catch (_) {
      // Keep per-space fallback without failing the full list.
    }
    return fallbackMood;
  }
}
