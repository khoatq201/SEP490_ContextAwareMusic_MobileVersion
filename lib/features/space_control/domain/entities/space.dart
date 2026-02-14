import 'package:equatable/equatable.dart';

class Space extends Equatable {
  final String id;
  final String name;
  final String status; // Online, Offline
  final String? currentMood;
  final String assignedHubId;
  final String storeId;

  const Space({
    required this.id,
    required this.name,
    required this.status,
    this.currentMood,
    required this.assignedHubId,
    required this.storeId,
  });

  @override
  List<Object?> get props =>
      [id, name, status, currentMood, assignedHubId, storeId];

  bool get isOnline => status == 'Online';
  bool get isOffline => status == 'Offline';
}
