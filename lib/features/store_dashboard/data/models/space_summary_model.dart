import '../../domain/entities/space_summary.dart';

class SpaceSummaryModel {
  final String id;
  final String name;
  final String storeId;
  final String currentMood;
  final bool isOnline;
  final int? customerCount;
  final double? noiseLevel;
  final double temperature;
  final double humidity;
  final int lightLevel;
  final bool isMusicPlaying;
  final String? currentTrack;
  final bool isManualOverride;
  final bool isScheduling;
  final int? manualOverrideRemainingSeconds;
  final int? schedulingRemainingSeconds;
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
    this.noiseLevel,
    required this.temperature,
    required this.humidity,
    required this.lightLevel,
    required this.isMusicPlaying,
    this.currentTrack,
    this.isManualOverride = false,
    this.isScheduling = false,
    this.manualOverrideRemainingSeconds,
    this.schedulingRemainingSeconds,
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
      customerCount: _readInt(json, const [
        'customerCount',
        'crowdDensity',
        'avgCrowdDensity',
        'peopleCount',
        'occupancy',
      ]),
      noiseLevel: _readDouble(json, const [
        'avgNoise',
        'noiseLevel',
        'noise',
        'decibel',
        'decibelLevel',
      ]),
      temperature:
          _readDouble(json, const ['temperature', 'avgTemperature']) ?? 0.0,
      humidity: _readDouble(json, const ['humidity', 'avgHumidity']) ?? 0.0,
      lightLevel: json['lightLevel'] as int? ?? 0,
      isMusicPlaying: json['isMusicPlaying'] as bool? ?? false,
      currentTrack: json['currentTrack'] as String?,
      isManualOverride: json['isManualOverride'] as bool? ?? false,
      isScheduling: json['isScheduling'] as bool? ?? false,
      manualOverrideRemainingSeconds:
          (json['manualOverrideRemainingSeconds'] as num?)?.toInt(),
      schedulingRemainingSeconds:
          (json['schedulingRemainingSeconds'] as num?)?.toInt(),
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
      noiseLevel: noiseLevel,
      temperature: temperature,
      humidity: humidity,
      lightLevel: lightLevel,
      isMusicPlaying: isMusicPlaying,
      currentTrack: currentTrack,
      isManualOverride: isManualOverride,
      isScheduling: isScheduling,
      manualOverrideRemainingSeconds: manualOverrideRemainingSeconds,
      schedulingRemainingSeconds: schedulingRemainingSeconds,
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
    double? noiseLevel,
    double? temperature,
    double? humidity,
    int? lightLevel,
    bool? isMusicPlaying,
    String? currentTrack,
    bool? isManualOverride,
    bool? isScheduling,
    int? manualOverrideRemainingSeconds,
    int? schedulingRemainingSeconds,
    int? totalZones,
    int? activeZones,
    bool? hasMultiZoneMusic,
    bool clearCurrentTrack = false,
  }) {
    return SpaceSummaryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      storeId: storeId ?? this.storeId,
      currentMood: currentMood ?? this.currentMood,
      isOnline: isOnline ?? this.isOnline,
      customerCount: customerCount ?? this.customerCount,
      noiseLevel: noiseLevel ?? this.noiseLevel,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      lightLevel: lightLevel ?? this.lightLevel,
      isMusicPlaying: isMusicPlaying ?? this.isMusicPlaying,
      currentTrack:
          clearCurrentTrack ? null : (currentTrack ?? this.currentTrack),
      isManualOverride: isManualOverride ?? this.isManualOverride,
      isScheduling: isScheduling ?? this.isScheduling,
      manualOverrideRemainingSeconds:
          manualOverrideRemainingSeconds ?? this.manualOverrideRemainingSeconds,
      schedulingRemainingSeconds:
          schedulingRemainingSeconds ?? this.schedulingRemainingSeconds,
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
      'noiseLevel': noiseLevel,
      'temperature': temperature,
      'humidity': humidity,
      'lightLevel': lightLevel,
      'isMusicPlaying': isMusicPlaying,
      'currentTrack': currentTrack,
      'isManualOverride': isManualOverride,
      'isScheduling': isScheduling,
      'manualOverrideRemainingSeconds': manualOverrideRemainingSeconds,
      'schedulingRemainingSeconds': schedulingRemainingSeconds,
      'totalZones': totalZones,
      'activeZones': activeZones,
      'hasMultiZoneMusic': hasMultiZoneMusic,
    };
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    final value = _readNum(json, keys);
    return value?.round();
  }

  static double? _readDouble(Map<String, dynamic> json, List<String> keys) {
    return _readNum(json, keys)?.toDouble();
  }

  static num? _readNum(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = _readValue(json, key);
      if (value is num) return value;
      if (value is String) {
        final parsed = num.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static dynamic _readValue(Map<String, dynamic> json, String key) {
    if (json.containsKey(key)) return json[key];
    if (key.isEmpty) return null;
    final pascalCaseKey = '${key[0].toUpperCase()}${key.substring(1)}';
    return json[pascalCaseKey];
  }
}
