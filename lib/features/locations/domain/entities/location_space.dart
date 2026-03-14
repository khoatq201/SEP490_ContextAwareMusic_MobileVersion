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
  final String? currentPlaylistName;
  final String? currentMoodName;
  final String? currentTrackName;
  final String? currentTrackArtist;
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
    this.currentPlaylistName,
    this.currentMoodName,
    this.currentTrackName,
    this.currentTrackArtist,
    this.volume = 50.0,
  });

  bool get hasLivePlayback =>
      (currentPlaylistId != null && currentPlaylistId!.isNotEmpty) ||
      (currentTrackName != null && currentTrackName!.isNotEmpty);

  LocationSpace copyWith({
    String? id,
    String? name,
    String? storeId,
    SpaceTypeEnum? type,
    String? description,
    EntityStatusEnum? status,
    String? currentPlaylistId,
    String? storeName,
    bool? isOnline,
    String? currentPlaylistName,
    String? currentMoodName,
    String? currentTrackName,
    String? currentTrackArtist,
    double? volume,
  }) {
    return LocationSpace(
      id: id ?? this.id,
      name: name ?? this.name,
      storeId: storeId ?? this.storeId,
      type: type ?? this.type,
      description: description ?? this.description,
      status: status ?? this.status,
      currentPlaylistId: currentPlaylistId ?? this.currentPlaylistId,
      storeName: storeName ?? this.storeName,
      isOnline: isOnline ?? this.isOnline,
      currentPlaylistName: currentPlaylistName ?? this.currentPlaylistName,
      currentMoodName: currentMoodName ?? this.currentMoodName,
      currentTrackName: currentTrackName ?? this.currentTrackName,
      currentTrackArtist: currentTrackArtist ?? this.currentTrackArtist,
      volume: volume ?? this.volume,
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
        currentPlaylistId,
        storeName,
        isOnline,
        currentPlaylistName,
        currentMoodName,
        currentTrackName,
        currentTrackArtist,
        volume,
      ];
}
