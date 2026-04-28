import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../presentation/app_error_presentation.dart';
import '../error/failures.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    this.failure,
    this.title,
    this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.onSecondaryAction,
    this.secondaryLabel,
    this.icon,
    this.padding = const EdgeInsets.all(24),
  });

  final Failure? failure;
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final VoidCallback? onSecondaryAction;
  final String? secondaryLabel;
  final IconData? icon;
  final EdgeInsetsGeometry padding;

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
            icon: icon ?? Icons.error_outline_rounded,
          );
    final colors = _colorsFor(presentation.tone, isDark: isDark);

    return Center(
      child: SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? presentation.icon,
                  color: colors.accent,
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                presentation.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textDarkPrimary
                          : AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                presentation.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textSecondary,
                    ),
              ),
              if (onRetry != null || onSecondaryAction != null) ...[
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (onRetry != null)
                      FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(retryLabel),
                      ),
                    if (onSecondaryAction != null && secondaryLabel != null)
                      TextButton(
                        onPressed: onSecondaryAction,
                        child: Text(secondaryLabel!),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorViewColors {
  const _ErrorViewColors({
    required this.accent,
    required this.background,
  });

  final Color accent;
  final Color background;
}

_ErrorViewColors _colorsFor(
  AppStatusTone tone, {
  required bool isDark,
}) {
  switch (tone) {
    case AppStatusTone.warning:
      return _ErrorViewColors(
        accent: AppColors.warningDark,
        background: AppColors.warning.withValues(alpha: isDark ? 0.18 : 0.12),
      );
    case AppStatusTone.info:
      return _ErrorViewColors(
        accent: isDark ? AppColors.primaryCyan : AppColors.infoDark,
        background: AppColors.info.withValues(alpha: isDark ? 0.18 : 0.12),
      );
    case AppStatusTone.success:
      return _ErrorViewColors(
        accent: AppColors.successDark,
        background: AppColors.success.withValues(alpha: isDark ? 0.18 : 0.12),
      );
    case AppStatusTone.error:
      return _ErrorViewColors(
        accent: AppColors.errorDark,
        background: AppColors.error.withValues(alpha: isDark ? 0.18 : 0.12),
      );
  }
}
