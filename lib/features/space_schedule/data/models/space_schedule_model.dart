import '../../domain/entities/space_schedule.dart';
import 'schedule_slot_model.dart';

class SpaceScheduleModel extends SpaceSchedule {
  const SpaceScheduleModel({
    required super.id,
    required super.name,
    required super.spaceId,
    required super.slots,
    required super.enabled,
    super.sourceId,
    super.sourceLabel,
    required super.updatedAt,
  });

  factory SpaceScheduleModel.fromJson(Map<String, dynamic> json) {
    final updatedAtRaw = json['updatedAt']?.toString();
    return SpaceScheduleModel(
      id: json['id']?.toString() ??
          'space-schedule-${json['spaceId']?.toString() ?? 'unknown'}',
      name: json['name']?.toString() ??
          json['sourceLabel']?.toString() ??
          'Space schedule',
      spaceId: json['spaceId']?.toString(),
      slots: (json['slots'] as List<dynamic>? ?? const [])
          .map((slot) =>
              ScheduleSlotModel.fromJson(slot as Map<String, dynamic>))
          .toList(),
      enabled: json['enabled'] as bool? ?? true,
      sourceId: json['sourceId']?.toString(),
      sourceLabel: json['sourceLabel']?.toString(),
      updatedAt: updatedAtRaw == null
          ? DateTime.now()
          : DateTime.tryParse(updatedAtRaw) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'spaceId': spaceId,
      'slots': slots
          .map((slot) => ScheduleSlotModel(
                id: slot.id,
                daysOfWeek: slot.daysOfWeek,
                startTime: slot.startTime,
                endTime: slot.endTime,
                musicId: slot.musicId,
              ).toJson())
          .toList(),
      'enabled': enabled,
      'sourceId': sourceId,
      'sourceLabel': sourceLabel,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
