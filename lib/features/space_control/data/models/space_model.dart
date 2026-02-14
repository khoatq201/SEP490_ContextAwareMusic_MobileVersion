import '../../domain/entities/space.dart';

class SpaceModel extends Space {
  const SpaceModel({
    required super.id,
    required super.name,
    required super.status,
    super.currentMood,
    required super.assignedHubId,
    required super.storeId,
  });

  factory SpaceModel.fromJson(Map<String, dynamic> json) {
    return SpaceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      currentMood: json['currentMood'] as String?,
      assignedHubId: json['assignedHubId'] as String,
      storeId: json['storeId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'currentMood': currentMood,
      'assignedHubId': assignedHubId,
      'storeId': storeId,
    };
  }

  Space toEntity() {
    return Space(
      id: id,
      name: name,
      status: status,
      currentMood: currentMood,
      assignedHubId: assignedHubId,
      storeId: storeId,
    );
  }

  factory SpaceModel.fromEntity(Space space) {
    return SpaceModel(
      id: space.id,
      name: space.name,
      status: space.status,
      currentMood: space.currentMood,
      assignedHubId: space.assignedHubId,
      storeId: space.storeId,
    );
  }
}
