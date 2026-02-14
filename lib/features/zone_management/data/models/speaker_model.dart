import '../../domain/entities/speaker.dart';

class SpeakerModel extends Speaker {
  const SpeakerModel({
    required super.id,
    required super.name,
    required super.zoneId,
    required super.hubId,
    required super.ipAddress,
    required super.isOnline,
    required super.currentVolume,
    required super.capabilities,
    super.lastSeenAt,
    super.firmwareVersion,
  });

  factory SpeakerModel.fromJson(Map<String, dynamic> json) {
    return SpeakerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      zoneId: json['zoneId'] as String,
      hubId: json['hubId'] as String,
      ipAddress: json['ipAddress'] as String,
      isOnline: json['isOnline'] as bool,
      currentVolume: json['currentVolume'] as int,
      capabilities: SpeakerCapabilitiesModel.fromJson(
          json['capabilities'] as Map<String, dynamic>),
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.parse(json['lastSeenAt'] as String)
          : null,
      firmwareVersion: json['firmwareVersion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'zoneId': zoneId,
      'hubId': hubId,
      'ipAddress': ipAddress,
      'isOnline': isOnline,
      'currentVolume': currentVolume,
      'capabilities': (capabilities as SpeakerCapabilitiesModel).toJson(),
      'lastSeenAt': lastSeenAt?.toIso8601String(),
      'firmwareVersion': firmwareVersion,
    };
  }

  factory SpeakerModel.fromEntity(Speaker speaker) {
    return SpeakerModel(
      id: speaker.id,
      name: speaker.name,
      zoneId: speaker.zoneId,
      hubId: speaker.hubId,
      ipAddress: speaker.ipAddress,
      isOnline: speaker.isOnline,
      currentVolume: speaker.currentVolume,
      capabilities: speaker.capabilities,
      lastSeenAt: speaker.lastSeenAt,
      firmwareVersion: speaker.firmwareVersion,
    );
  }
}

class SpeakerCapabilitiesModel extends SpeakerCapabilities {
  const SpeakerCapabilitiesModel({
    required super.maxPowerWatts,
    required super.supportedFormats,
    required super.supportsStereo,
    required super.frequencyRange,
  });

  factory SpeakerCapabilitiesModel.fromJson(Map<String, dynamic> json) {
    return SpeakerCapabilitiesModel(
      maxPowerWatts: json['maxPowerWatts'] as int,
      supportedFormats: (json['supportedFormats'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      supportsStereo: json['supportsStereo'] as bool,
      frequencyRange: json['frequencyRange'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxPowerWatts': maxPowerWatts,
      'supportedFormats': supportedFormats,
      'supportsStereo': supportsStereo,
      'frequencyRange': frequencyRange,
    };
  }
}
