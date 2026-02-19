import 'package:equatable/equatable.dart';
import 'hub_sensor_entity.dart';

/// Represents a physical ESP32 Hub device bound to a Space.
class HubEntity extends Equatable {
  final String id;

  /// MAC address, e.g. "AA:BB:CC:DD:EE:01"
  final String macAddress;

  /// Whether the hub is currently reachable over the network.
  final bool isOnline;

  /// Human-readable Wi-Fi signal quality: "Mạnh" | "Trung bình" | "Yếu"
  final String wifiSignalStrength;

  /// Name of the Bluetooth speaker currently paired with the hub.
  final String connectedSpeakerName;

  /// Current playback volume (0–100).
  final int currentVolume;

  /// Physical sensors attached to this hub.
  final List<HubSensorEntity> sensors;

  const HubEntity({
    required this.id,
    required this.macAddress,
    required this.isOnline,
    required this.wifiSignalStrength,
    required this.connectedSpeakerName,
    required this.currentVolume,
    this.sensors = const [],
  });

  HubEntity copyWith({
    String? id,
    String? macAddress,
    bool? isOnline,
    String? wifiSignalStrength,
    String? connectedSpeakerName,
    int? currentVolume,
    List<HubSensorEntity>? sensors,
  }) {
    return HubEntity(
      id: id ?? this.id,
      macAddress: macAddress ?? this.macAddress,
      isOnline: isOnline ?? this.isOnline,
      wifiSignalStrength: wifiSignalStrength ?? this.wifiSignalStrength,
      connectedSpeakerName: connectedSpeakerName ?? this.connectedSpeakerName,
      currentVolume: currentVolume ?? this.currentVolume,
      sensors: sensors ?? this.sensors,
    );
  }

  @override
  List<Object?> get props => [
        id,
        macAddress,
        isOnline,
        wifiSignalStrength,
        connectedSpeakerName,
        currentVolume,
        sensors,
      ];
}
