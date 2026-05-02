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
    final type = _parseSourceType(json);
    final rawSchedule = json['schedule'];
    final schedule = rawSchedule is Map
        ? SpaceScheduleModel.fromJson(Map<String, dynamic>.from(rawSchedule))
        : SpaceScheduleModel(
            id: json['id']?.toString() ?? '',
            name: json['title']?.toString() ?? 'Schedule source',
            spaceId: null,
            slots: const [],
            enabled: true,
            updatedAt: DateTime.now(),
          );
    return ScheduleSourceModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Schedule source',
      subtitle: json['subtitle']?.toString() ?? '',
      description: json['description']?.toString(),
      type: type,
      schedule: schedule,
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

  static ScheduleSourceType _parseSourceType(Map<String, dynamic> json) {
    final raw = json['type']?.toString().trim().toLowerCase();
    if (raw == 'template' || json['isTemplate'] == true) {
      return ScheduleSourceType.template;
    }
    return ScheduleSourceType.library;
  }
}
