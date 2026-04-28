import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/space_schedule/domain/entities/schedule_music_item.dart';
import 'package:cams_store_manager/features/space_schedule/domain/entities/schedule_slot.dart';
import 'package:cams_store_manager/features/space_schedule/presentation/widgets/schedule_slot_form_sheet.dart';

void main() {
  group('ScheduleSlotFormSheet', () {
    testWidgets('creates a single-day slot with selected playlist',
        (tester) async {
      ScheduleSlot? result;

      await tester.pumpWidget(
        MaterialApp(
          home: _BottomSheetHost<ScheduleSlot>(
            onResult: (value) => result = value,
            builder: (_) => const ScheduleSlotFormSheet(
              title: 'Add schedule slot',
              slot: null,
              initialDay: 2,
              musicCatalog: _musicCatalog,
              generatedIdPrefix: 'slot-test',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add schedule slot'), findsOneWidget);

      await tester.tap(find.text('Fri'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dinner Pulse').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('slot-editor-save')));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.id.startsWith('slot-test-'), isTrue);
      expect(result!.daysOfWeek, const [5]);
      expect(result!.startTime, '09:00');
      expect(result!.endTime, '12:00');
      expect(result!.musicId, 'music-2');
    });

    testWidgets('keeps existing id and supports multi-day brand editing',
        (tester) async {
      ScheduleSlot? result;

      await tester.pumpWidget(
        MaterialApp(
          home: _BottomSheetHost<ScheduleSlot>(
            onResult: (value) => result = value,
            builder: (_) => const ScheduleSlotFormSheet(
              title: 'Edit brand slot',
              slot: ScheduleSlot(
                id: 'brand-slot-7',
                daysOfWeek: [1, 3],
                startTime: '10:00',
                endTime: '13:00',
                musicId: 'music-1',
              ),
              initialDay: 1,
              musicCatalog: _musicCatalog,
              allowMultipleDays: true,
              generatedIdPrefix: 'brand-slot',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit brand slot'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);

      await tester.tap(find.text('Fri'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dinner Pulse').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('slot-editor-save')));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.id, 'brand-slot-7');
      expect(result!.daysOfWeek, const [1, 3, 5]);
      expect(result!.startTime, '10:00');
      expect(result!.endTime, '13:00');
      expect(result!.musicId, 'music-2');
    });

    testWidgets('disables save when there is no playlist to assign',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _BottomSheetHost<ScheduleSlot>(
            onResult: (_) {},
            builder: (_) => const ScheduleSlotFormSheet(
              title: 'Add schedule slot',
              slot: null,
              initialDay: 0,
              musicCatalog: [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final saveButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('slot-editor-save')),
      );
      expect(saveButton.onPressed, isNull);
    });
  });
}

class _BottomSheetHost<T> extends StatefulWidget {
  const _BottomSheetHost({
    required this.builder,
    required this.onResult,
  });

  final WidgetBuilder builder;
  final ValueChanged<T?> onResult;

  @override
  State<_BottomSheetHost<T>> createState() => _BottomSheetHostState<T>();
}

class _BottomSheetHostState<T> extends State<_BottomSheetHost<T>> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
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

const _musicCatalog = [
  ScheduleMusicItem(
    id: 'music-1',
    title: 'Lunch Rush',
    artist: 'CAMS',
    collection: 'Brand',
    artworkLabel: 'LR',
    primaryHex: '#FF6B35',
    secondaryHex: '#FFD166',
  ),
  ScheduleMusicItem(
    id: 'music-2',
    title: 'Dinner Pulse',
    artist: 'CAMS',
    collection: 'Brand',
    artworkLabel: 'DP',
    primaryHex: '#3A86FF',
    secondaryHex: '#8338EC',
  ),
];
