import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cams_store_manager/core/services/local_storage_service.dart';
import 'package:cams_store_manager/features/space_schedule/data/datasources/space_schedule_local_datasource.dart';
import 'package:cams_store_manager/features/space_schedule/data/datasources/space_schedule_mock_datasource.dart';
import 'package:cams_store_manager/features/space_schedule/data/models/schedule_slot_model.dart';
import 'package:cams_store_manager/features/space_schedule/data/models/space_schedule_model.dart';
import 'package:cams_store_manager/features/space_schedule/data/repositories/space_schedule_repository_impl.dart';
import 'package:cams_store_manager/features/space_schedule/domain/usecases/space_schedule_usecases.dart';
import 'package:cams_store_manager/features/space_schedule/presentation/bloc/space_schedule_bloc.dart';

class InMemoryLocalStorageService extends LocalStorageService {
  final Map<String, dynamic> _settings = {};

  @override
  dynamic getSetting(String key) => _settings[key];

  @override
  Future<void> saveSetting(String key, dynamic value) async {
    _settings[key] = value;
  }
}

SpaceScheduleLocalDataSource buildLocalDataSource(
  InMemoryLocalStorageService storage,
) {
  return SpaceScheduleLocalDataSource(localStorage: storage);
}

SpaceScheduleRepositoryImpl buildSpaceScheduleRepository({
  InMemoryLocalStorageService? storage,
}) {
  final resolvedStorage = storage ?? InMemoryLocalStorageService();
  return SpaceScheduleRepositoryImpl(
    mockDataSource: SpaceScheduleMockDataSource(),
    localDataSource: buildLocalDataSource(resolvedStorage),
  );
}

SpaceScheduleBloc buildSpaceScheduleBloc({
  InMemoryLocalStorageService? storage,
}) {
  final repository = buildSpaceScheduleRepository(storage: storage);
  return SpaceScheduleBloc(
    getSpaceScheduleBootstrap: GetSpaceScheduleBootstrap(repository),
    applyScheduleSource: ApplyScheduleSource(repository),
    saveSpaceSchedule: SaveSpaceSchedule(repository),
    saveScheduleToLibrary: SaveScheduleToLibrary(repository),
    deleteScheduleSlot: DeleteScheduleSlot(repository),
  );
}

Future<void> seedDraftSchedule(
  InMemoryLocalStorageService storage, {
  required String spaceId,
  String name = 'Seeded Schedule',
}) async {
  final localDataSource = buildLocalDataSource(storage);
  await localDataSource.saveDraftSchedule(
    SpaceScheduleModel(
      id: 'space-schedule-$spaceId',
      name: name,
      spaceId: spaceId,
      slots: const [
        ScheduleSlotModel(
          id: 'seed-slot-001',
          daysOfWeek: [7],
          startTime: '14:00',
          endTime: '16:00',
          musicId: 'music-001',
        ),
      ],
      enabled: true,
      sourceLabel: 'Seeded Library',
      updatedAt: DateTime(2026, 3, 15, 10),
    ),
  );
}

Future<void> waitForScheduleData() async {
  await Future<void>.delayed(const Duration(milliseconds: 700));
}

Future<void> closeBloc(BlocBase bloc) async {
  await bloc.close();
}
