import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/space_schedule/data/models/space_schedule_model.dart';
import 'package:cams_store_manager/features/space_schedule/data/models/schedule_source_model.dart';
import 'package:cams_store_manager/features/space_schedule/domain/entities/schedule_source.dart';

import 'space_schedule_test_helpers.dart';

void main() {
  group('SpaceScheduleRepositoryImpl', () {
    test('restores draft and merges saved library items with seeded sources',
        () async {
      final storage = InMemoryLocalStorageService();
      final localDataSource = buildLocalDataSource(storage);
      final repository = buildSpaceScheduleRepository(storage: storage);

      await seedDraftSchedule(storage, spaceId: 'space-1');
      await localDataSource.saveLibrarySources(
        [
          ScheduleSourceModel(
            id: 'user-library-001',
            title: 'My Brunch Copy',
            subtitle: 'Saved locally',
            type: ScheduleSourceType.library,
            schedule: SpaceScheduleModel(
              id: 'local-schedule-001',
              name: 'My Brunch Copy',
              spaceId: null,
              slots: const [],
              enabled: true,
              updatedAt: DateTime(2026, 3, 15, 11),
            ),
            isUserCreated: true,
          ),
        ],
      );

      final result = await repository.getBootstrap(
        spaceId: 'space-1',
        spaceName: 'Floor 1',
      );

      result.fold(
        (failure) => fail('Expected bootstrap to succeed: ${failure.message}'),
        (bootstrap) {
          expect(bootstrap.draftSchedule, isNotNull);
          expect(bootstrap.draftSchedule!.spaceId, 'space-1');
          expect(
            bootstrap.librarySources.any((source) => source.id == 'user-library-001'),
            isTrue,
          );
          expect(bootstrap.librarySources.length, greaterThanOrEqualTo(3));
          expect(bootstrap.templateSources, isNotEmpty);
          expect(bootstrap.musicCatalog, isNotEmpty);
        },
      );
    });

    test('applyScheduleSource clones template into the target space draft',
        () async {
      final storage = InMemoryLocalStorageService();
      final repository = buildSpaceScheduleRepository(storage: storage);
      final localDataSource = buildLocalDataSource(storage);

      final bootstrap = await repository.getBootstrap(
        spaceId: 'space-9',
        spaceName: 'VIP Area',
      );

      final template = bootstrap.getOrElse(
        () => throw StateError('Bootstrap failed'),
      ).templateSources.first;

      final result = await repository.applyScheduleSource(
        spaceId: 'space-9',
        spaceName: 'VIP Area',
        source: template,
      );

      result.fold(
        (failure) => fail('Expected applyScheduleSource to succeed: ${failure.message}'),
        (schedule) {
          expect(schedule.spaceId, 'space-9');
          expect(schedule.id, 'space-schedule-space-9');
          expect(schedule.sourceId, template.id);
          expect(schedule.slots, isNotEmpty);
        },
      );

      final persisted = localDataSource.getDraftSchedule('space-9');
      expect(persisted, isNotNull);
      expect(persisted!.spaceId, 'space-9');
      expect(template.schedule.spaceId, isNull);
    });

    test('deleteScheduleSlot updates persisted draft', () async {
      final storage = InMemoryLocalStorageService();
      final repository = buildSpaceScheduleRepository(storage: storage);

      await seedDraftSchedule(storage, spaceId: 'space-delete');

      final result = await repository.deleteScheduleSlot(
        spaceId: 'space-delete',
        slotId: 'seed-slot-001',
      );

      result.fold(
        (failure) => fail('Expected slot deletion to succeed: ${failure.message}'),
        (schedule) => expect(schedule.slots, isEmpty),
      );
    });
  });
}
