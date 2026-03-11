import '../../../../core/enums/entity_status_enum.dart';
import '../../../../core/enums/space_type_enum.dart';
import '../../domain/entities/location_space.dart';

class LocationSpaceModel extends LocationSpace {
  const LocationSpaceModel({
    required super.id,
    required super.name,
    required super.storeId,
    required super.type,
    super.description,
    required super.status,
    super.currentPlaylistId,
    super.storeName,
    required super.isOnline,
    super.currentTrackName,
    required super.volume,
  });

  factory LocationSpaceModel.fromJson(Map<String, dynamic> json) {
    // Parse the Enums
    final typeEnum = SpaceTypeEnum.fromValue(json['type'] as int?);
    final statusEnum = EntityStatusEnum.fromJson(json['status'] ?? json['statusStr']);

    return LocationSpaceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      storeId: json['storeId'] as String,
      type: typeEnum,
      description: json['description'] as String?,
      status: statusEnum,
      currentPlaylistId: json['currentPlaylistId'] as String?,
      
      // Keep support for UI mocks if they are passed through
      storeName: json['storeName'] as String?,
      isOnline: json['isOnline'] as bool? ?? statusEnum.isActive,
      currentTrackName: json['currentTrackName'] as String?,
      volume: (json['volume'] as num?)?.toDouble() ?? 50.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'storeId': storeId,
      'type': type.value,
      'description': description,
      'status': status.value,
      'currentPlaylistId': currentPlaylistId,
      'storeName': storeName,
      'isOnline': isOnline,
      'currentTrackName': currentTrackName,
      'volume': volume,
    };
  }
}

