import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:cams_store_manager/features/locations/presentation/widgets/space_management_tile.dart';
import 'package:cams_store_manager/main.dart' as app;

const _email = String.fromEnvironment('E2E_TEST_EMAIL');
const _password = String.fromEnvironment('E2E_TEST_PASSWORD');
const _storeName = String.fromEnvironment(
  'E2E_TEST_STORE_NAME',
  defaultValue: 'DeerCoffee - Pham Ngu Lao',
);
const _spaceName = String.fromEnvironment(
  'E2E_TEST_SPACE_NAME',
  defaultValue: 'Entrance Lounge',
);
const _captureScreenshots = bool.fromEnvironment(
  'E2E_CAPTURE_SCREENSHOTS',
  defaultValue: false,
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'smoke: dashboard tools lead to strict-sync space schedule read-only UX',
    (tester) async {
      _step('boot app');
      assert(
        _email.isNotEmpty && _password.isNotEmpty,
        'Provide E2E_TEST_EMAIL and E2E_TEST_PASSWORD via --dart-define.',
      );

      app.main();
      await tester.pump();
      await _pumpFor(tester, const Duration(seconds: 3));

      if (_captureScreenshots) {
        await binding.convertFlutterSurfaceToImage();
        await tester.pump(const Duration(milliseconds: 300));
      }

      _step('login if needed');
      await _loginIfNeeded(tester);
      _step('land on target store dashboard');
      await _landOnTargetStoreDashboard(tester);

      _step('open brand schedule');
      await _openBrandSchedule(tester);
      await _takeScreenshotIfEnabled(binding, 'schedule_brand_schedule_sheet');
      await _closeSheetIfVisible(tester, tooltip: 'Close');
      await _waitForStoreDashboard(tester);

      _step('open strict sync stores');
      await _openStrictSyncStores(tester);
      await _ensureStoreSelectedInStrictSyncSheet(tester, _storeName);
      await _takeScreenshotIfEnabled(binding, 'schedule_strict_sync_sheet');
      await _tapText(tester, 'Apply');
      await _waitForAny(
        tester,
        <Finder>[
          find.text('Strict Sync store selection updated.'),
          find.text('Strict Sync'),
        ],
        timeout: const Duration(seconds: 20),
      );
      await _waitForStoreDashboard(tester);

      _step('open locations and space schedule');
      await _openSpaceScheduleFromLocations(tester);
      _step('verify read-only banner');
      await _waitForText(
        tester,
        find.text('Controlled by brand schedule'),
        timeout: const Duration(seconds: 20),
      );
      expect(find.text('Controlled by brand schedule'), findsOneWidget);
      expect(
        find.textContaining('Local slots are read-only'),
        findsOneWidget,
      );

      await _takeScreenshotIfEnabled(binding, 'schedule_space_read_only');
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}

void _step(String message) {
  debugPrint('[schedule-smoke] $message');
}

Future<void> _takeScreenshotIfEnabled(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  if (!_captureScreenshots) {
    return;
  }
  await binding.takeScreenshot(name);
}

Future<void> _loginIfNeeded(WidgetTester tester) async {
  if (_finderExists(find.byKey(const ValueKey('login_email_field')))) {
    await _submitLoginForm(tester);
    return;
  }

  final logInButton = find.text('Log in');
  if (_finderExists(logInButton)) {
    await _tap(tester, logInButton);
  }

  await _waitForAny(
    tester,
    <Finder>[
      find.byKey(const ValueKey('login_email_field')),
      find.text('Store Dashboard'),
      find.text('Select Store'),
    ],
  );

  if (_finderExists(find.byKey(const ValueKey('login_email_field')))) {
    await _submitLoginForm(tester);
  }
}

Future<void> _submitLoginForm(WidgetTester tester) async {
  final emailField = find.byKey(const ValueKey('login_email_field'));
  final passwordField = find.byKey(const ValueKey('login_password_field'));

  await _waitForText(tester, emailField);
  await tester.tap(emailField);
  await tester.enterText(emailField, _email);
  await tester.pump(const Duration(milliseconds: 250));

  await tester.tap(passwordField);
  await tester.enterText(passwordField, _password);
  await tester.pump(const Duration(milliseconds: 250));

  await _tapText(tester, 'Sign In');
  await _waitForAny(
    tester,
    <Finder>[
      find.text('Store Dashboard'),
      find.text('Select Store'),
      find.text('Loading your store...'),
    ],
    timeout: const Duration(seconds: 30),
  );

  await _pumpFor(tester, const Duration(seconds: 3));
}

Future<void> _landOnTargetStoreDashboard(WidgetTester tester) async {
  if (_finderExists(find.text('Select Store'))) {
    await _openTargetStoreFromSelection(tester, _storeName);
    return;
  }

  await _waitForStoreDashboard(tester);
  if (_finderExists(find.text(_storeName))) {
    return;
  }

  throw TestFailure(
    'Logged in successfully but dashboard did not land on target store '
    '"$_storeName". Open store-switching UX in a follow-up smoke step if '
    'this account changes its default store.',
  );
}

Future<void> _openTargetStoreFromSelection(
  WidgetTester tester,
  String storeName,
) async {
  await _waitForText(
    tester,
    find.text('Select Store'),
    timeout: const Duration(seconds: 20),
  );

  final storeText = find.text(storeName);
  if (!_finderExists(storeText)) {
    final searchField = find.byType(TextField);
    if (_finderExists(searchField)) {
      await tester.tap(searchField.first);
      await tester.enterText(searchField.first, storeName);
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  await _waitForText(
    tester,
    storeText,
    timeout: const Duration(seconds: 20),
  );
  await _tap(tester, storeText);
  await _waitForStoreDashboard(tester);
}

Future<void> _openBrandSchedule(WidgetTester tester) async {
  await _openStoreTools(tester);
  await _tapText(tester, 'Brand schedule');
  await _waitForText(
    tester,
    find.text('Sources used by Strict Sync stores.'),
    timeout: const Duration(seconds: 20),
  );
}

Future<void> _openStrictSyncStores(WidgetTester tester) async {
  await _openStoreTools(tester);
  await _tapText(tester, 'Strict Sync stores');
  await _waitForText(
    tester,
    find.text('Selected stores must follow brand scheduling. Stores removed from this list are moved to Freedom mode.'),
    timeout: const Duration(seconds: 20),
  );
}

Future<void> _ensureStoreSelectedInStrictSyncSheet(
  WidgetTester tester,
  String storeName,
) async {
  await _waitForText(
    tester,
    find.text(storeName),
    timeout: const Duration(seconds: 20),
  );

  final tileFinder = find.ancestor(
    of: find.text(storeName),
    matching: find.byType(CheckboxListTile),
  );
  if (!_finderExists(tileFinder)) {
    throw TestFailure('Could not locate strict-sync checkbox tile for $storeName.');
  }

  final tile = tester.widget<CheckboxListTile>(tileFinder.first);
  if (tile.value == true) {
    return;
  }

  await _tap(tester, tileFinder);
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _openSpaceScheduleFromLocations(WidgetTester tester) async {
  if (!_finderExists(find.text('Location'))) {
    await _waitForStoreDashboard(tester);
    await _waitForText(
      tester,
      find.text(_spaceName),
      timeout: const Duration(seconds: 20),
    );
    await _tap(tester, find.text(_spaceName));
    await _waitForText(
      tester,
      find.text('Location'),
      timeout: const Duration(seconds: 20),
    );
  }

  await _tapText(tester, 'Location');
  await _waitForAny(
    tester,
    <Finder>[
      find.text('Brand Spaces'),
      find.text('Store Spaces'),
      find.text('Paired Space'),
    ],
    timeout: const Duration(seconds: 20),
  );

  final spaceTile = find.widgetWithText(SpaceManagementTile, _spaceName);
  await _scrollUntilVisible(tester, spaceTile);
  final scheduleLabel = find.descendant(
    of: spaceTile,
    matching: find.text('Schedule'),
  );
  final scheduleAction = find.ancestor(
    of: scheduleLabel,
    matching: find.byType(InkWell),
  );
  await _tap(tester, scheduleAction);

  await _waitForAny(
    tester,
    <Finder>[
      find.text('Controlled by brand schedule'),
      find.textContaining('This store is in Strict Sync'),
    ],
    timeout: const Duration(seconds: 25),
  );
}

Future<void> _openStoreTools(WidgetTester tester) async {
  final toolsButton = find.byTooltip('Store tools');
  await _tap(tester, toolsButton);
  await _waitForText(
    tester,
    find.text('Store tools'),
    timeout: const Duration(seconds: 10),
  );
}

Future<void> _closeSheetIfVisible(
  WidgetTester tester, {
  required String tooltip,
}) async {
  final closeButton = find.byTooltip(tooltip);
  if (!_finderExists(closeButton)) {
    return;
  }
  await _tap(tester, closeButton);
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _waitForStoreDashboard(WidgetTester tester) async {
  await _waitForText(
    tester,
    find.text('Store Dashboard'),
    timeout: const Duration(seconds: 30),
  );
  await _pumpFor(tester, const Duration(seconds: 2));
}

bool _finderExists(Finder finder) => finder.evaluate().isNotEmpty;

Future<void> _tapText(WidgetTester tester, String text) async {
  await _tap(tester, find.text(text));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _waitForText(tester, finder);
  final target = finder.first;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _scrollUntilVisible(WidgetTester tester, Finder finder) async {
  if (_finderExists(finder)) {
    return;
  }

  final scrollable = find.byType(Scrollable).first;
  await tester.scrollUntilVisible(
    finder,
    280,
    scrollable: scrollable,
    maxScrolls: 10,
  );
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _waitForAny(
  WidgetTester tester,
  List<Finder> finders, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finders.any(_finderExists)) {
      return;
    }
  }
  throw TestFailure(
    'Timed out waiting for any of: '
    '${finders.map((finder) => finder.describeMatch(Plurality.many)).join(', ')}',
  );
}

Future<void> _waitForText(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (_finderExists(finder)) {
      return;
    }
  }
  throw TestFailure(
    'Timed out waiting for ${finder.describeMatch(Plurality.many)}.',
  );
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final milliseconds = duration.inMilliseconds;
  const step = 250;
  for (var elapsed = 0; elapsed < milliseconds; elapsed += step) {
    await tester.pump(const Duration(milliseconds: step));
  }
}
