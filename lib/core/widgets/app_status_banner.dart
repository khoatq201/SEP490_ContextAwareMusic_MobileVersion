import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../presentation/app_error_presentation.dart';

class AppStatusBanner extends StatelessWidget {
  const AppStatusBanner({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.tone = AppStatusTone.info,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData? icon;
  final AppStatusTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _bannerColors(tone, isDark: isDark);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? colors.icon, color: colors.accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.45,
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textSecondary,
                      ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: colors.accent,
                    ),
                    child: Text(actionLabel!),
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

class _BannerColors {
  const _BannerColors({
    required this.accent,
    required this.background,
    required this.border,
    required this.icon,
  });

  final Color accent;
  final Color background;
  final Color border;
  final IconData icon;
}

_BannerColors _bannerColors(
  AppStatusTone tone, {
  required bool isDark,
}) {
  switch (tone) {
    case AppStatusTone.warning:
      return _BannerColors(
        accent: AppColors.warningDark,
        background: AppColors.warning.withValues(alpha: isDark ? 0.16 : 0.1),
        border: AppColors.warning.withValues(alpha: isDark ? 0.36 : 0.22),
        icon: Icons.warning_amber_rounded,
      );
    case AppStatusTone.info:
      return _BannerColors(
        accent: isDark ? AppColors.primaryCyan : AppColors.infoDark,
        background: AppColors.info.withValues(alpha: isDark ? 0.16 : 0.1),
        border: AppColors.info.withValues(alpha: isDark ? 0.36 : 0.22),
        icon: Icons.info_outline_rounded,
      );
    case AppStatusTone.success:
      return _BannerColors(
        accent: AppColors.successDark,
        background: AppColors.success.withValues(alpha: isDark ? 0.16 : 0.1),
        border: AppColors.success.withValues(alpha: isDark ? 0.36 : 0.22),
        icon: Icons.check_circle_outline_rounded,
      );
    case AppStatusTone.error:
      return _BannerColors(
        accent: AppColors.errorDark,
        background: AppColors.error.withValues(alpha: isDark ? 0.16 : 0.1),
        border: AppColors.error.withValues(alpha: isDark ? 0.36 : 0.22),
        icon: Icons.error_outline_rounded,
      );
  }
}
