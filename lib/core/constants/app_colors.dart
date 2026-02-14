import 'package:flutter/material.dart';

/// CAMS Theme Colors - Adaptive Retail Hub
/// Based on: Retail Energy (Orange) + Technology Intelligence (Teal)
/// Inspired by CAMS logo design
class AppColors {
  // ==========================================
  // PRIMARY BRAND - Professional Blue
  // ==========================================
  static const Color primaryOrange = Color(0xFF2196F3); // Professional blue
  static const Color primaryOrangeDark =
      Color(0xFF1976D2); // Darker for pressed states
  static const Color primaryOrangeLight =
      Color(0xFF64B5F6); // Lighter for hover states
  static const Color primaryOrangePale =
      Color(0xFFBBDEFB); // Very light for backgrounds

  // ==========================================
  // SECONDARY BRAND - Technology Intelligence (Teal)
  // ==========================================
  static const Color secondaryTeal = Color(0xFF26A69A); // Deep teal from logo
  static const Color secondaryTealDark = Color(0xFF00897B); // Darker teal
  static const Color secondaryTealLight = Color(0xFF4DB6AC); // Lighter teal
  static const Color secondaryTealPale =
      Color(0xFFB2DFDB); // Very light for backgrounds

  // ==========================================
  // NEUTRAL COLORS - Professional Grayscale
  // ==========================================
  static const Color backgroundPrimary =
      Color(0xFFFAFAFA); // Very clean light gray, not pure white
  static const Color backgroundSecondary =
      Color(0xFFF5F5F5); // Slightly darker for cards
  static const Color backgroundTertiary =
      Color(0xFFEEEEEE); // For subtle distinctions
  static const Color surface =
      Color(0xFFFFFFFF); // Pure white for elevated cards

  static const Color textPrimary =
      Color(0xFF212121); // Deep charcoal, not pure black
  static const Color textSecondary =
      Color(0xFF424242); // Medium gray for secondary text
  static const Color textTertiary =
      Color(0xFF757575); // Light gray for hints/disabled
  static const Color textInverse =
      Color(0xFFFFFFFF); // White text on dark backgrounds

  static const Color borderLight = Color(0xFFE0E0E0); // Light borders
  static const Color borderMedium = Color(0xFFBDBDBD); // Medium borders
  static const Color borderDark = Color(0xFF9E9E9E); // Dark borders

  static const Color divider = Color(0xFFEEEEEE); // Divider lines
  static const Color shadow = Color(0x1A000000); // 10% black for shadows

