import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../presentation/app_error_presentation.dart';
import '../presentation/app_feedback.dart';

class AppFeedbackPresenter {
  const AppFeedbackPresenter._();

  static void show(
    BuildContext context,
    AppFeedback feedback,
  ) {
    final errorPresentation = feedback.failure == null
        ? null
        : AppErrorPresentation.fromFailure(
            feedback.failure,
            title: feedback.title,
            message: feedback.message,
          );
    final resolvedTitle = errorPresentation?.title ?? feedback.title;
    final resolvedMessage = errorPresentation?.message ?? feedback.message;
    final colors = _colorsFor(feedback.type);
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.background,
          content: Row(
            children: [
              Icon(colors.icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  resolvedTitle == null
                      ? resolvedMessage
                      : '$resolvedTitle: $resolvedMessage',
                ),
              ),
            ],
          ),
        ),
      );
  }

  static _FeedbackColors _colorsFor(AppFeedbackType type) {
    switch (type) {
      case AppFeedbackType.success:
        return const _FeedbackColors(
          background: AppColors.successDark,
          icon: Icons.check_circle_outline,
        );
      case AppFeedbackType.warning:
        return const _FeedbackColors(
          background: AppColors.warningDark,
          icon: Icons.warning_amber_rounded,
        );
      case AppFeedbackType.info:
        return const _FeedbackColors(
          background: AppColors.infoDark,
          icon: Icons.info_outline,
        );
      case AppFeedbackType.error:
        return const _FeedbackColors(
          background: AppColors.errorDark,
          icon: Icons.error_outline_rounded,
        );
    }
  }
}

class _FeedbackColors {
  const _FeedbackColors({
    required this.background,
    required this.icon,
  });

  final Color background;
  final IconData icon;
}
