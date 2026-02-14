import 'package:equatable/equatable.dart';

/// Represents a physical speaker device in a zone
/// Each speaker belongs to exactly one zone (1:1 relationship)
class Speaker extends Equatable {
  final String id;
  final String name;

  /// The zone this speaker belongs to
  final String zoneId;

  /// The hub this speaker is connected to
  final String hubId;

  /// IP address for network communication
  final String ipAddress;

  /// Whether the speaker is currently online and reachable
  final bool isOnline;

  /// Current volume level (0-100)
  final int currentVolume;

  /// Speaker capabilities and specifications
  final SpeakerCapabilities capabilities;

  /// Last time the speaker was seen online
  final DateTime? lastSeenAt;

  /// Firmware version
  final String? firmwareVersion;

  const Speaker({
    required this.id,
    required this.name,
    required this.zoneId,
    required this.hubId,
    required this.ipAddress,
    required this.isOnline,
    required this.currentVolume,
    required this.capabilities,
    this.lastSeenAt,
    this.firmwareVersion,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        zoneId,
        hubId,
        ipAddress,
        isOnline,
        currentVolume,
        capabilities,
        lastSeenAt,
        firmwareVersion,
      ];
}

/// Speaker technical capabilities
class SpeakerCapabilities extends Equatable {
  /// Maximum power output in watts
  final int maxPowerWatts;

  /// Supported audio formats (e.g., ["mp3", "aac", "wav"])
  final List<String> supportedFormats;

  /// Whether speaker supports stereo output
  final bool supportsStereo;

  /// Frequency response range (e.g., "20Hz-20kHz")
  final String frequencyRange;

  const SpeakerCapabilities({
    required this.maxPowerWatts,
    required this.supportedFormats,
    required this.supportsStereo,
    required this.frequencyRange,
  });

  @override
  List<Object?> get props =>
      [maxPowerWatts, supportedFormats, supportsStereo, frequencyRange];
}
