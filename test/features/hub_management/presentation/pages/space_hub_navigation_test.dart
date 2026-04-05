import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:cams_store_manager/core/enums/entity_status_enum.dart';
import 'package:cams_store_manager/core/enums/space_type_enum.dart';
import 'package:cams_store_manager/core/services/local_storage_service.dart';
import 'package:cams_store_manager/core/session/session_cubit.dart';
import 'package:cams_store_manager/features/locations/domain/entities/location_space.dart';
import 'package:cams_store_manager/features/locations/presentation/widgets/space_settings_sheet.dart';
import 'package:cams_store_manager/features/space_control/presentation/pages/space_settings_page.dart';

void main() {
  group('Hub navigation entry points', () {
    late SessionCubit sessionCubit;

    setUp(() {
      sessionCubit = SessionCubit(localStorage: _InMemoryLocalStorageService());
    });

    tearDown(() async {
      await sessionCubit.close();
    });

    testWidgets('SpaceSettingsPage opens the space hub route', (tester) async {
      final router = _buildRouter(
        home: const SpaceSettingsPage(
          storeId: 'store-1',
          spaceId: 'space-1',
          spaceName: 'Main Hall',
        ),
      );

      await tester.pumpWidget(
        BlocProvider.value(
          value: sessionCubit,
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.tap(find.text('IoT Hub & Wi-Fi'));
      await tester.pumpAndSettle();

      expect(find.text('Stub Space Hub'), findsOneWidget);
      expect(find.text('space-1 | store-1 | Main Hall'), findsOneWidget);
    });

    testWidgets('SpaceSettingsSheet opens the same hub route', (tester) async {
      final router = _buildRouter(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (_) => const SpaceSettingsSheet(
                        space: LocationSpace(
                          id: 'space-1',
                          name: 'Main Hall',
                          storeId: 'store-1',
                          type: SpaceTypeEnum.hall,
                          status: EntityStatusEnum.active,
                        ),
                        isPlaybackDevice: false,
                      ),
                    );
                  },
                  child: const Text('Open sheet'),
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpWidget(
        BlocProvider.value(
          value: sessionCubit,
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('IoT Hub & Wi-Fi'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('IoT Hub & Wi-Fi'));
      await tester.pumpAndSettle();

      expect(find.text('Stub Space Hub'), findsOneWidget);
      expect(find.text('space-1 | store-1 | Main Hall'), findsOneWidget);
    });
  });
}

GoRouter _buildRouter({required Widget home}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => home,
      ),
      GoRoute(
        path: '/space-hub',
        builder: (context, state) {
          final spaceId = state.uri.queryParameters['spaceId'];
          final storeId = state.uri.queryParameters['storeId'];
          final spaceName = state.uri.queryParameters['spaceName'];
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Stub Space Hub'),
                  Text('$spaceId | $storeId | $spaceName'),
                ],
              ),
            ),
          );
        },
      ),
    ],
  );
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
