import '../../domain/entities/location_space.dart';

class LocationSpaceModel extends LocationSpace {
  const LocationSpaceModel({
    required super.id,
    required super.name,
    required super.storeId,
    required super.storeName,
    required super.isOnline,
    super.currentTrackName,
    required super.volume,
  });

  factory LocationSpaceModel.fromJson(Map<String, dynamic> json) {
    return LocationSpaceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      storeId: json['storeId'] as String,
      storeName: json['storeName'] as String,
      isOnline: json['isOnline'] as bool? ?? false,
      currentTrackName: json['currentTrackName'] as String?,
      volume: (json['volume'] as num?)?.toDouble() ?? 50.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'storeId': storeId,
      'storeName': storeName,
      'isOnline': isOnline,
      'currentTrackName': currentTrackName,
      'volume': volume,
    };
  }
}
