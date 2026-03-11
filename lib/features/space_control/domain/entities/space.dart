import 'package:equatable/equatable.dart';
import 'package:cams_store_manager/features/hub_management/domain/entities/hub_entity.dart';
import '../../../../core/enums/entity_status_enum.dart';
import '../../../../core/enums/space_type_enum.dart';

class Space extends Equatable {
  final String id;
  final String name;
  final String storeId;
  
  // Real API fields
  final SpaceTypeEnum type;
  final String? description;
  final EntityStatusEnum status; 
  final String? cameraId;
  final String? roiCoordinates;
  final int? maxOccupancy;
  final int? criticalQueueThreshold;
  final String? wiFiSensorId;
  final String? currentPlaylistId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Mock / UI fields
  final String? currentMood;
  final String? assignedHubId;

  /// The resolved Hub device for this space. Null when no hub is installed.
  final HubEntity? currentHub;

  const Space({
    required this.id,
    required this.name,
    required this.storeId,
    required this.type,
    this.description,
    required this.status,
    this.cameraId,
    this.roiCoordinates,
    this.maxOccupancy,
    this.criticalQueueThreshold,
    this.wiFiSensorId,
    this.currentPlaylistId,
    this.createdAt,
    this.updatedAt,
    this.currentMood,
    this.assignedHubId,
    this.currentHub,
  });

  Space copyWith({
    String? id,
    String? name,
    String? storeId,
    SpaceTypeEnum? type,
    String? description,
    EntityStatusEnum? status,
    String? cameraId,
    String? roiCoordinates,
    int? maxOccupancy,
    int? criticalQueueThreshold,
    String? wiFiSensorId,
    String? currentPlaylistId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? currentMood,
    String? assignedHubId,
    HubEntity? currentHub,
  }) {
    return Space(
      id: id ?? this.id,
      name: name ?? this.name,
      storeId: storeId ?? this.storeId,
      type: type ?? this.type,
      description: description ?? this.description,
      status: status ?? this.status,
      cameraId: cameraId ?? this.cameraId,
      roiCoordinates: roiCoordinates ?? this.roiCoordinates,
      maxOccupancy: maxOccupancy ?? this.maxOccupancy,
      criticalQueueThreshold: criticalQueueThreshold ?? this.criticalQueueThreshold,
      wiFiSensorId: wiFiSensorId ?? this.wiFiSensorId,
      currentPlaylistId: currentPlaylistId ?? this.currentPlaylistId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentMood: currentMood ?? this.currentMood,
      assignedHubId: assignedHubId ?? this.assignedHubId,
      currentHub: currentHub ?? this.currentHub,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        storeId,
        type,
        description,
        status,
        cameraId,
        roiCoordinates,
        maxOccupancy,
        criticalQueueThreshold,
        wiFiSensorId,
        currentPlaylistId,
        createdAt,
        updatedAt,
        currentMood,
        assignedHubId,
        currentHub,
      ];

  bool get isOnline => status.isActive;
  bool get isOffline => !isOnline;
}

