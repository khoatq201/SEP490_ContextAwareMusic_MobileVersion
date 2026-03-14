import 'package:cams_store_manager/core/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('splash screen renders CAMS loading state',
      (WidgetTester tester) async {
    var initialized = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          onInitializationComplete: () {
            initialized = true;
          },
        ),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Store Manager'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2600));
    expect(initialized, isTrue);
  });
}
