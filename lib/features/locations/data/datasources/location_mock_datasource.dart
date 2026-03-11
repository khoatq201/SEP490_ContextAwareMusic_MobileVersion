import 'dart:async';
import '../../../../core/enums/entity_status_enum.dart';
import '../../../../core/enums/space_type_enum.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/models/pagination_result.dart';
import '../models/location_space_model.dart';
import 'location_remote_datasource.dart';

class LocationMockDataSource implements LocationRemoteDataSource {
  final Map<String, List<LocationSpaceModel>> _mockData = {
    'store-1': [
      const LocationSpaceModel(
        id: 'space-1',
        name: 'Floor 1',
        storeId: 'store-1',
        type: SpaceTypeEnum.hall,
        status: EntityStatusEnum.active,
        description: 'Main dining area',
        storeName: 'Highlands Coffee',
        isOnline: true,
        currentTrackName: 'Lofi Chill Beat',
        volume: 65,
      ),
      const LocationSpaceModel(
        id: 'space-2',
        name: 'Floor 2',
        storeId: 'store-1',
        type: SpaceTypeEnum.hall,
        status: EntityStatusEnum.inactive,
        description: 'Quiet working space',
        storeName: 'Highlands Coffee',
        isOnline: false,
        volume: 50,
      ),
    ],
    'store-2': [
      const LocationSpaceModel(
        id: 'space-3',
        name: 'Meeting Room',
        storeId: 'store-2',
        type: SpaceTypeEnum.counter,
        status: EntityStatusEnum.active,
        description: 'Private booking room',
        storeName: 'The Coffee House',
        isOnline: true,
        currentTrackName: 'Acoustic Guitar',
        volume: 40,
      ),
    ],
    'store-3': [
      const LocationSpaceModel(
        id: 'space-4',
        name: 'Lobby',
        storeId: 'store-3',
        type: SpaceTypeEnum.entrance,
        status: EntityStatusEnum.active,
        description: 'Waiting area',
        storeName: 'Airport Store',
        isOnline: true,
        currentTrackName: 'Jazz Lounge',
        volume: 55,
      ),
      const LocationSpaceModel(
        id: 'space-5',
        name: 'VIP Area',
        storeId: 'store-3',
        type: SpaceTypeEnum.hall,
        status: EntityStatusEnum.inactive,
        description: 'Premium customer area',
        storeName: 'Airport Store',
        isOnline: false,
        volume: 30,
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
  Future<PaginationResult<LocationSpaceModel>> getSpacesForStore(
      String storeId, {int page = 1, int pageSize = 10}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final items = _mockData[storeId] ?? [];
    return PaginationResult<LocationSpaceModel>(
      currentPage: page,
      pageSize: pageSize,
      totalItems: items.length,
      totalPages: 1,
      hasPrevious: false,
      hasNext: false,
      items: items,
    );
  }

  @override
  Future<Map<String, PaginationResult<LocationSpaceModel>>> getSpacesForBrand(
      List<String> storeIds, {int page = 1, int pageSize = 10}) async {
    await Future.delayed(const Duration(seconds: 1));
    final result = <String, PaginationResult<LocationSpaceModel>>{};
    for (final storeId in storeIds) {
      if (_mockData.containsKey(storeId)) {
        final items = _mockData[storeId]!;
        result[storeId] = PaginationResult<LocationSpaceModel>(
          currentPage: page,
          pageSize: pageSize,
          totalItems: items.length,
          totalPages: 1,
          hasPrevious: false,
          hasNext: false,
          items: items,
        );
      }
    }
    return result;
  }
}

