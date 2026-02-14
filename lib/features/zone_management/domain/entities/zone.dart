import 'package:equatable/equatable.dart';

/// Represents a logical zone within a space (e.g., "Entrance Section", "Center Display")
/// Each zone has its own music profile, speakers, and can operate independently
class Zone extends Equatable {
  final String id;
  final String name;
  final String spaceId;

  /// Floor level within the space (e.g., "Ground", "Mezzanine")
  /// Null if space doesn't have multiple floors
  final String? floorLevel;

  /// List of speaker IDs assigned to this zone
  /// Each speaker can only belong to one zone (1:1 relationship)
  final List<String> speakerIds;

  /// Reference to the music profile configuration for this zone
  final String musicProfileId;

  /// Optional named boundary/area description (e.g., "Near entrance doors")
  /// No coordinates for MVP - just descriptive text
  final String? boundary;

  /// Whether this zone is currently active and operational
  final bool isActive;

  /// When this zone configuration was created
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime? updatedAt;

  const Zone({
    required this.id,
    required this.name,
    required this.spaceId,
    this.floorLevel,
    required this.speakerIds,
    required this.musicProfileId,
    this.boundary,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        spaceId,
        floorLevel,
        speakerIds,
        musicProfileId,
        boundary,
        isActive,
        createdAt,
        updatedAt,
      ];
}
