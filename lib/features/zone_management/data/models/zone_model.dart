import '../../domain/entities/zone.dart';

class ZoneModel extends Zone {
  const ZoneModel({
    required super.id,
    required super.name,
    required super.spaceId,
    super.floorLevel,
    required super.speakerIds,
    required super.musicProfileId,
    super.boundary,
    required super.isActive,
    required super.createdAt,
    super.updatedAt,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    return ZoneModel(
      id: json['id'] as String,
      name: json['name'] as String,
      spaceId: json['spaceId'] as String,
      floorLevel: json['floorLevel'] as String?,
      speakerIds: (json['speakerIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      musicProfileId: json['musicProfileId'] as String,
      boundary: json['boundary'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'spaceId': spaceId,
      'floorLevel': floorLevel,
      'speakerIds': speakerIds,
      'musicProfileId': musicProfileId,
      'boundary': boundary,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ZoneModel.fromEntity(Zone zone) {
    return ZoneModel(
      id: zone.id,
      name: zone.name,
      spaceId: zone.spaceId,
      floorLevel: zone.floorLevel,
      speakerIds: zone.speakerIds,
      musicProfileId: zone.musicProfileId,
      boundary: zone.boundary,
      isActive: zone.isActive,
      createdAt: zone.createdAt,
      updatedAt: zone.updatedAt,
    );
  }
}