  // ==========================================
  // SEMANTIC STATE COLORS - Dashboard Status
  // ==========================================
  static const Color success =
      Color(0xFF4CAF50); // Positive green - Online/Success
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);
  static const Color successPale = Color(0xFFC8E6C9);

  static const Color warning =
      Color(0xFFFFA726); // Amber/Yellow - distinct from orange
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFFB8C00);
  static const Color warningPale = Color(0xFFFFE0B2);

  static const Color error = Color(0xFFF44336); // Clear red - Error/Offline
  static const Color errorLight = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFD32F2F);
  static const Color errorPale = Color(0xFFFFCDD2);

  static const Color info = Color(0xFF2196F3); // Blue for informational states
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoDark = Color(0xFF1976D2);
  static const Color infoPale = Color(0xFFBBDEFB);

  // ==========================================
  // DARK MODE COLORS - Minimalist Digital Pulse
  // ==========================================

  // PRIMARY ACCENT - Electric Cyan (Dark Mode)
  static const Color primaryCyan =
      Color(0xFF00E5FF); // Electric Cyan - Main accent
  static const Color primaryCyanBright =
      Color(0xFF84FFFF); // Brighter for hover/glow
  static const Color primaryCyanMuted =
      Color(0xFF00838F); // Muted for subtle elements
  static const Color primaryCyanDark = Color(0xFF006064); // Dark variant

  // SECONDARY ACCENT - Neon Lime (Dark Mode)
  static const Color secondaryLime = Color(0xFFCDDC39); // Neon Lime Green
  static const Color secondaryLimeBright = Color(0xFFF4FF81); // Brighter lime
  static const Color secondaryLimeMuted = Color(0xFF9E9D24); // Muted lime
  static const Color secondaryLimeDark = Color(0xFF827717); // Dark lime

  // DARK BACKGROUNDS - Deep Space
  static const Color backgroundDarkPrimary =
      Color(0xFF0A1929); // Deep charcoal, almost black
  static const Color backgroundDarkSecondary =
      Color(0xFF121212); // Slightly lighter for cards
  static const Color backgroundDarkTertiary =
      Color(0xFF1E1E1E); // Elevated surfaces
  static const Color surfaceDark = Color(0xFF1A1A1A); // Card surfaces
  static const Color surfaceDarkElevated = Color(0xFF242424); // Elevated cards

  // DARK MODE TYPOGRAPHY
  static const Color textDarkPrimary = Color(0xFFFFFFFF); // Pure white
  static const Color textDarkSecondary = Color(0xFFB0BEC5); // Mid-tone gray
  static const Color textDarkTertiary = Color(0xFF78909C); // Light gray hints

  // DARK MODE BORDERS
  static const Color borderDarkLight = Color(0xFF263238); // Subtle dark border
  static const Color borderDarkMedium = Color(0xFF37474F); // Medium border
  static const Color borderDarkStrong = Color(0xFF455A64); // Stronger border
  static const Color dividerDark = Color(0xFF1E2830); // Divider lines
  static const Color shadowDark =
      Color(0x40000000); // 25% black for glow shadows

  // NEON STATE COLORS (Dark Mode)
  static const Color successNeon = Color(0xFF00E676); // Neon Green
  static const Color warningNeon = Color(0xFFFFEA00); // Electric Yellow
  static const Color errorNeon = Color(0xFFFF1744); // Hot Neon Red/Magenta

  // ==========================================
  // GRADIENTS - Signature CAMS Gradients (COMMENTED OUT FOR MINIMAL THEME)
  // ==========================================

  /* GRADIENTS DISABLED FOR MINIMAL THEME
  // Primary Orange Gradient (Retail Energy)
  static const List<Color> primaryGradient = [
    primaryOrange,
    primaryOrangeDark,
  ];

  // Secondary Teal Gradient (Technology Intelligence)
  static const List<Color> secondaryGradient = [
    secondaryTeal,
    secondaryTealDark,
  ];

  // Signature CAMS Gradient (Orange to Teal - represents fusion of retail & tech)
  static const List<Color> signatureGradient = [
    primaryOrange,
    Color(0xFFFF8A65), // Mid orange
    secondaryTealLight,
    secondaryTeal,
  ];

  // Adaptive gradient (Teal to Orange - reverse flow)
  static const List<Color> adaptiveGradient = [
    secondaryTeal,
    secondaryTealLight,
    primaryOrangeLight,
    primaryOrange,
  ];

  // Digital Pulse Gradient (Cyan to Lime - Dark Mode signature)
  static const List<Color> digitalPulseGradient = [
    primaryCyan,
    Color(0xFF00D4E5), // Mid cyan
    Color(0xFF7ED321), // Mid lime
    secondaryLime,
  ];

  // Neon Cyan Gradient (Dark Mode primary)
  static const List<Color> neonCyanGradient = [
    primaryCyan,
    primaryCyanBright,
  ];

  // Neon Lime Gradient (Dark Mode secondary)
  static const List<Color> neonLimeGradient = [
    secondaryLime,
    secondaryLimeBright,
  ];

  // Glow Colors for Effects
  static const List<Color> glowCyan = [
    Color(0x00FFFFFF),
    primaryCyan,
    Color(0x00FFFFFF),
  ];

  static const List<Color> glowLime = [
    Color(0x00FFFFFF),
    secondaryLime,
    Color(0x00FFFFFF),
  ];
  */

  // ==========================================
  // MOOD-SPECIFIC COLORS - Music Context
  // ==========================================
  static const Color energeticColor = primaryOrange; // Retail energy - Orange
  static const Color focusColor = secondaryTeal; // Technology focus - Teal
  static const Color chillColor =
      Color(0xFF4DD0E1); // Relaxation - Cyan (lighter teal)
  static const Color upliftingColor =
      Color(0xFFFFD54F); // Positivity - Golden yellow

  // ==========================================
  // LEGACY SUPPORT (Deprecated - use new names)
  // ==========================================
  @Deprecated('Use primaryOrangeDark instead')
  static const Color darkOrange = primaryOrangeDark;

  @Deprecated('Use primaryOrangeLight instead')
  static const Color lightOrange = primaryOrangeLight;

  @Deprecated('Use primaryOrangePale instead')
  static const Color paleOrange = primaryOrangePale;

  @Deprecated('Use textInverse instead')
  static const Color textLight = textInverse;

  @Deprecated('Use textPrimary instead')
  static const Color textDark = textPrimary;

  @Deprecated('Use backgroundPrimary instead')
  static const Color backgroundLight = backgroundPrimary;

  @Deprecated('Use backgroundPrimary instead')
  static const Color backgroundDark = Color(0xFF303030);

  @Deprecated('Use borderLight instead')
  static const Color border = borderLight;

  // Legacy mood colors (deprecated - use new scheme)
  @Deprecated('Use upliftingColor instead')
  static const Color moodHappy = upliftingColor;

  @Deprecated('Use energeticColor instead')
  static const Color moodEnergetic = energeticColor;

  @Deprecated('Use success instead')
  static const Color moodRelaxed = success;

  @Deprecated('Use chillColor instead')
  static const Color moodChill = chillColor;

  @Deprecated('Use focusColor instead')
  static const Color moodFocused = focusColor;

  // ==========================================
  // GRADIENT GETTERS - Ready-to-use gradients (COMMENTED OUT FOR MINIMAL THEME)
  // ==========================================

  /* GRADIENT GETTERS DISABLED FOR MINIMAL THEME
  static LinearGradient get primaryLinearGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: primaryGradient,
      );

  static LinearGradient get secondaryLinearGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: secondaryGradient,
      );

  static LinearGradient get signatureLinearGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: signatureGradient,
      );

  static LinearGradient get adaptiveLinearGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: adaptiveGradient,
      );

  static RadialGradient get primaryRadialGradient => const RadialGradient(
        colors: primaryGradient,
        center: Alignment.center,
        radius: 1.0,
      );

  static RadialGradient get signatureRadialGradient => const RadialGradient(
        colors: signatureGradient,
        center: Alignment.center,
        radius: 1.2,
      );

  // Dark Mode Gradients
  static LinearGradient get digitalPulseLinearGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: digitalPulseGradient,
      );

  static LinearGradient get neonCyanLinearGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: neonCyanGradient,
      );

  static LinearGradient get neonLimeLinearGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: neonLimeGradient,
      );

  static RadialGradient get glowCyanRadialGradient => const RadialGradient(
        colors: glowCyan,
        center: Alignment.center,
        radius: 1.0,
      );

  static RadialGradient get glowLimeRadialGradient => const RadialGradient(
        colors: glowLime,
        center: Alignment.center,
        radius: 1.0,
      );
  */

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  /// Get color with custom opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Get appropriate text color for background (contrast)
  static Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? textPrimary : textInverse;
  }

  /// Create glassmorphism effect color
  static Color glassmorphism({double opacity = 0.2}) {
    return Colors.white.withOpacity(opacity);
  }

  /// Get status color by name
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'online':
      case 'active':
        return success;
      case 'warning':
      case 'issues':
        return warning;
      case 'error':
      case 'offline':
      case 'inactive':
        return error;
      case 'info':
      default:
        return info;
    }
  }

  /// Get mood color by name
  static Color getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'energetic':
      case 'energy':
        return energeticColor;
      case 'focus':
      case 'focused':
        return focusColor;
      case 'chill':
      case 'relax':
        return chillColor;
      case 'uplifting':
      case 'happy':
        return upliftingColor;
      default:
        return primaryOrange;
    }
  }
}
