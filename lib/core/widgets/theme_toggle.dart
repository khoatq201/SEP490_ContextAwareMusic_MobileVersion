import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../theme/cams_theme_tokens.dart';
import '../theme/theme_provider.dart';
import 'cams_glow_effects.dart';

/// Theme toggle switch widget with neon effects
class ThemeToggleSwitch extends StatelessWidget {
  final bool showLabel;
  final bool glowEffect;

  const ThemeToggleSwitch({
    super.key,
    this.showLabel = true,
    this.glowEffect = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.camsTokens;

    Widget toggleWidget = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacing8,
      ),
      decoration: BoxDecoration(
        color: tokens.bgElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
          color: isDark
              ? tokens.techAccent.withValues(alpha: 0.3)
              : tokens.borderSecondary,
          width: AppDimensions.borderWidthNormal,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wb_sunny,
            color: isDark ? tokens.textTertiary : colorScheme.primary,
            size: AppDimensions.iconSm,
          ),
          const SizedBox(width: AppDimensions.spacing8),
          Switch(
            value: isDark,
            onChanged: (_) => themeProvider.toggleTheme(),
            activeThumbColor: tokens.techAccent,
            activeTrackColor: tokens.techAccent.withValues(alpha: 0.35),
          ),
          const SizedBox(width: AppDimensions.spacing8),
          Icon(
            Icons.nights_stay,
            color: isDark ? tokens.techAccent : tokens.textTertiary,
            size: AppDimensions.iconSm,
          ),
          if (showLabel) ...[
            const SizedBox(width: AppDimensions.spacingMd),
            Text(
              isDark ? 'Dark Mode' : 'Light Mode',
              style: AppTypography.labelMedium.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    if (glowEffect && isDark) {
      return CAMSGlowContainer(
        glowColor: tokens.techAccent,
        glowRadius: 15,
        glowSpread: 1,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: toggleWidget,
      );
    }

    return toggleWidget;
  }
}

/// Floating Action Button for theme toggle
class ThemeToggleFAB extends StatelessWidget {
  const ThemeToggleFAB({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    Widget fab = FloatingActionButton(
      onPressed: () => themeProvider.toggleTheme(),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return RotationTransition(
            turns: animation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: Icon(
          isDark ? Icons.wb_sunny : Icons.nights_stay,
          key: ValueKey(isDark),
          color: colorScheme.onPrimary,
        ),
      ),
    );

    if (isDark) {
      return CAMSGlowContainer(
        glowRadius: 20,
        glowSpread: 3,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        child: fab,
      );
    }

    return fab;
  }
}

/// Theme selector card
class ThemeSelectorCard extends StatelessWidget {
  const ThemeSelectorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.camsTokens;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: tokens.bgContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(
          color: tokens.borderSecondary,
          width: AppDimensions.borderWidthNormal,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: tokens.techAccent.withValues(alpha: 0.1),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: tokens.shadow.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                color: isDark ? tokens.techAccent : colorScheme.primary,
                size: AppDimensions.iconMd,
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Text(
                'Theme Settings',
                style: AppTypography.titleMedium.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          const ThemeToggleSwitch(showLabel: true, glowEffect: true),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            isDark
                ? 'Minimalist Digital Pulse - Dark mode with cyan & lime neon accents'
                : 'Adaptive Retail Hub - Light mode with orange & teal theme',
            style: AppTypography.bodySmall.copyWith(
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
