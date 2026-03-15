import '../../domain/entities/schedule_source.dart';
import 'space_schedule_model.dart';

class ScheduleSourceModel extends ScheduleSource {
  const ScheduleSourceModel({
    required super.id,
    required super.title,
    required super.subtitle,
    super.description,
    required super.type,
    required super.schedule,
    super.isUserCreated,
  });

  factory ScheduleSourceModel.fromJson(Map<String, dynamic> json) {
    return ScheduleSourceModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      description: json['description'] as String?,
      type: ScheduleSourceType.values.byName(json['type'] as String),
      schedule:
          SpaceScheduleModel.fromJson(json['schedule'] as Map<String, dynamic>),
      isUserCreated: json['isUserCreated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'type': type.name,
      'schedule': SpaceScheduleModel(
        id: schedule.id,
        name: schedule.name,
        spaceId: schedule.spaceId,
        slots: schedule.slots,
        enabled: schedule.enabled,
        sourceId: schedule.sourceId,
        sourceLabel: schedule.sourceLabel,
        updatedAt: schedule.updatedAt,
      ).toJson(),
      'isUserCreated': isUserCreated,
    };
  }
}
