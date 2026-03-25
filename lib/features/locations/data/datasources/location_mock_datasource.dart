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
        currentPlaylistName: 'Morning Roast',
        currentMoodName: 'Energetic',
        currentTrackName: 'Lofi Chill Beat',
        currentTrackArtist: 'Cafe Collective',
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
        currentPlaylistName: 'Focus Flow',
        currentMoodName: 'Focus',
        currentTrackName: 'Acoustic Guitar',
        currentTrackArtist: 'Studio Strings',
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
        currentPlaylistName: 'Sky Lounge',
        currentMoodName: 'Chill',
        currentTrackName: 'Jazz Lounge',
        currentTrackArtist: 'Blue Evening Trio',
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
  Future<PaginationResult<LocationSpaceModel>> getSpacesForStore(String storeId,
      {int page = 1, int pageSize = 10}) async {
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
      List<String> storeIds,
      {int page = 1,
      int pageSize = 10}) async {
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

  @override
  Future<SpaceMutationResult> createSpace(SpaceMutationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final storeId = request.storeId;
    final name = request.name?.trim() ?? '';
    if (storeId == null ||
        storeId.isEmpty ||
        name.isEmpty ||
        request.type == null) {
      throw ServerException('Invalid payload for creating space.');
    }

    final created = LocationSpaceModel(
      id: 'space-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      storeId: storeId,
      type: SpaceTypeEnum.fromValue(request.type),
      description: request.description,
      status: EntityStatusEnum.active,
      storeName: _resolveStoreName(storeId),
      isOnline: true,
      volume: 50,
    );
    final spaces = _mockData.putIfAbsent(storeId, () => <LocationSpaceModel>[]);
    spaces.add(created);
    return const SpaceMutationResult(
      isSuccess: true,
      message: 'Space created successfully',
    );
  }

  @override
  Future<SpaceMutationResult> updateSpace(
    String spaceId,
    SpaceMutationRequest request,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (final entry in _mockData.entries) {
      final index = entry.value.indexWhere((space) => space.id == spaceId);
      if (index < 0) continue;

      final current = entry.value[index];
      final updated = LocationSpaceModel(
        id: current.id,
        name: request.name?.trim().isNotEmpty == true
            ? request.name!.trim()
            : current.name,
        storeId: current.storeId,
        type: request.type != null
            ? SpaceTypeEnum.fromValue(request.type)
            : current.type,
        description: request.description ?? current.description,
        status: current.status,
        currentPlaylistId: current.currentPlaylistId,
        storeName: current.storeName,
        isOnline: current.isOnline,
        currentPlaylistName: current.currentPlaylistName,
        currentMoodName: current.currentMoodName,
        currentTrackName: current.currentTrackName,
        currentTrackArtist: current.currentTrackArtist,
        hasActivePlayback: current.hasActivePlayback,
        volume: current.volume,
        pairDeviceInfo: current.pairDeviceInfo,
        activePairCode: current.activePairCode,
      );
      entry.value[index] = updated;
      return const SpaceMutationResult(
        isSuccess: true,
        message: 'Space updated successfully',
      );
    }
    throw ServerException('Space not found.');
  }

  @override
  Future<SpaceMutationResult> deleteSpace(String spaceId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (final entry in _mockData.entries) {
      final before = entry.value.length;
      entry.value.removeWhere((space) => space.id == spaceId);
      if (entry.value.length != before) {
        return const SpaceMutationResult(
          isSuccess: true,
          message: 'Space deleted successfully',
        );
      }
    }
    throw ServerException('Space not found.');
  }

  @override
  Future<SpaceMutationResult> toggleSpaceStatus(String spaceId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (final entry in _mockData.entries) {
      final index = entry.value.indexWhere((space) => space.id == spaceId);
      if (index < 0) continue;

      final current = entry.value[index];
      final nextStatus = current.status.isActive
          ? EntityStatusEnum.inactive
          : EntityStatusEnum.active;
      entry.value[index] = LocationSpaceModel(
        id: current.id,
        name: current.name,
        storeId: current.storeId,
        type: current.type,
        description: current.description,
        status: nextStatus,
        currentPlaylistId: current.currentPlaylistId,
        storeName: current.storeName,
        isOnline: nextStatus.isActive,
        currentPlaylistName: current.currentPlaylistName,
        currentMoodName: current.currentMoodName,
        currentTrackName: current.currentTrackName,
        currentTrackArtist: current.currentTrackArtist,
        hasActivePlayback: current.hasActivePlayback,
        volume: current.volume,
        pairDeviceInfo: current.pairDeviceInfo,
        activePairCode: current.activePairCode,
      );
      return const SpaceMutationResult(
        isSuccess: true,
        message: 'Space status updated successfully',
      );
    }
    throw ServerException('Space not found.');
  }

  String? _resolveStoreName(String storeId) {
    switch (storeId) {
      case 'store-1':
        return 'Highlands Coffee';
      case 'store-2':
        return 'The Coffee House';
      case 'store-3':
        return 'Airport Store';
      default:
        return null;
    }
  }
}
