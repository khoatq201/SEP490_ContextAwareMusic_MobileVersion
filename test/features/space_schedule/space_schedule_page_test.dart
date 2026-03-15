import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/space_schedule/presentation/bloc/space_schedule_event.dart';
import 'package:cams_store_manager/features/space_schedule/data/models/space_schedule_model.dart';
import 'package:cams_store_manager/features/space_schedule/presentation/pages/space_schedule_page.dart';

import 'space_schedule_test_helpers.dart';

void main() {
  group('SpaceSchedulePage', () {
    testWidgets('renders welcome state CTAs for a fresh space',
        (tester) async {
      final bloc = buildSpaceScheduleBloc();
      addTearDown(() => closeBloc(bloc));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc
              ..add(
                const SpaceScheduleStarted(
                  spaceId: 'space-1',
                  storeId: 'store-1',
                  spaceName: 'Floor 1',
                ),
              ),
            child: const SpaceSchedulePage(
              spaceId: 'space-1',
              storeId: 'store-1',
              spaceName: 'Floor 1',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.text('First schedule,\nlet\'s go.'), findsOneWidget);
      expect(find.text('Load schedule'), findsOneWidget);
      expect(find.text('Create new'), findsOneWidget);
    });

    testWidgets('switches between library and templates in source picker',
        (tester) async {
      final bloc = buildSpaceScheduleBloc();
      addTearDown(() => closeBloc(bloc));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc
              ..add(
                const SpaceScheduleStarted(
                  spaceId: 'space-2',
                  storeId: 'store-1',
                  spaceName: 'Floor 2',
                ),
              ),
            child: const SpaceSchedulePage(
              spaceId: 'space-2',
              storeId: 'store-1',
              spaceName: 'Floor 2',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      await tester.tap(find.text('Load schedule'));
      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.text('Ready-made Lunch Rush'), findsOneWidget);

      await tester.tap(find.text('Templates'));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      expect(find.text('Feelgood Restaurant'), findsOneWidget);
    });

    testWidgets('adds a slot from the editor and renders it on the timeline',
        (tester) async {
      final storage = InMemoryLocalStorageService();
      final localDataSource = buildLocalDataSource(storage);
      final bloc = buildSpaceScheduleBloc(storage: storage);
      addTearDown(() => closeBloc(bloc));

      await localDataSource.saveDraftSchedule(
        SpaceScheduleModel(
          id: 'space-schedule-space-3',
          name: 'Editable Schedule',
          spaceId: 'space-3',
          slots: const [],
          enabled: true,
          updatedAt: DateTime(2026, 3, 15, 10),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc
              ..add(
                const SpaceScheduleStarted(
                  spaceId: 'space-3',
                  storeId: 'store-1',
                  spaceName: 'Meeting Room',
                ),
              ),
            child: const SpaceSchedulePage(
              spaceId: 'space-3',
              storeId: 'store-1',
              spaceName: 'Meeting Room',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.text('Day & Time'), findsOneWidget);
      await tester.tap(find.text('Add music'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      await tester.tap(find.byKey(const ValueKey('music-option-music-001')));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      await tester.ensureVisible(find.byKey(const ValueKey('slot-editor-save')));
      await tester.tap(find.byKey(const ValueKey('slot-editor-save')));
      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.text('Indie Pop Pillow'), findsOneWidget);
    });
  });
}
