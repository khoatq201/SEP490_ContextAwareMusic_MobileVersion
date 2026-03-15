import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/schedule_source.dart';
import '../entities/space_schedule.dart';
import '../entities/space_schedule_bootstrap.dart';

abstract class SpaceScheduleRepository {
  Future<Either<Failure, SpaceScheduleBootstrap>> getBootstrap({
    required String spaceId,
    required String spaceName,
  });

  Future<Either<Failure, SpaceSchedule>> applyScheduleSource({
    required String spaceId,
    required String spaceName,
    required ScheduleSource source,
  });

  Future<Either<Failure, SpaceSchedule>> saveSpaceSchedule(
      SpaceSchedule schedule);

  Future<Either<Failure, ScheduleSource>> saveScheduleToLibrary({
    required SpaceSchedule schedule,
    required String title,
    String? subtitle,
  });

  Future<Either<Failure, SpaceSchedule>> deleteScheduleSlot({
    required String spaceId,
    required String slotId,
  });
}
