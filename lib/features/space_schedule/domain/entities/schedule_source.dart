import 'package:equatable/equatable.dart';

import 'space_schedule.dart';

enum ScheduleSourceType { library, template }

class ScheduleSource extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String? description;
  final ScheduleSourceType type;
  final SpaceSchedule schedule;
  final bool isUserCreated;

  const ScheduleSource({
    required this.id,
    required this.title,
    required this.subtitle,
    this.description,
    required this.type,
    required this.schedule,
    this.isUserCreated = false,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        description,
        type,
        schedule,
        isUserCreated,
      ];
}

class ScheduleTemplate extends ScheduleSource {
  const ScheduleTemplate({
    required super.id,
    required super.title,
    required super.subtitle,
    super.description,
    required super.schedule,
  }) : super(type: ScheduleSourceType.template);
}
