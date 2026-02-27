import 'package:equatable/equatable.dart';
import 'package:cams_store_manager/features/hub_management/domain/entities/hub_entity.dart';

class Space extends Equatable {
  final String id;
  final String name;
  final String status; // Online, Offline
  final String? currentMood;
  final String assignedHubId;
  final String storeId;

  /// The resolved Hub device for this space. Null when no hub is installed.
  final HubEntity? currentHub;

  const Space({
    required this.id,
    required this.name,
    required this.status,
    this.currentMood,
    required this.assignedHubId,
    required this.storeId,
    this.currentHub,
  });

  Space copyWith({
    String? id,
    String? name,
    String? status,
    String? currentMood,
    String? assignedHubId,
    String? storeId,
    HubEntity? currentHub,
  }) {
    return Space(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      currentMood: currentMood ?? this.currentMood,
      assignedHubId: assignedHubId ?? this.assignedHubId,
      storeId: storeId ?? this.storeId,
      currentHub: currentHub ?? this.currentHub,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, status, currentMood, assignedHubId, storeId, currentHub];

  bool get isOnline => status == 'Online';
  bool get isOffline => status == 'Offline';
}
