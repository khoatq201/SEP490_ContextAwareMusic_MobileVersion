import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/schedule_source.dart';
import '../../domain/entities/space_schedule.dart';
import '../../domain/entities/space_schedule_bootstrap.dart';
import '../../domain/repositories/space_schedule_repository.dart';
import '../datasources/space_schedule_local_datasource.dart';
import '../datasources/space_schedule_mock_datasource.dart';
import '../models/schedule_source_model.dart';
import '../models/space_schedule_model.dart';

class SpaceScheduleRepositoryImpl implements SpaceScheduleRepository {
  final SpaceScheduleMockDataSource mockDataSource;
  final SpaceScheduleLocalDataSource localDataSource;

  SpaceScheduleRepositoryImpl({
    required this.mockDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, SpaceScheduleBootstrap>> getBootstrap({
    required String spaceId,
    required String spaceName,
  }) async {
    try {
      final draft = localDataSource.getDraftSchedule(spaceId);
      final templates = await mockDataSource.getTemplateSources();
      final seedLibrary = await mockDataSource.getSeedLibrarySources();
      final localLibrary = localDataSource.getLibrarySources();
      final catalog = await mockDataSource.getMusicCatalog();

      return Right(
        SpaceScheduleBootstrap(
          draftSchedule: draft,
          librarySources: [...localLibrary, ...seedLibrary],
          templateSources: templates,
          musicCatalog: catalog,
        ),
      );
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Failed to bootstrap schedule: $error'));
    }
  }

  @override
  Future<Either<Failure, SpaceSchedule>> applyScheduleSource({
    required String spaceId,
    required String spaceName,
    required ScheduleSource source,
  }) async {
    try {
      final applied = _cloneToSpaceSchedule(
        schedule: source.schedule,
        spaceId: spaceId,
        fallbackName: source.title,
        sourceId: source.id,
        sourceLabel: source.title,
      );
      await localDataSource.saveDraftSchedule(_toScheduleModel(applied));
      return Right(applied);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Failed to apply schedule source: $error'));
    }
  }

  @override
  Future<Either<Failure, SpaceSchedule>> saveSpaceSchedule(
      SpaceSchedule schedule) async {
    try {
      final normalized = schedule.copyWith(updatedAt: DateTime.now());
      await localDataSource.saveDraftSchedule(_toScheduleModel(normalized));
      return Right(normalized);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Failed to save schedule: $error'));
    }
  }

  @override
  Future<Either<Failure, ScheduleSource>> saveScheduleToLibrary({
    required SpaceSchedule schedule,
    required String title,
    String? subtitle,
  }) async {
    try {
      final existing = localDataSource.getLibrarySources();
      final source = ScheduleSourceModel(
        id: 'library-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        subtitle: subtitle?.trim().isNotEmpty == true
            ? subtitle!.trim()
            : 'Saved from ${schedule.spaceId ?? 'space draft'}',
        description: 'User-saved schedule',
        type: ScheduleSourceType.library,
        schedule: _toScheduleModel(
          schedule.copyWith(
            name: title,
            updatedAt: DateTime.now(),
          ),
        ),
        isUserCreated: true,
      );
      await localDataSource.saveLibrarySources([source, ...existing]);
      return Right(source);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Failed to save schedule to library: $error'));
    }
  }

  @override
  Future<Either<Failure, SpaceSchedule>> deleteScheduleSlot({
    required String spaceId,
    required String slotId,
  }) async {
    try {
      final draft = localDataSource.getDraftSchedule(spaceId);
      if (draft == null) {
        return const Left(CacheFailure('No schedule draft found'));
      }
      final updated = draft.copyWith(
        slots: draft.slots.where((slot) => slot.id != slotId).toList(),
        updatedAt: DateTime.now(),
      );
      await localDataSource.saveDraftSchedule(_toScheduleModel(updated));
      return Right(updated);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Failed to delete slot: $error'));
    }
  }

  SpaceSchedule _cloneToSpaceSchedule({
    required SpaceSchedule schedule,
    required String spaceId,
    required String fallbackName,
    required String sourceId,
    required String sourceLabel,
  }) {
    final now = DateTime.now();
    return SpaceSchedule(
      id: 'space-schedule-$spaceId',
      name: schedule.name.isNotEmpty ? schedule.name : fallbackName,
      spaceId: spaceId,
      slots: schedule.slots
          .map(
            (slot) => slot.copyWith(
              id: 'slot-${slot.id}-$spaceId',
              daysOfWeek: List<int>.from(slot.daysOfWeek),
            ),
          )
          .toList(),
      enabled: schedule.enabled,
      sourceId: sourceId,
      sourceLabel: sourceLabel,
      updatedAt: now,
    );
  }

  SpaceScheduleModel _toScheduleModel(SpaceSchedule schedule) {
    return SpaceScheduleModel(
      id: schedule.id,
      name: schedule.name,
      spaceId: schedule.spaceId,
      slots: schedule.slots,
      enabled: schedule.enabled,
      sourceId: schedule.sourceId,
      sourceLabel: schedule.sourceLabel,
      updatedAt: schedule.updatedAt,
    );
  }
}
