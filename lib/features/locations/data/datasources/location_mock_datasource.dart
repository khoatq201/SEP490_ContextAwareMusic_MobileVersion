import 'dart:async';
import 'location_remote_datasource.dart';
import '../models/location_space_model.dart';
import '../../../../core/error/exceptions.dart';

class LocationMockDataSource implements LocationRemoteDataSource {
  final Map<String, List<LocationSpaceModel>> _mockData = {
    'store-1': [
      const LocationSpaceModel(
        id: 'space-1', name: 'Tầng 1', storeId: 'store-1', storeName: 'Highlands Coffee',
        isOnline: true, currentTrackName: 'Lofi Chill Beat', volume: 65,
      ),
      const LocationSpaceModel(
        id: 'space-2', name: 'Tầng 2', storeId: 'store-1', storeName: 'Highlands Coffee',
        isOnline: false, volume: 50,
      ),
    ],
    'store-2': [
      const LocationSpaceModel(
        id: 'space-3', name: 'Phòng Họp', storeId: 'store-2', storeName: 'The Coffee House',
        isOnline: true, currentTrackName: 'Acoustic Guitar', volume: 40,
      ),
    ],
    'store-3': [
      const LocationSpaceModel(
        id: 'space-4', name: 'Sảnh Chờ', storeId: 'store-3', storeName: 'Airport Store',
        isOnline: true, currentTrackName: 'Jazz Lounge', volume: 55,
      ),
      const LocationSpaceModel(
        id: 'space-5', name: 'Khu VIP', storeId: 'store-3', storeName: 'Airport Store',
        isOnline: false, volume: 30,
      ),
    ],
  };

  @override
  Future<LocationSpaceModel> getSpace(String spaceId, String storeId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final storeSpaces = _mockData[storeId];
    if (storeSpaces != null) {
      final space = storeSpaces.cast<LocationSpaceModel?>().firstWhere(
        (s) => s?.id == spaceId,
        orElse: () => null,
      );
      if (space != null) return space;
    }
    throw ServerException('Space not found');
  }

  @override
  Future<List<LocationSpaceModel>> getSpacesForStore(String storeId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockData[storeId] ?? [];
  }

  @override
  Future<Map<String, List<LocationSpaceModel>>> getSpacesForBrand(List<String> storeIds) async {
    await Future.delayed(const Duration(seconds: 1));
    final result = <String, List<LocationSpaceModel>>{};
    for (final storeId in storeIds) {
      if (_mockData.containsKey(storeId)) {
        result[storeId] = _mockData[storeId]!;
      }
    }
    return result;
  }
}
