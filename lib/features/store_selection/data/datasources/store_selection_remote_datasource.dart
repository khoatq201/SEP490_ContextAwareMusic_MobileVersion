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
        id: 'store-1',
        name: 'Highlands Coffee',
        address: '123 Main Street, District 1, Ho Chi Minh City',
        spacesCount: 2,
        imageUrl: null,
      ),
      const StoreSummaryModel(
        id: 'store-2',
        name: 'The Coffee House',
        address: '456 Nguyen Hue, District 1, Ho Chi Minh City',
        spacesCount: 1,
        imageUrl: null,
      ),
      const StoreSummaryModel(
        id: 'store-3',
        name: 'Airport Store',
        address: 'Tan Son Nhat Airport, Tan Binh District, Ho Chi Minh City',
        spacesCount: 0,
        imageUrl: null,
      ),
    ];

    // Filter by requested storeIds
    return mockStores.where((store) => storeIds.contains(store.id)).toList();
  }
}
