import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/error/failures.dart';
import 'package:cams_store_manager/core/error/failure_kind.dart';
import 'package:cams_store_manager/core/presentation/app_feedback.dart';
import 'package:cams_store_manager/core/widgets/app_error_view.dart';
import 'package:cams_store_manager/core/widgets/app_feedback_presenter.dart';
import 'package:cams_store_manager/core/widgets/app_inline_error_card.dart';

void main() {
  group('App error UX', () {
    testWidgets('AppErrorView hides DioException details', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppErrorView(
              failure: ServerFailure(
                'Failed to load playlists: DioException [bad response]',
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('DioException'), findsNothing);
      expect(
        find.text('Something went wrong on our side. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('AppInlineErrorCard hides SocketException details', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppInlineErrorCard(
              failure: NetworkFailure(
                'SocketException: Failed host lookup: api.example.com',
                FailureKind.network,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('SocketException'), findsNothing);
      expect(
        find.text('Check your internet connection and try again.'),
        findsOneWidget,
      );
    });

    testWidgets('AppFeedbackPresenter shows friendly snackbar copy', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.shrink(),
          ),
        ),
      );

      AppFeedbackPresenter.show(
        tester.element(find.byType(Scaffold)),
        AppFeedback.fromFailure(
          const ServerFailure(
            'Failed to update queue: DioException [bad response]',
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('DioException'), findsNothing);
      expect(find.textContaining('Something went wrong'), findsOneWidget);
    });
  });
}
