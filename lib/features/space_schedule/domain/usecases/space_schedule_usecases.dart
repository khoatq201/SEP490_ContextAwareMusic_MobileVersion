import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/schedule_source.dart';
import '../entities/space_schedule.dart';
import '../entities/space_schedule_bootstrap.dart';
import '../repositories/space_schedule_repository.dart';

class GetSpaceScheduleBootstrap {
  final SpaceScheduleRepository repository;

  GetSpaceScheduleBootstrap(this.repository);

  Future<Either<Failure, SpaceScheduleBootstrap>> call({
    required String spaceId,
    required String spaceName,
  }) {
    return repository.getBootstrap(spaceId: spaceId, spaceName: spaceName);
  }
}

class ApplyScheduleSource {
  final SpaceScheduleRepository repository;

  ApplyScheduleSource(this.repository);

  Future<Either<Failure, SpaceSchedule>> call({
    required String spaceId,
    required String spaceName,
    required ScheduleSource source,
  }) {
    return repository.applyScheduleSource(
      spaceId: spaceId,
      spaceName: spaceName,
      source: source,
    );
  }
}

class SaveSpaceSchedule {
  final SpaceScheduleRepository repository;

  SaveSpaceSchedule(this.repository);

  Future<Either<Failure, SpaceSchedule>> call(SpaceSchedule schedule) {
    return repository.saveSpaceSchedule(schedule);
  }
}

class SaveScheduleToLibrary {
  final SpaceScheduleRepository repository;

  SaveScheduleToLibrary(this.repository);

  Future<Either<Failure, ScheduleSource>> call({
    required SpaceSchedule schedule,
    required String title,
    String? subtitle,
  }) {
    return repository.saveScheduleToLibrary(
      schedule: schedule,
      title: title,
      subtitle: subtitle,
    );
  }
}

class DeleteScheduleSlot {
  final SpaceScheduleRepository repository;

  DeleteScheduleSlot(this.repository);

  Future<Either<Failure, SpaceSchedule>> call({
    required String spaceId,
    required String slotId,
  }) {
    return repository.deleteScheduleSlot(spaceId: spaceId, slotId: slotId);
  }
}
