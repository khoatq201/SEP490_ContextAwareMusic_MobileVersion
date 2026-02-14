import '../../domain/entities/space_summary.dart';

class SpaceSummaryModel {
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
  final int totalZones;
  final int activeZones;
  final bool hasMultiZoneMusic;

  SpaceSummaryModel({
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
    this.totalZones = 1,
    this.activeZones = 1,
    this.hasMultiZoneMusic = false,
  });

  factory SpaceSummaryModel.fromJson(Map<String, dynamic> json) {
    return SpaceSummaryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      storeId: json['storeId'] as String,
      currentMood: json['currentMood'] as String? ?? 'neutral',
      isOnline: json['isOnline'] as bool? ?? false,
      customerCount: json['customerCount'] as int? ?? 0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      lightLevel: json['lightLevel'] as int? ?? 0,
      isMusicPlaying: json['isMusicPlaying'] as bool? ?? false,
      currentTrack: json['currentTrack'] as String?,
      totalZones: json['totalZones'] as int? ?? 1,
      activeZones: json['activeZones'] as int? ?? 1,
      hasMultiZoneMusic: json['hasMultiZoneMusic'] as bool? ?? false,
    );
  }

  SpaceSummary toEntity() {
    return SpaceSummary(
      id: id,
      name: name,
      storeId: storeId,
      currentMood: currentMood,
      isOnline: isOnline,
      customerCount: customerCount,
      temperature: temperature,
      humidity: humidity,
      lightLevel: lightLevel,
      isMusicPlaying: isMusicPlaying,
      currentTrack: currentTrack,
      totalZones: totalZones,
      activeZones: activeZones,
      hasMultiZoneMusic: hasMultiZoneMusic,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'storeId': storeId,
      'currentMood': currentMood,
      'isOnline': isOnline,
      'customerCount': customerCount,
      'temperature': temperature,
      'humidity': humidity,
      'lightLevel': lightLevel,
      'isMusicPlaying': isMusicPlaying,
      'currentTrack': currentTrack,
      'totalZones': totalZones,
      'activeZones': activeZones,
      'hasMultiZoneMusic': hasMultiZoneMusic,
    };
  }
}
