import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../theme/cams_theme_tokens.dart';

/// CAMS Signature Card - Glassmorphism style with orange accent
class CAMSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final CAMSCardVariant variant;
  final bool showBorder;
  final bool showShadow;
  final Gradient? gradient;
  final bool hasGradientBorder;
  final Gradient? borderGradient;

  const CAMSCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.variant = CAMSCardVariant.solid,
    this.showBorder = true,
    this.showShadow = true,
    this.gradient,
    this.hasGradientBorder = false,
    this.borderGradient,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.camsTokens;
    Widget cardContent;

    // Handle gradient border case
    if (hasGradientBorder && borderGradient != null) {
      cardContent = Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: borderGradient,
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        ),
        padding: const EdgeInsets.all(2), // Border width
        child: Container(
          decoration: BoxDecoration(
            color: tokens.bgContainer,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard - 2),
          ),
          padding: padding ?? const EdgeInsets.all(AppDimensions.cardPaddingMd),
          child: child,
        ),
      );
    } else {
      cardContent = Container(
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.all(AppDimensions.cardPaddingMd),
        decoration: _buildDecoration(colorScheme, tokens),
        child: child,
      );
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          splashColor: colorScheme.primary.withValues(alpha: 0.1),
          highlightColor: colorScheme.primary.withValues(alpha: 0.05),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  BoxDecoration _buildDecoration(
    ColorScheme colorScheme,
    CamsThemeTokens tokens,
  ) {
    switch (variant) {
      case CAMSCardVariant.solid:
        return _solidDecoration(tokens);
      case CAMSCardVariant.outlined:
        return _outlinedDecoration(colorScheme);
    }
  }

  BoxDecoration _solidDecoration(CamsThemeTokens tokens) {
    return BoxDecoration(
      color: tokens.bgContainer,
      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      border: showBorder
          ? Border.all(
              color: tokens.borderSecondary,
              width: AppDimensions.borderWidthNormal,
            )
          : null,
      boxShadow: showShadow
          ? [
              BoxShadow(
                color: tokens.shadow.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ]
          : null,
    );
  }

  BoxDecoration _outlinedDecoration(ColorScheme colorScheme) {
    return BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      border: Border.all(
        color: colorScheme.primary,
        width: AppDimensions.borderWidthThick,
      ),
    );
  }
}

enum CAMSCardVariant {
  solid,
  outlined,
}

/// CAMS Sensor Card - Specialized card for sensor data display
class CAMSSensorCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color? iconColor;
  final Color? valueColor;
  final VoidCallback? onTap;

  const CAMSSensorCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    this.iconColor,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    final accent = iconColor ?? tokens.techAccent;
    final valueAccent = valueColor ?? accent;

    return CAMSCard(
      width: AppDimensions.sensorCardWidth,
      height: AppDimensions.sensorCardHeight,
      variant: CAMSCardVariant.solid,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacing8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(
              icon,
              size: AppDimensions.iconLg,
              color: accent,
            ),
          ),

          // Value
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: valueAccent,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      unit,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: tokens.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// CAMS Info Card - For displaying information with icon
class CAMSInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const CAMSInfoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    final accent = iconColor ?? tokens.techAccent;

    return CAMSCard(
      variant: CAMSCardVariant.solid,
      onTap: onTap,
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacing12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(
              icon,
              size: AppDimensions.iconLg,
              color: accent,
            ),
          ),

          const SizedBox(width: AppDimensions.spacingMd),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Trailing widget
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
