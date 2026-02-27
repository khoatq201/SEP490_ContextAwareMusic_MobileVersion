import 'package:flutter/material.dart';
import 'app_colors.dart';

/// CAMS Typography System - Signature text styles for brand consistency
class AppTypography {
  // Font families
  static const String primaryFont = 'Roboto'; // Default Flutter font
  static const String displayFont = 'Roboto'; // Can be changed to custom font

  // ========================================
  // Display Styles (For large headings)
  // ========================================

  static const TextStyle displayLarge = TextStyle(
    fontFamily: displayFont,
    fontSize: 57,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: displayFont,
    fontSize: 45,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.16,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: displayFont,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.22,
  );

  // ========================================
  // Headline Styles
  // ========================================

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
  );

  // ========================================
  // Title Styles
  // ========================================

  static const TextStyle titleLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // ========================================
  // Body Styles
  // ========================================

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // ========================================
  // Label Styles (For buttons, chips, etc.)
  // ========================================

  static const TextStyle labelLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // ========================================
  // CAMS Signature Styles
  // ========================================

  /// Brand logo text style with distinctive look
  static TextStyle brand = TextStyle(
    fontFamily: displayFont,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.0,
    color: AppColors.primaryOrange,
    shadows: [
      Shadow(
        color: AppColors.primaryOrange.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  /// Gradient text style for special headings
  static const TextStyle gradientHeading = TextStyle(
    fontFamily: displayFont,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    height: 1.2,
  );

  /// Button text with uppercase and spacing
  static const TextStyle button = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    height: 1.0,
  );

  /// Sensor value display (large numbers)
  static TextStyle sensorValue = const TextStyle(
    fontFamily: displayFont,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    color: AppColors.primaryOrange,
    height: 1.0,
  );

  /// Small caption with opacity
  static TextStyle caption = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: Colors.grey.shade600,
    height: 1.33,
  );

  /// Emphasized text for important info
  static TextStyle emphasized = const TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: AppColors.primaryOrange,
    height: 1.5,
  );

  // ========================================
  // Helper Methods
  // ========================================

  /// Apply gradient to text (requires shader mask)
  static TextStyle withGradient(TextStyle baseStyle, Gradient gradient) {
    return baseStyle;
  }

  /// Apply color to any style
  static TextStyle withColor(TextStyle baseStyle, Color color) {
    return baseStyle.copyWith(color: color);
  }

  /// Apply shadow effect
  static TextStyle withShadow(
    TextStyle baseStyle, {
    Color? shadowColor,
    double blurRadius = 8,
    Offset offset = const Offset(0, 2),
  }) {
    return baseStyle.copyWith(
      shadows: [
        Shadow(
          color: (shadowColor ?? AppColors.primaryOrange).withOpacity(0.3),
          blurRadius: blurRadius,
          offset: offset,
        ),
      ],
    );
  }
}
