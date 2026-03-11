import 'package:equatable/equatable.dart';

import '../../../../core/enums/entity_status_enum.dart';
import '../../../../core/enums/space_type_enum.dart';

/// Represents a space (and its summary info) displayed in the Location Tab.
class LocationSpace extends Equatable {
  final String id;
  final String name;
  final String storeId;
  
  // Real API fields
  final SpaceTypeEnum type;
  final String? description;
  final EntityStatusEnum status;
  final String? currentPlaylistId;
  
  // Legacy / UI Mock fields
  final String? storeName;
  final bool isOnline; // Kept for UI backwards compatibility 
  final String? currentTrackName;
  final double volume;

  const LocationSpace({
    required this.id,
    required this.name,
    required this.storeId,
    required this.type,
    this.description,
    required this.status,
    this.currentPlaylistId,
    this.storeName,
    this.isOnline = false,
    this.currentTrackName,
    this.volume = 50.0,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        storeId,
        type,
        description,
        status,
        currentPlaylistId,
        storeName,
        isOnline,
        currentTrackName,
        volume,
      ];
}
