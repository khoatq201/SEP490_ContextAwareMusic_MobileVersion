import '../models/store_model.dart';
import '../models/space_summary_model.dart';

abstract class StoreRemoteDataSource {
  Future<StoreModel> getStoreDetails(String storeId);
  Future<List<SpaceSummaryModel>> getSpaceSummaries(String storeId);
}

class StoreRemoteDataSourceImpl implements StoreRemoteDataSource {
  // Mock implementation for demo
  @override
  Future<StoreModel> getStoreDetails(String storeId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return StoreModel(
      id: storeId,
      name: 'CAMS Store Central',
      brandId: 'brand-001',
      address: '123 Nguyễn Huệ, Q1, TP.HCM',
      phone: '028 1234 5678',
      email: 'central@camsstore.com',
      totalSpaces: 4,
      activeSpaces: 3,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<SpaceSummaryModel>> getSpaceSummaries(String storeId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      SpaceSummaryModel(
        id: 'space-1',
        name: 'Main Floor',
        storeId: storeId,
        currentMood: 'energetic',
        isOnline: true,
        customerCount: 12,
        temperature: 24.5,
        humidity: 65.0,
        lightLevel: 750,
        isMusicPlaying: true,
        currentTrack: 'Upbeat Retail Mix Vol.3',
        totalZones: 3, // Main Floor has 3 zones
        activeZones: 3,
        hasMultiZoneMusic: true,
      ),
      SpaceSummaryModel(
        id: 'space-2',
        name: 'VIP Lounge',
        storeId: storeId,
        currentMood: 'calm',
        isOnline: true,
        customerCount: 3,
        temperature: 22.0,
        humidity: 60.0,
        lightLevel: 450,
        isMusicPlaying: true,
        currentTrack: 'Ambient Chill Playlist',
        totalZones: 2, // VIP has 2 zones
        activeZones: 2,
        hasMultiZoneMusic: true,
      ),
      SpaceSummaryModel(
        id: 'space-3',
        name: 'Entrance Area',
        storeId: storeId,
        currentMood: 'welcoming',
        isOnline: true,
        customerCount: 8,
        temperature: 25.0,
        humidity: 62.0,
        lightLevel: 900,
        isMusicPlaying: true,
        currentTrack: 'Welcome Vibes',
        totalZones: 1, // Single zone
        activeZones: 1,
        hasMultiZoneMusic: false,
      ),
      SpaceSummaryModel(
        id: 'space-4',
        name: 'Fitting Rooms',
        storeId: storeId,
        currentMood: 'relaxed',
        isOnline: false,
        customerCount: 0,
        temperature: 23.0,
        humidity: 58.0,
        lightLevel: 300,
        isMusicPlaying: false,
        currentTrack: null,
        totalZones: 1, // Single zone
        activeZones: 0, // Offline
        hasMultiZoneMusic: false,
      ),
    ];
  }
}
