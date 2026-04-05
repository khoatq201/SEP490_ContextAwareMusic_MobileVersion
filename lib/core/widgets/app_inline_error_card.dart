import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../error/failures.dart';
import '../presentation/app_error_presentation.dart';

class AppInlineErrorCard extends StatelessWidget {
  const AppInlineErrorCard({
    super.key,
    this.failure,
    this.title,
    this.message,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.margin,
  });

  final Failure? failure;
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final presentation = failure != null
        ? AppErrorPresentation.fromFailure(
            failure,
            title: title,
            message: message,
          )
        : AppErrorPresentation.custom(
            title: title ?? 'Something went wrong',
            message: message ?? 'Please try again.',
          );
    final colors = _inlineColors(presentation.tone, isDark: isDark);

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(presentation.icon, color: colors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  presentation.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  presentation.message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textSecondary,
                      ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft,
                      foregroundColor: colors.accent,
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(retryLabel),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineColors {
  const _InlineColors({
    required this.accent,
    required this.background,
    required this.border,
  });

  final Color accent;
  final Color background;
  final Color border;
}

_InlineColors _inlineColors(
  AppStatusTone tone, {
  required bool isDark,
}) {
  switch (tone) {
    case AppStatusTone.warning:
      return _InlineColors(
        accent: AppColors.warningDark,
        background: AppColors.warning.withValues(alpha: isDark ? 0.16 : 0.1),
        border: AppColors.warning.withValues(alpha: isDark ? 0.36 : 0.22),
      );
    case AppStatusTone.info:
      return _InlineColors(
        accent: isDark ? AppColors.primaryCyan : AppColors.infoDark,
        background: AppColors.info.withValues(alpha: isDark ? 0.16 : 0.1),
        border: AppColors.info.withValues(alpha: isDark ? 0.36 : 0.22),
      );
    case AppStatusTone.success:
      return _InlineColors(
        accent: AppColors.successDark,
        background: AppColors.success.withValues(alpha: isDark ? 0.16 : 0.1),
        border: AppColors.success.withValues(alpha: isDark ? 0.36 : 0.22),
      );
    case AppStatusTone.error:
      return _InlineColors(
        accent: AppColors.errorDark,
        background: AppColors.error.withValues(alpha: isDark ? 0.16 : 0.1),
        border: AppColors.error.withValues(alpha: isDark ? 0.36 : 0.22),
      );
  }
}
