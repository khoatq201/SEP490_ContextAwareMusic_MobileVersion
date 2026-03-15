import 'package:equatable/equatable.dart';

import 'schedule_slot.dart';

class SpaceSchedule extends Equatable {
  final String id;
  final String name;
  final String? spaceId;
  final List<ScheduleSlot> slots;
  final bool enabled;
  final String? sourceId;
  final String? sourceLabel;
  final DateTime updatedAt;

  const SpaceSchedule({
    required this.id,
    required this.name,
    required this.spaceId,
    required this.slots,
    required this.enabled,
    this.sourceId,
    this.sourceLabel,
    required this.updatedAt,
  });

  SpaceSchedule copyWith({
    String? id,
    String? name,
    String? spaceId,
    List<ScheduleSlot>? slots,
    bool? enabled,
    String? sourceId,
    String? sourceLabel,
    DateTime? updatedAt,
  }) {
    return SpaceSchedule(
      id: id ?? this.id,
      name: name ?? this.name,
      spaceId: spaceId ?? this.spaceId,
      slots: slots ?? this.slots,
      enabled: enabled ?? this.enabled,
      sourceId: sourceId ?? this.sourceId,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        spaceId,
        slots,
        enabled,
        sourceId,
        sourceLabel,
        updatedAt,
      ];
}
