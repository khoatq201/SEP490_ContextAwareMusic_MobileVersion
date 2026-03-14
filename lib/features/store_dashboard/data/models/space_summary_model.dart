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
    // Derive isOnline from API status field (1 = Active = online)
    final status = json['status'];
    final derivedIsOnline =
        json['isOnline'] as bool? ?? (status is int ? status == 1 : false);

    return SpaceSummaryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      storeId: json['storeId'] as String? ?? '',
      currentMood: json['currentMood'] as String? ?? 'neutral',
      isOnline: derivedIsOnline,
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

  SpaceSummaryModel copyWith({
    String? id,
    String? name,
    String? storeId,
    String? currentMood,
    bool? isOnline,
    int? customerCount,
    double? temperature,
    double? humidity,
    int? lightLevel,
    bool? isMusicPlaying,
    String? currentTrack,
    int? totalZones,
    int? activeZones,
    bool? hasMultiZoneMusic,
  }) {
    return SpaceSummaryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      storeId: storeId ?? this.storeId,
      currentMood: currentMood ?? this.currentMood,
      isOnline: isOnline ?? this.isOnline,
      customerCount: customerCount ?? this.customerCount,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      lightLevel: lightLevel ?? this.lightLevel,
      isMusicPlaying: isMusicPlaying ?? this.isMusicPlaying,
      currentTrack: currentTrack ?? this.currentTrack,
      totalZones: totalZones ?? this.totalZones,
      activeZones: activeZones ?? this.activeZones,
      hasMultiZoneMusic: hasMultiZoneMusic ?? this.hasMultiZoneMusic,
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
