import 'package:dartz/dartz.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/schedule_source.dart';
import '../../domain/entities/space_schedule.dart';
import '../../domain/entities/space_schedule_bootstrap.dart';
import '../../domain/repositories/space_schedule_repository.dart';
import '../datasources/space_schedule_local_datasource.dart';
import '../datasources/space_schedule_mock_datasource.dart';
import '../datasources/space_schedule_remote_datasource.dart';
import '../models/schedule_source_model.dart';
import '../models/space_schedule_model.dart';

class SpaceScheduleRepositoryImpl implements SpaceScheduleRepository {
  final SpaceScheduleMockDataSource mockDataSource;
  final SpaceScheduleLocalDataSource localDataSource;
  final SpaceScheduleRemoteDataSource? remoteDataSource;

  SpaceScheduleRepositoryImpl({
    required this.mockDataSource,
    required this.localDataSource,
    this.remoteDataSource,
  });

  @override
  Future<Either<Failure, SpaceScheduleBootstrap>> getBootstrap({
    required String spaceId,
    required String spaceName,
  }) async {
    if (remoteDataSource != null) {
      return _getRemoteBootstrap(spaceId: spaceId);
    }

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
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to load the schedule draft right now.',
        ),
      );
    } catch (error) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to load schedule data right now.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, SpaceSchedule>> applyScheduleSource({
    required String spaceId,
    required String spaceName,
    required ScheduleSource source,
  }) async {
    if (remoteDataSource != null) {
      return _applyRemoteScheduleSource(
        spaceId: spaceId,
        fallbackName: spaceName,
        source: source,
      );
    }

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
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to apply this schedule source right now.',
        ),
      );
    } catch (error) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to apply this schedule source right now.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, SpaceSchedule>> saveSpaceSchedule(
      SpaceSchedule schedule) async {
    if (remoteDataSource != null) {
      return _saveRemoteSpaceSchedule(schedule);
    }

    try {
      final normalized = schedule.copyWith(updatedAt: DateTime.now());
      await localDataSource.saveDraftSchedule(_toScheduleModel(normalized));
      return Right(normalized);
    } on CacheException catch (error) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to save the schedule right now.',
        ),
      );
    } catch (error) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to save the schedule right now.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, SpaceSchedule>> toggleSchedule({
    required String spaceId,
    required bool enabled,
  }) async {
    if (remoteDataSource != null) {
      return _toggleRemoteSchedule(spaceId: spaceId, enabled: enabled);
    }

    try {
      final draft = localDataSource.getDraftSchedule(spaceId);
      if (draft == null) {
        return const Left(CacheFailure('No schedule draft found'));
      }
      final updated = draft.copyWith(
        enabled: enabled,
        updatedAt: DateTime.now(),
      );
      await localDataSource.saveDraftSchedule(_toScheduleModel(updated));
      return Right(updated);
    } on CacheException catch (error) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to update schedule status right now.',
        ),
      );
    } catch (error) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to update schedule status right now.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ScheduleSource>> saveScheduleToLibrary({
    required SpaceSchedule schedule,
    required String title,
    String? subtitle,
  }) async {
    if (remoteDataSource != null) {
      return _saveRemoteScheduleToLibrary(
        schedule: schedule,
        title: title,
        subtitle: subtitle,
      );
    }

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
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to save this schedule to your library.',
        ),
      );
    } catch (error) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to save this schedule to your library.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, SpaceSchedule>> deleteScheduleSlot({
    required String spaceId,
    required String slotId,
  }) async {
    if (remoteDataSource != null) {
      return _deleteRemoteScheduleSlot(spaceId: spaceId, slotId: slotId);
    }

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
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to remove this schedule slot right now.',
        ),
      );
    } catch (error) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to remove this schedule slot right now.',
        ),
      );
    }
  }

  Future<Either<Failure, SpaceScheduleBootstrap>> _getRemoteBootstrap({
    required String spaceId,
  }) async {
    try {
      final bootstrap = await remoteDataSource!.getBootstrap(spaceId);
      final localDraft = localDataSource.getDraftSchedule(spaceId);
      final draft = bootstrap.draftSchedule ?? localDraft;
      if (draft != null) {
        await localDataSource.saveDraftSchedule(_toScheduleModel(draft));
      }
      return Right(
        SpaceScheduleBootstrap(
          draftSchedule: draft,
          librarySources: bootstrap.librarySources,
          templateSources: bootstrap.templateSources,
          musicCatalog: bootstrap.musicCatalog,
        ),
      );
    } on CacheException catch (error) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to cache schedule data right now.',
        ),
      );
    } catch (error) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to load schedule data right now.',
        ),
      );
    }
  }

  Future<Either<Failure, SpaceSchedule>> _applyRemoteScheduleSource({
    required String spaceId,
    required String fallbackName,
    required ScheduleSource source,
  }) async {
    try {
      await remoteDataSource!.applySource(
        spaceId: spaceId,
        sourceId: source.id,
      );
      final bootstrap = await remoteDataSource!.getBootstrap(spaceId);
      final applied = bootstrap.draftSchedule ??
          _cloneToSpaceSchedule(
            schedule: source.schedule,
            spaceId: spaceId,
            fallbackName: fallbackName,
            sourceId: source.id,
            sourceLabel: source.title,
          );
      await localDataSource.saveDraftSchedule(_toScheduleModel(applied));
      return Right(applied);
    } catch (error) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to apply this schedule source right now.',
        ),
      );
    }
  }

  Future<Either<Failure, SpaceSchedule>> _saveRemoteSpaceSchedule(
    SpaceSchedule schedule,
  ) async {
    try {
      final normalized = schedule.copyWith(updatedAt: DateTime.now());
      await localDataSource.saveDraftSchedule(_toScheduleModel(normalized));

      for (final slot in normalized.slots) {
        await remoteDataSource!.upsertSlot(
          spaceId: normalized.spaceId ?? '',
          slot: slot,
        );
      }

      if (normalized.slots.isEmpty) {
        return Right(normalized);
      }

      final bootstrap =
          await remoteDataSource!.getBootstrap(normalized.spaceId ?? '');
      final saved = bootstrap.draftSchedule ?? normalized;
      await localDataSource.saveDraftSchedule(_toScheduleModel(saved));
      return Right(saved);
    } catch (error) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to save the schedule right now.',
        ),
      );
    }
  }

  Future<Either<Failure, ScheduleSource>> _saveRemoteScheduleToLibrary({
    required SpaceSchedule schedule,
    required String title,
    String? subtitle,
  }) async {
    try {
      final sourceId = await remoteDataSource!.saveToLibrary(
        spaceId: schedule.spaceId ?? '',
        title: title,
        subtitle: subtitle,
      );
      final bootstrap =
          await remoteDataSource!.getBootstrap(schedule.spaceId ?? '');
      final source = _findSavedLibrarySource(
            bootstrap.librarySources,
            sourceId: sourceId,
            title: title,
          ) ??
          _buildLibrarySourceFallback(
            schedule: schedule,
            title: title,
            subtitle: subtitle,
          );
      return Right(source);
    } catch (error) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to save this schedule to your library.',
        ),
      );
    }
  }

  Future<Either<Failure, SpaceSchedule>> _deleteRemoteScheduleSlot({
    required String spaceId,
    required String slotId,
  }) async {
    try {
      await remoteDataSource!.deleteSlot(spaceId: spaceId, slotId: slotId);
      final bootstrap = await remoteDataSource!.getBootstrap(spaceId);
      final localDraft = localDataSource.getDraftSchedule(spaceId);
      final updated = bootstrap.draftSchedule ??
          localDraft?.copyWith(
            slots: localDraft.slots
                .where((slot) => slot.id != slotId)
                .toList(growable: false),
            updatedAt: DateTime.now(),
          );
      if (updated == null) {
        return const Left(CacheFailure('No schedule draft found'));
      }
      await localDataSource.saveDraftSchedule(_toScheduleModel(updated));
      return Right(updated);
    } catch (error) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to remove this schedule slot right now.',
        ),
      );
    }
  }

  Future<Either<Failure, SpaceSchedule>> _toggleRemoteSchedule({
    required String spaceId,
    required bool enabled,
  }) async {
    try {
      await remoteDataSource!.toggle(spaceId: spaceId, enabled: enabled);
      final bootstrap = await remoteDataSource!.getBootstrap(spaceId);
      final localDraft = localDataSource.getDraftSchedule(spaceId);
      final updated = bootstrap.draftSchedule ??
          localDraft?.copyWith(enabled: enabled, updatedAt: DateTime.now());
      if (updated == null) {
        return const Left(CacheFailure('No schedule draft found'));
      }
      await localDataSource.saveDraftSchedule(_toScheduleModel(updated));
      return Right(updated);
    } catch (error) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to update schedule status right now.',
        ),
      );
    }
  }

  ScheduleSource? _findSavedLibrarySource(
    List<ScheduleSource> sources, {
    required String sourceId,
    required String title,
  }) {
    final normalizedId = sourceId.trim();
    if (normalizedId.isNotEmpty) {
      for (final source in sources) {
        if (source.id == normalizedId) return source;
      }
    }

    final normalizedTitle = title.trim().toLowerCase();
    for (final source in sources) {
      if (source.title.trim().toLowerCase() == normalizedTitle) {
        return source;
      }
    }

    return null;
  }

  ScheduleSourceModel _buildLibrarySourceFallback({
    required SpaceSchedule schedule,
    required String title,
    String? subtitle,
  }) {
    return ScheduleSourceModel(
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
