import 'package:equatable/equatable.dart';

/// Represents a space (and its summary info) displayed in the Location Tab.
class LocationSpace extends Equatable {
  final String id;
  final String name;
  final String storeId;
  final String storeName;
  final bool isOnline;
  final String? currentTrackName;
  final double volume;

  const LocationSpace({
    required this.id,
    required this.name,
    required this.storeId,
    required this.storeName,
    required this.isOnline,
    this.currentTrackName,
    required this.volume,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        storeId,
        storeName,
        isOnline,
        currentTrackName,
        volume,
      ];
}
