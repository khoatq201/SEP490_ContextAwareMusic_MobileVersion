import 'package:cams_store_manager/core/widgets/cams_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CamsSkeleton renders in light and dark themes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: const Scaffold(
          body: CamsSkeletonList(itemCount: 2),
        ),
      ),
    );

    expect(find.byType(CamsSkeletonList), findsOneWidget);
    expect(find.byType(CamsSkeleton), findsWidgets);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        home: const Scaffold(
          body: CamsSkeletonList(itemCount: 2),
        ),
      ),
    );

    expect(find.byType(CamsSkeletonList), findsOneWidget);
    expect(find.byType(CamsSkeleton), findsWidgets);
  });

  testWidgets('CamsSkeleton can render inside a sliver scroll view',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CamsSkeletonCardGrid(itemCount: 4),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(CamsSkeletonCardGrid), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
