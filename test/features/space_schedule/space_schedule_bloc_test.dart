import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/space_schedule/presentation/bloc/space_schedule_event.dart';
import 'package:cams_store_manager/features/space_schedule/presentation/bloc/space_schedule_state.dart';

import 'space_schedule_test_helpers.dart';

void main() {
  group('SpaceScheduleBloc', () {
    test('starts in welcome stage when there is no saved draft', () async {
      final bloc = buildSpaceScheduleBloc();
      addTearDown(() => closeBloc(bloc));

      bloc.add(
        const SpaceScheduleStarted(
          spaceId: 'space-1',
          storeId: 'store-1',
          spaceName: 'Floor 1',
        ),
      );
      await waitForScheduleData();

      expect(bloc.state.status, SpaceScheduleStatus.loaded);
      expect(bloc.state.stage, SpaceScheduleStage.welcome);
      expect(bloc.state.draftSchedule, isNull);
      expect(bloc.state.librarySources, isNotEmpty);
      expect(bloc.state.templateSources, isNotEmpty);
    });

    test('restores editor stage when a local draft already exists', () async {
      final storage = InMemoryLocalStorageService();
      await seedDraftSchedule(storage, spaceId: 'space-2');
      final bloc = buildSpaceScheduleBloc(storage: storage);
      addTearDown(() => closeBloc(bloc));

      bloc.add(
        const SpaceScheduleStarted(
          spaceId: 'space-2',
          storeId: 'store-1',
          spaceName: 'Floor 2',
        ),
      );
      await waitForScheduleData();

      expect(bloc.state.stage, SpaceScheduleStage.editor);
      expect(bloc.state.draftSchedule, isNotNull);
      expect(bloc.state.draftSchedule!.slots.length, 1);
    });

    test('applies template source and saves a library copy', () async {
      final storage = InMemoryLocalStorageService();
      final bloc = buildSpaceScheduleBloc(storage: storage);
      addTearDown(() => closeBloc(bloc));

      bloc.add(
        const SpaceScheduleStarted(
          spaceId: 'space-3',
          storeId: 'store-1',
          spaceName: 'Meeting Room',
        ),
      );
      await waitForScheduleData();

      final template = bloc.state.templateSources.first;
      bloc.add(SpaceScheduleSourceSelected(template));
      await waitForScheduleData();

      expect(bloc.state.stage, SpaceScheduleStage.editor);
      expect(bloc.state.draftSchedule?.sourceId, template.id);

      bloc.add(
        const SpaceScheduleSavedToLibrary(
          title: 'Copied Schedule',
          subtitle: 'Saved from test',
        ),
      );
      await waitForScheduleData();

      expect(
        bloc.state.librarySources
            .any((source) => source.title == 'Copied Schedule'),
        isTrue,
      );
    });
  });
}
