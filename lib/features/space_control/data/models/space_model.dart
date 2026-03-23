import '../../../../core/enums/entity_status_enum.dart';
import '../../../../core/enums/space_type_enum.dart';
import '../../domain/entities/space.dart';

class SpaceModel extends Space {
  const SpaceModel({
    required super.id,
    required super.name,
    required super.storeId,
    required super.type,
    super.description,
    required super.status,
    super.cameraId,
    super.roiCoordinates,
    super.maxOccupancy,
    super.criticalQueueThreshold,
    super.wiFiSensorId,
    super.currentPlaylistId,
    super.createdAt,
    super.updatedAt,
    super.currentMood,
    super.assignedHubId,
  });

  factory SpaceModel.fromJson(Map<String, dynamic> json) {
    final statusEnum =
        EntityStatusEnum.fromJson(json['status'] ?? json['statusStr']);
    final typeEnum = SpaceTypeEnum.fromValue(json['type'] as int?);

    return SpaceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      storeId: json['storeId'] as String,
      type: typeEnum,
      description: json['description'] as String?,
      status: statusEnum,
      cameraId: json['cameraId'] as String?,
      roiCoordinates: json['roiCoordinates'] as String?,
      maxOccupancy: json['maxOccupancy'] as int?,
      criticalQueueThreshold: json['criticalQueueThreshold'] as int?,
      wiFiSensorId: json['wiFiSensorId'] as String?,
      currentPlaylistId: json['currentPlaylistId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      currentMood: json['currentMood'] as String?,
      assignedHubId: json['assignedHubId'] as String?,
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
      'cameraId': cameraId,
      'roiCoordinates': roiCoordinates,
      'maxOccupancy': maxOccupancy,
      'criticalQueueThreshold': criticalQueueThreshold,
      'wiFiSensorId': wiFiSensorId,
      'currentPlaylistId': currentPlaylistId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'currentMood': currentMood,
      'assignedHubId': assignedHubId,
    };
  }

  Space toEntity() {
    return Space(
      id: id,
      name: name,
      storeId: storeId,
      type: type,
      description: description,
      status: status,
      cameraId: cameraId,
      roiCoordinates: roiCoordinates,
      maxOccupancy: maxOccupancy,
      criticalQueueThreshold: criticalQueueThreshold,
      wiFiSensorId: wiFiSensorId,
      currentPlaylistId: currentPlaylistId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      currentMood: currentMood,
      assignedHubId: assignedHubId,
    );
  }

  factory SpaceModel.fromEntity(Space space) {
    return SpaceModel(
      id: space.id,
      name: space.name,
      storeId: space.storeId,
      type: space.type,
      description: space.description,
      status: space.status,
      cameraId: space.cameraId,
      roiCoordinates: space.roiCoordinates,
      maxOccupancy: space.maxOccupancy,
      criticalQueueThreshold: space.criticalQueueThreshold,
      wiFiSensorId: space.wiFiSensorId,
      currentPlaylistId: space.currentPlaylistId,
      createdAt: space.createdAt,
      updatedAt: space.updatedAt,
      currentMood: space.currentMood,
      assignedHubId: space.assignedHubId,
    );
  }
}
