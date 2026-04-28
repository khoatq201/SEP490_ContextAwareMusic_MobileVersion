import 'package:equatable/equatable.dart';

import 'schedule_music_item.dart';
import 'schedule_source.dart';
import 'space_schedule.dart';

class SpaceScheduleBootstrap extends Equatable {
  final SpaceSchedule? draftSchedule;
  final List<ScheduleSource> librarySources;
  final List<ScheduleTemplate> templateSources;
  final List<ScheduleMusicItem> musicCatalog;

  const SpaceScheduleBootstrap({
    required this.draftSchedule,
    required this.librarySources,
    required this.templateSources,
    required this.musicCatalog,
  });

  @override
  List<Object?> get props => [
        draftSchedule,
        librarySources,
        templateSources,
        musicCatalog,
      ];
}
