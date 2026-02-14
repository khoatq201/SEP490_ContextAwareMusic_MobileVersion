import '../models/store_summary_model.dart';

abstract class StoreSelectionRemoteDataSource {
  /// Fetches stores by their IDs from the API
  Future<List<StoreSummaryModel>> getStoresByIds(List<String> storeIds);
}

class StoreSelectionRemoteDataSourceImpl
    implements StoreSelectionRemoteDataSource {
  @override
  Future<List<StoreSummaryModel>> getStoresByIds(List<String> storeIds) async {
    // TODO: Implement actual API call when backend is ready
    // For now, return mock data
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock data based on storeIds
    final mockStores = <StoreSummaryModel>[
      const StoreSummaryModel(
        id: 'store-001',
        name: 'Downtown Store',
        address: '123 Main Street, District 1, Ho Chi Minh City',
        spacesCount: 5,
        imageUrl: null,
      ),
      const StoreSummaryModel(
        id: 'store-002',
        name: 'Shopping Mall Branch',
        address: '456 Nguyen Hue, District 1, Ho Chi Minh City',
        spacesCount: 8,
        imageUrl: null,
      ),
      const StoreSummaryModel(
        id: 'store-003',
        name: 'Airport Store',
        address: 'Tan Son Nhat Airport, Tan Binh District, Ho Chi Minh City',
        spacesCount: 3,
        imageUrl: null,
      ),
    ];

    // Filter by requested storeIds
    return mockStores.where((store) => storeIds.contains(store.id)).toList();
  }
}
