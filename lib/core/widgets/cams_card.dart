import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

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
    Key? key,
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            color: Colors.white,
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
        decoration: _buildDecoration(),
        child: child,
      );
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          splashColor: AppColors.primaryOrange.withOpacity(0.1),
          highlightColor: AppColors.primaryOrange.withOpacity(0.05),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  BoxDecoration _buildDecoration() {
    switch (variant) {
      case CAMSCardVariant.solid:
        return _solidDecoration();
      case CAMSCardVariant.outlined:
        return _outlinedDecoration();
      default:
        return _solidDecoration();
    }
  }

  BoxDecoration _solidDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      border: showBorder
          ? Border.all(
              color: Colors.grey.shade200,
              width: AppDimensions.borderWidthNormal,
            )
          : null,
      boxShadow: showShadow
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ]
          : null,
    );
  }

  BoxDecoration _outlinedDecoration() {
    return BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      border: Border.all(
        color: AppColors.primaryOrange,
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
    Key? key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    this.iconColor,
    this.valueColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              color: (iconColor ?? AppColors.primaryOrange).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(
              icon,
              size: AppDimensions.iconLg,
              color: iconColor ?? AppColors.primaryOrange,
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
                      color: valueColor ?? AppColors.primaryOrange,
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
                        color: Colors.grey.shade600,
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
                  color: Colors.grey.shade700,
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
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor,
    this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CAMSCard(
      variant: CAMSCardVariant.solid,
      onTap: onTap,
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacing12),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primaryOrange).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(
              icon,
              size: AppDimensions.iconLg,
              color: iconColor ?? AppColors.primaryOrange,
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
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
