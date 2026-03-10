import '../../../../core/constants/api_constants.dart';
import '../../../../core/enums/entity_status_enum.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/models/pagination_result.dart';
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

    final response = await dioClient.get(
      ApiConstants.getStoresEndpoint,
      queryParameters: {'pageSize': 500},
    );

    final data = response.data as Map<String, dynamic>;

    // API returns: { isSuccess, message, data: null, currentPage, pageSize, totalItems, ..., items: [...] }
    // OR: { isSuccess, data: { currentPage, ..., items: [...] } }
    // Handle both: pagination at root level or nested under 'data'.
    final bool isSuccess = data['isSuccess'] as bool? ?? false;
    if (!isSuccess) {
      throw ServerException(
        data['message'] as String? ?? 'Failed to load stores',
      );
    }

    // Determine where the paginated data lives
    final Map<String, dynamic> paginatedData;
    if (data.containsKey('items')) {
      // Pagination fields are at root level
      paginatedData = data;
    } else if (data['data'] is Map<String, dynamic>) {
      paginatedData = data['data'] as Map<String, dynamic>;
    } else {
      throw ServerException('Unexpected response format for stores');
    }

    final paginationResult = PaginationResult<StoreSummaryModel>.fromJson(
      paginatedData,
      fromItemJson: StoreSummaryModel.fromJson,
    );

    return paginationResult.items;
  }

  /// Mock data for development.
  Future<List<StoreSummaryModel>> _getMockStores() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const [
      StoreSummaryModel(
        id: 'store-1',
        brandId: 'brand-001',
        name: 'Highlands Coffee',
        address: '123 Main Street',
        city: 'Ho Chi Minh City',
        district: 'District 1',
        status: EntityStatusEnum.active,
      ),
      StoreSummaryModel(
        id: 'store-2',
        brandId: 'brand-001',
        name: 'The Coffee House',
        address: '456 Nguyen Hue',
        city: 'Ho Chi Minh City',
        district: 'District 1',
        status: EntityStatusEnum.active,
      ),
      StoreSummaryModel(
        id: 'store-3',
        brandId: 'brand-001',
        name: 'Airport Store',
        address: 'Tan Son Nhat Airport',
        city: 'Ho Chi Minh City',
        district: 'Tan Binh District',
        status: EntityStatusEnum.pending,
      ),
    ];
  }
}
