import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/space_schedule/domain/entities/schedule_source.dart';
import 'package:cams_store_manager/features/space_schedule/domain/entities/space_schedule.dart';
import 'package:cams_store_manager/features/space_schedule/presentation/widgets/schedule_source_form_dialog.dart';

void main() {
  group('ScheduleSourceFormDialog', () {
    testWidgets('requires title before enabling save and returns payload',
        (tester) async {
      ScheduleSourceFormPayload? result;

      await tester.pumpWidget(
        MaterialApp(
          home: _DialogHost<ScheduleSourceFormPayload>(
            onResult: (value) => result = value,
            builder: (_) => const ScheduleSourceFormDialog(
              title: 'Create brand schedule',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      FilledButton saveButton() => tester.widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Save'),
          );

      expect(saveButton().onPressed, isNull);

      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(3));

      await tester.enterText(fields.at(0), 'Weekday Lunch');
      await tester.enterText(fields.at(1), 'Store default');
      await tester.enterText(fields.at(2), 'Use this during lunch rush.');
      await tester.pumpAndSettle();

      expect(saveButton().onPressed, isNotNull);

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.title, 'Weekday Lunch');
      expect(result!.subtitle, 'Store default');
      expect(result!.description, 'Use this during lunch rush.');
    });

    testWidgets('fromSource pre-fills fields and supports editing',
        (tester) async {
      ScheduleSourceFormPayload? result;

      await tester.pumpWidget(
        MaterialApp(
          home: _DialogHost<ScheduleSourceFormPayload>(
            onResult: (value) => result = value,
            builder: (_) => ScheduleSourceFormDialog.fromSource(
              title: 'Edit brand schedule',
              source: ScheduleSource(
                id: 'source-1',
                title: 'Lunch Rush',
                subtitle: 'Brand v1',
                description: 'Default daytime rotation',
                type: ScheduleSourceType.library,
                schedule: SpaceSchedule(
                  id: 'schedule-1',
                  name: 'Lunch Rush',
                  spaceId: null,
                  slots: const [],
                  enabled: true,
                  updatedAt: DateTime.utc(2026, 4, 22),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lunch Rush'), findsOneWidget);
      expect(find.text('Brand v1'), findsOneWidget);
      expect(find.text('Default daytime rotation'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'Lunch Rush v2');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.title, 'Lunch Rush v2');
      expect(result!.subtitle, 'Brand v1');
      expect(result!.description, 'Default daytime rotation');
    });

    testWidgets('can hide description field for save-to-library mode',
        (tester) async {
      ScheduleSourceFormPayload? result;

      await tester.pumpWidget(
        MaterialApp(
          home: _DialogHost<ScheduleSourceFormPayload>(
            onResult: (value) => result = value,
            builder: (_) => const ScheduleSourceFormDialog(
              title: 'Save to library',
              actionLabel: 'Save copy',
              initialTitle: 'Meeting Room copy',
              showDescription: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Description'), findsNothing);

      await tester.enterText(find.byType(TextField).at(1), 'For reuse');
      await tester.tap(find.widgetWithText(FilledButton, 'Save copy'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.title, 'Meeting Room copy');
      expect(result!.subtitle, 'For reuse');
      expect(result!.description, isEmpty);
    });
  });
}

class _DialogHost<T> extends StatefulWidget {
  const _DialogHost({
    required this.builder,
    required this.onResult,
  });

  final WidgetBuilder builder;
  final ValueChanged<T?> onResult;

  @override
  State<_DialogHost<T>> createState() => _DialogHostState<T>();
}

class _DialogHostState<T> extends State<_DialogHost<T>> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await showDialog<T>(
        context: context,
        builder: widget.builder,
      );
      widget.onResult(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}
