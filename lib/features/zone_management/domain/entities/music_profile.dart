import 'package:equatable/equatable.dart';

/// Music configuration for a specific zone
/// Controls what music plays, when, and how
class MusicProfile extends Equatable {
  final String id;
  final String name;
  final String zoneId;

  /// List of playlist IDs available for this zone
  final List<String> playlistIds;

  /// Maps mood states to specific playlist IDs
  /// e.g., {"energetic": "playlist-upbeat-001", "calm": "playlist-ambient-002"}
  final Map<String, String> moodToPlaylistMap;

  /// Volume settings for this zone (0-100)
  final VolumeSettings volumeSettings;

  /// Optional schedule configuration for time-based playlist switching
  final ScheduleConfig? scheduleConfig;

  /// Whether to automatically detect and respond to mood changes
  final bool autoMoodDetection;

  /// Fallback playlist ID for offline mode
  final String offlineFallbackPlaylistId;

  /// Whether this profile is currently active
  final bool isActive;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const MusicProfile({
    required this.id,
    required this.name,
    required this.zoneId,
    required this.playlistIds,
    required this.moodToPlaylistMap,
    required this.volumeSettings,
    this.scheduleConfig,
    required this.autoMoodDetection,
    required this.offlineFallbackPlaylistId,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        zoneId,
        playlistIds,
        moodToPlaylistMap,
        volumeSettings,
        scheduleConfig,
        autoMoodDetection,
        offlineFallbackPlaylistId,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Volume configuration for a zone
class VolumeSettings extends Equatable {
  /// Default volume level (0-100)
  final int defaultVolume;

  /// Minimum allowed volume (0-100)
  final int minVolume;

  /// Maximum allowed volume (0-100)
  final int maxVolume;

  /// Whether to automatically adjust volume based on noise level
  final bool autoAdjust;

  const VolumeSettings({
    required this.defaultVolume,
    required this.minVolume,
    required this.maxVolume,
    required this.autoAdjust,
  });

  @override
  List<Object?> get props => [defaultVolume, minVolume, maxVolume, autoAdjust];
}

/// Time-based schedule for playlist switching
class ScheduleConfig extends Equatable {
  /// List of scheduled time slots
  final List<TimeSlot> timeSlots;

  /// Whether schedule is enabled
  final bool enabled;

  const ScheduleConfig({
    required this.timeSlots,
    required this.enabled,
  });

  @override
  List<Object?> get props => [timeSlots, enabled];
}

/// A single time slot in the schedule
class TimeSlot extends Equatable {
  /// Start time (HH:mm format)
  final String startTime;

  /// End time (HH:mm format)
  final String endTime;

  /// Playlist ID to play during this time slot
  final String playlistId;

  /// Optional mood override for this time slot
  final String? moodOverride;

  /// Days of week this slot applies (1=Monday, 7=Sunday)
  /// Empty list = all days
  final List<int> daysOfWeek;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.playlistId,
    this.moodOverride,
    required this.daysOfWeek,
  });

  @override
  List<Object?> get props =>
      [startTime, endTime, playlistId, moodOverride, daysOfWeek];
}
