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
    return SpaceScheduleModel(
      id: json['id'] as String,
      name: json['name'] as String,
      spaceId: json['spaceId'] as String?,
      slots: (json['slots'] as List<dynamic>)
          .map((slot) =>
              ScheduleSlotModel.fromJson(slot as Map<String, dynamic>))
          .toList(),
      enabled: json['enabled'] as bool? ?? true,
      sourceId: json['sourceId'] as String?,
      sourceLabel: json['sourceLabel'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
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
