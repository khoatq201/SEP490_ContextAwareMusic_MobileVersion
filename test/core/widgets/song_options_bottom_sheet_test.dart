import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/services/local_storage_service.dart';
import 'package:cams_store_manager/core/session/session_cubit.dart';
import 'package:cams_store_manager/core/widgets/song_options_bottom_sheet.dart';
import 'package:cams_store_manager/features/home/domain/entities/song_entity.dart';

void main() {
  testWidgets(
      'hides Play now and enables queue label when queue-first option sheet is used',
      (tester) async {
    final sessionCubit = SessionCubit(
      localStorage: _InMemoryLocalStorageService(),
    );
    addTearDown(sessionCubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SessionCubit>.value(
          value: sessionCubit,
          child: const Scaffold(
            body: SongOptionsBottomSheet(
              song: SongEntity(
                id: 'song-1',
                title: 'Queue First Song',
                artist: 'CAMS',
                duration: 120,
              ),
              showPlayNow: false,
              enableAddToQueue: true,
              addToQueueLabel: 'Add to space queue',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Play now'), findsNothing);
    expect(find.text('Add to space queue'), findsOneWidget);
  });
}

class _InMemoryLocalStorageService extends LocalStorageService {
  final Map<String, dynamic> _settings = {};

  @override
  dynamic getSetting(String key) => _settings[key];

  @override
  Future<void> saveSetting(String key, dynamic value) async {
    _settings[key] = value;
  }

  @override
  Future<void> removeSetting(String key) async {
    _settings.remove(key);
  }
}
