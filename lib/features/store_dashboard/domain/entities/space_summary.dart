import 'package:equatable/equatable.dart';

class SpaceSummary extends Equatable {
  final String id;
  final String name;
  final String storeId;
  final String currentMood;
  final bool isOnline;
  final int customerCount;
  final double temperature;
  final double humidity;
  final int lightLevel;
  final bool isMusicPlaying;
  final String? currentTrack;

  /// Total number of zones in this space
  final int totalZones;

  /// Number of active zones
  final int activeZones;

  /// Whether this space has multi-zone music capability
  final bool hasMultiZoneMusic;

  const SpaceSummary({
    required this.id,
    required this.name,
    required this.storeId,
    required this.currentMood,
    required this.isOnline,
    required this.customerCount,
    required this.temperature,
    required this.humidity,
    required this.lightLevel,
    required this.isMusicPlaying,
    this.currentTrack,
    this.totalZones = 1, // Default to 1 zone for backward compatibility
    this.activeZones = 1,
    this.hasMultiZoneMusic = false,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        storeId,
        currentMood,
        isOnline,
        customerCount,
        temperature,
        humidity,
        lightLevel,
        isMusicPlaying,
        currentTrack,
        totalZones,
        activeZones,
        hasMultiZoneMusic,
      ];
}
