import '../../domain/entities/music_profile.dart';

class MusicProfileModel extends MusicProfile {
  const MusicProfileModel({
    required super.id,
    required super.name,
    required super.zoneId,
    required super.playlistIds,
    required super.moodToPlaylistMap,
    required super.volumeSettings,
    super.scheduleConfig,
    required super.autoMoodDetection,
    required super.offlineFallbackPlaylistId,
    required super.isActive,
    required super.createdAt,
    super.updatedAt,
  });

  factory MusicProfileModel.fromJson(Map<String, dynamic> json) {
    return MusicProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      zoneId: json['zoneId'] as String,
      playlistIds: (json['playlistIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      moodToPlaylistMap: Map<String, String>.from(
          json['moodToPlaylistMap'] as Map<String, dynamic>),
      volumeSettings: VolumeSettingsModel.fromJson(
          json['volumeSettings'] as Map<String, dynamic>),
      scheduleConfig: json['scheduleConfig'] != null
          ? ScheduleConfigModel.fromJson(
              json['scheduleConfig'] as Map<String, dynamic>)
          : null,
      autoMoodDetection: json['autoMoodDetection'] as bool,
      offlineFallbackPlaylistId: json['offlineFallbackPlaylistId'] as String,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'zoneId': zoneId,
      'playlistIds': playlistIds,
      'moodToPlaylistMap': moodToPlaylistMap,
      'volumeSettings': (volumeSettings as VolumeSettingsModel).toJson(),
      'scheduleConfig': scheduleConfig != null
          ? (scheduleConfig as ScheduleConfigModel).toJson()
          : null,
      'autoMoodDetection': autoMoodDetection,
      'offlineFallbackPlaylistId': offlineFallbackPlaylistId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class VolumeSettingsModel extends VolumeSettings {
  const VolumeSettingsModel({
    required super.defaultVolume,
    required super.minVolume,
    required super.maxVolume,
    required super.autoAdjust,
  });

  factory VolumeSettingsModel.fromJson(Map<String, dynamic> json) {
    return VolumeSettingsModel(
      defaultVolume: json['defaultVolume'] as int,
      minVolume: json['minVolume'] as int,
      maxVolume: json['maxVolume'] as int,
      autoAdjust: json['autoAdjust'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultVolume': defaultVolume,
      'minVolume': minVolume,
      'maxVolume': maxVolume,
      'autoAdjust': autoAdjust,
    };
  }
}

class ScheduleConfigModel extends ScheduleConfig {
  const ScheduleConfigModel({
    required super.timeSlots,
    required super.enabled,
  });

  factory ScheduleConfigModel.fromJson(Map<String, dynamic> json) {
    return ScheduleConfigModel(
      timeSlots: (json['timeSlots'] as List<dynamic>)
          .map((e) => TimeSlotModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      enabled: json['enabled'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeSlots': timeSlots.map((e) => (e as TimeSlotModel).toJson()).toList(),
      'enabled': enabled,
    };
  }
}

class TimeSlotModel extends TimeSlot {
  const TimeSlotModel({
    required super.startTime,
    required super.endTime,
    required super.playlistId,
    super.moodOverride,
    required super.daysOfWeek,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      playlistId: json['playlistId'] as String,
      moodOverride: json['moodOverride'] as String?,
      daysOfWeek:
          (json['daysOfWeek'] as List<dynamic>).map((e) => e as int).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'playlistId': playlistId,
      'moodOverride': moodOverride,
      'daysOfWeek': daysOfWeek,
    };
  }
}
