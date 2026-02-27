import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// A dashboard-level sensor reading displayed on the Home tab.
/// This is distinct from [SensorData] used in SpaceDetailPage — that one
/// carries raw float values for a single space. [SensorEntity] is richer:
/// it carries a human-readable [value] string and an icon for UI rendering.
class SensorEntity extends Equatable {
  final String id;

  /// Human-readable label, e.g. "Nhiệt độ", "Độ ẩm", "Lượng khách"
  final String name;

  /// Pre-formatted display value, e.g. "32°C", "65%", "Medium"
  final String value;

  /// Material icon for the sensor card
  final IconData icon;

  /// Optional accent color for the card gradient
  final Color? accentColor;

  /// Optional sub-label / status badge text, e.g. "Stable", "Loud"
  final String? badge;

  const SensorEntity({
    required this.id,
    required this.name,
    required this.value,
    required this.icon,
    this.accentColor,
    this.badge,
  });

  @override
  List<Object?> get props => [id, name, value, icon, accentColor, badge];
}
