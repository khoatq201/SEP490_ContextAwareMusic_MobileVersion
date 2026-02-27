import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/models/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../models/store_summary_model.dart';

abstract class StoreSelectionRemoteDataSource {
  /// Fetches stores the current user has access to (backend filters by JWT).
  Future<List<StoreSummaryModel>> getUserStores();
}

class StoreSelectionRemoteDataSourceImpl
    implements StoreSelectionRemoteDataSource {
  final DioClient dioClient;

  StoreSelectionRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<StoreSummaryModel>> getUserStores() async {
    if (ApiConstants.useMockData) {
      return _getMockStores();
    }

    final response = await dioClient.get(ApiConstants.getStoresEndpoint);

    final apiResult = ApiResult<List<StoreSummaryModel>>.fromJson(
      response.data as Map<String, dynamic>,
      fromData: (data) => (data as List<dynamic>)
          .map((e) => StoreSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

    if (!apiResult.isSuccess || apiResult.data == null) {
      throw ServerException(apiResult.userFriendlyError);
    }

    return apiResult.data!;
  }

  /// Mock data for development.
  Future<List<StoreSummaryModel>> _getMockStores() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const [
      StoreSummaryModel(
        id: 'store-1',
        name: 'Highlands Coffee',
        address: '123 Main Street, District 1, Ho Chi Minh City',
        spacesCount: 2,
      ),
      StoreSummaryModel(
        id: 'store-2',
        name: 'The Coffee House',
        address: '456 Nguyen Hue, District 1, Ho Chi Minh City',
        spacesCount: 1,
      ),
      StoreSummaryModel(
        id: 'store-3',
        name: 'Airport Store',
        address: 'Tan Son Nhat Airport, Tan Binh District, Ho Chi Minh City',
        spacesCount: 0,
      ),
    ];
  }
}
