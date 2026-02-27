import 'package:equatable/equatable.dart';

/// Represents a physical sensor attached to a Hub device.
class HubSensorEntity extends Equatable {
  final String id;

  /// Display name, e.g. "Nhiệt độ", "Lượng khách"
  final String name;

  /// Machine-readable type: "temperature" | "crowd" | "humidity" | "noise"
  final String type;

  /// Unit suffix, e.g. "°C", " người", "%", " dB"
  final String unit;

  /// Current reading; null when the hub is offline or sensor is unavailable.
  final double? currentValue;

  const HubSensorEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.unit,
    this.currentValue,
  });

  /// Returns "24.5°C" when online or "--" when offline.
  String get formattedValue =>
      currentValue != null ? '${currentValue!.toStringAsFixed(1)}$unit' : '--';

  HubSensorEntity copyWith({
    String? id,
    String? name,
    String? type,
    String? unit,
    double? currentValue,
  }) {
    return HubSensorEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      unit: unit ?? this.unit,
      currentValue: currentValue ?? this.currentValue,
    );
  }

  @override
  List<Object?> get props => [id, name, type, unit, currentValue];
}
