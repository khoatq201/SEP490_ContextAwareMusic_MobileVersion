import 'package:flutter/material.dart';

/// CAMS color tokens.
///
/// The canonical palette is semantic and hybrid red-blue: red drives brand
/// actions, while blue is reserved for technology/data accents and Focus mood.
class AppColors {
  AppColors._();

  // ==========================================
  // LIGHT THEME - Brand and Surfaces
  // ==========================================
  static const Color lightBrandPrimary = Color(0xFFDC2626);
  static const Color lightBrandHover = Color(0xFFEF4444);
  static const Color lightBrandActive = Color(0xFFB91C1C);
  static const Color lightBrandSoft = Color(0xFFFEE2E2);

  static const Color lightTechAccent = Color(0xFF2563EB);
  static const Color lightTechAccentHover = Color(0xFF3B82F6);
  static const Color lightTechAccentSoft = Color(0xFFDBEAFE);

  static const Color lightBgBase = Color(0xFFFFFAFA);
  static const Color lightBgLayout = Color(0xFFFEF2F2);
  static const Color lightBgContainer = Color(0xFFFFFFFF);
  static const Color lightBgElevated = Color(0xFFFFFFFF);
  static const Color lightSidebar = Color(0xFFFFFFFF);

  static const Color lightTextPrimary = Color(0xFF181113);
  static const Color lightTextSecondary = Color(0xFF665A5F);
  static const Color lightTextTertiary = Color(0xFF8F8187);
  static const Color lightTextOnAccent = Color(0xFFFFFFFF);

  static const Color lightBorder = Color(0xFFEADADD);
  static const Color lightBorderSecondary = Color(0xFFF1E4E7);
  static const Color lightDivider = Color(0xFFF1E4E7);
  static const Color lightShadow = Color(0x1F7F1D1D);

  static const Color lightAlertErrorBg = Color(0xFFFEE2E2);
  static const Color lightAlertWarningBg = Color(0xFFFEF3C7);
  static const Color lightAlertSuccessBg = Color(0xFFDCFCE7);
  static const Color lightAlertInfoBg = Color(0xFFFFE4E6);
  static const Color lightTrackBg = Color(0xFFF1DFE3);
  static const Color lightTrackHover = Color(0xFFFECACA);

  // ==========================================
  // DARK THEME - Brand and Surfaces
  // ==========================================
  static const Color darkBrandPrimary = Color(0xFFEF4444);
  static const Color darkBrandHover = Color(0xFFF87171);
  static const Color darkBrandActive = Color(0xFFDC2626);
  static const Color darkBrandSoft = Color(0xFF2A1114);
  static const Color darkBrandMuted = Color(0xFF5B222B);

  static const Color darkTechAccent = Color(0xFF3B82F6);
  static const Color darkTechAccentHover = Color(0xFF60A5FA);
  static const Color darkTechAccentSoft = Color(0xFF172554);

  static const Color darkBgBase = Color(0xFF0F0F11);
  static const Color darkBgLayout = Color(0xFF0F0F11);
  static const Color darkBgContainer = Color(0xFF18181B);
  static const Color darkBgElevated = Color(0xFF202024);
  static const Color darkSidebar = Color(0xFF111113);

  static const Color darkTextPrimary = Color(0xFFF8F7F7);
  static const Color darkTextSecondary = Color(0xFFB7ADB0);
  static const Color darkTextTertiary = Color(0xFF857B80);
  static const Color darkTextOnAccent = Color(0xFFFFFFFF);

  static const Color darkBorder = Color(0xFF2D2528);
  static const Color darkBorderSecondary = Color(0xFF252528);
  static const Color darkDivider = Color(0xFF252528);
  static const Color darkShadow = Color(0x66000000);

  static const Color darkAlertErrorBg = Color(0xFF2A1114);
  static const Color darkAlertWarningBg = Color(0xFF261D0F);
  static const Color darkAlertSuccessBg = Color(0xFF102116);
  static const Color darkAlertInfoBg = Color(0xFF241519);
  static const Color darkTrackBg = Color(0xFF3B3034);
  static const Color darkTrackHover = Color(0xFF5B222B);

  // ==========================================
  // SEMANTIC STATE COLORS
  // ==========================================
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFF86EFAC);
  static const Color successDark = Color(0xFF16A34A);
  static const Color successPale = Color(0xFFDCFCE7);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFD97706);
  static const Color warningPale = Color(0xFFFEF3C7);

  static const Color error = lightBrandPrimary;
  static const Color errorLight = darkBrandHover;
  static const Color errorDark = lightBrandActive;
  static const Color errorPale = lightBrandSoft;

  static const Color info = lightBrandHover;
  static const Color infoLight = darkBrandHover;
  static const Color infoDark = darkBrandActive;
  static const Color infoPale = lightAlertInfoBg;

  // ==========================================
  // MOOD-SPECIFIC COLORS - Music Context
  // ==========================================
  static const Color moodCalm = Color(0xFF10B981);
  static const Color moodEnergetic = warning;
  static const Color moodFocus = darkTechAccent;
  static const Color moodSocial = Color(0xFF14B8A6);
  static const Color moodRomantic = Color(0xFFEC4899);
  static const Color moodUplifting = Color(0xFF8B5CF6);
  static const Color moodDefault = Color(0xFF818CF8);

  static const Color moodCalmGlow = Color(0x6610B981);
  static const Color moodEnergeticGlow = Color(0x66F59E0B);
  static const Color moodFocusGlow = Color(0x663B82F6);
  static const Color moodSocialGlow = Color(0x6614B8A6);
  static const Color moodRomanticGlow = Color(0x66EC4899);
  static const Color moodUpliftingGlow = Color(0x668B5CF6);
  static const Color moodDefaultGlow = Color(0x66818CF8);

  @Deprecated('Use moodCalm instead')
  static const Color moodChill = moodCalm;
  @Deprecated('Use moodCalmGlow instead')
  static const Color moodChillGlow = moodCalmGlow;

  // ==========================================
  // DEFAULT SEMANTIC ALIASES (LIGHT)
  // ==========================================
  static const Color brandPrimary = lightBrandPrimary;
  static const Color brandPrimaryHover = lightBrandHover;
  static const Color brandPrimaryActive = lightBrandActive;
  static const Color brandPrimarySoft = lightBrandSoft;
  static const Color techAccent = lightTechAccent;
  static const Color bgBase = lightBgBase;
  static const Color bgLayout = lightBgLayout;
  static const Color bgContainer = lightBgContainer;
  static const Color bgElevated = lightBgElevated;
  static const Color sidebar = lightSidebar;
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color textTertiary = lightTextTertiary;
  static const Color textInverse = lightTextOnAccent;
  static const Color textOnAccent = lightTextOnAccent;
  static const Color border = lightBorder;
  static const Color borderSecondary = lightBorderSecondary;
  static const Color divider = lightDivider;
  static const Color shadow = lightShadow;
  static const Color alertErrorBg = lightAlertErrorBg;
  static const Color alertWarningBg = lightAlertWarningBg;
  static const Color alertSuccessBg = lightAlertSuccessBg;
  static const Color alertInfoBg = lightAlertInfoBg;
  static const Color trackBg = lightTrackBg;
  static const Color trackHover = lightTrackHover;

  // ==========================================
  // LEGACY SUPPORT - remove after migration
  // ==========================================
  @Deprecated('Use brandPrimary instead')
  static const Color primaryOrange = lightBrandPrimary;
  @Deprecated('Use brandPrimaryActive instead')
  static const Color primaryOrangeDark = lightBrandActive;
  @Deprecated('Use brandPrimaryHover instead')
  static const Color primaryOrangeLight = lightBrandHover;
  @Deprecated('Use brandPrimarySoft instead')
  static const Color primaryOrangePale = lightBrandSoft;

  @Deprecated('Use techAccent instead')
  static const Color secondaryTeal = lightTechAccent;
  @Deprecated('Use lightTechAccent instead')
  static const Color secondaryTealDark = Color(0xFF1D4ED8);
  @Deprecated('Use lightTechAccentHover instead')
  static const Color secondaryTealLight = lightTechAccentHover;
  @Deprecated('Use lightTechAccentSoft instead')
  static const Color secondaryTealPale = lightTechAccentSoft;

  @Deprecated('Use bgBase instead')
  static const Color backgroundPrimary = lightBgBase;
  @Deprecated('Use bgLayout instead')
  static const Color backgroundSecondary = lightBgLayout;
  @Deprecated('Use borderSecondary or bgLayout instead')
  static const Color backgroundTertiary = lightBorderSecondary;
  @Deprecated('Use bgContainer instead')
  static const Color surface = lightBgContainer;
  @Deprecated('Use border instead')
  static const Color borderLight = lightBorder;
  @Deprecated('Use borderSecondary instead')
  static const Color borderMedium = lightBorderSecondary;
  @Deprecated('Use darkBorder instead')
  static const Color borderDark = darkBorder;

  @Deprecated('Use darkBrandPrimary instead')
  static const Color primaryCyan = darkBrandPrimary;
  @Deprecated('Use darkBrandHover instead')
  static const Color primaryCyanBright = darkBrandHover;
  @Deprecated('Use darkBrandMuted instead')
  static const Color primaryCyanMuted = darkBrandMuted;
  @Deprecated('Use darkBrandActive instead')
  static const Color primaryCyanDark = darkBrandActive;

  @Deprecated('Use darkTechAccent instead')
  static const Color secondaryLime = darkTechAccent;
  @Deprecated('Use darkTechAccentHover instead')
  static const Color secondaryLimeBright = darkTechAccentHover;
  @Deprecated('Use darkTechAccentSoft instead')
  static const Color secondaryLimeMuted = darkTechAccentSoft;
  @Deprecated('Use darkTechAccent instead')
  static const Color secondaryLimeDark = Color(0xFF1D4ED8);

  @Deprecated('Use darkBgBase instead')
  static const Color backgroundDarkPrimary = darkBgBase;
  @Deprecated('Use darkBgContainer instead')
  static const Color backgroundDarkSecondary = darkBgContainer;
  @Deprecated('Use darkBgElevated instead')
  static const Color backgroundDarkTertiary = darkBgElevated;
  @Deprecated('Use darkBgContainer instead')
  static const Color surfaceDark = darkBgContainer;
  @Deprecated('Use darkBgElevated instead')
  static const Color surfaceDarkElevated = darkBgElevated;
  @Deprecated('Use darkTextPrimary instead')
  static const Color textDarkPrimary = darkTextPrimary;
  @Deprecated('Use darkTextSecondary instead')
  static const Color textDarkSecondary = darkTextSecondary;
  @Deprecated('Use darkTextTertiary instead')
  static const Color textDarkTertiary = darkTextTertiary;
  @Deprecated('Use darkBorderSecondary instead')
  static const Color borderDarkLight = darkBorderSecondary;
  @Deprecated('Use darkBorder instead')
  static const Color borderDarkMedium = darkBorder;
  @Deprecated('Use darkBorder instead')
  static const Color borderDarkStrong = darkBorder;
  @Deprecated('Use darkDivider instead')
  static const Color dividerDark = darkDivider;
  @Deprecated('Use darkShadow instead')
  static const Color shadowDark = darkShadow;
  @Deprecated('Use success instead')
  static const Color successNeon = success;
  @Deprecated('Use warning instead')
  static const Color warningNeon = warning;
  @Deprecated('Use darkBrandPrimary instead')
  static const Color errorNeon = darkBrandPrimary;

  @Deprecated('Use brandPrimaryActive instead')
  static const Color darkOrange = lightBrandActive;
  @Deprecated('Use brandPrimaryHover instead')
  static const Color lightOrange = lightBrandHover;
  @Deprecated('Use brandPrimarySoft instead')
  static const Color paleOrange = lightBrandSoft;
  @Deprecated('Use textOnAccent instead')
  static const Color textLight = lightTextOnAccent;
  @Deprecated('Use textPrimary instead')
  static const Color textDark = lightTextPrimary;
  @Deprecated('Use bgBase instead')
  static const Color backgroundLight = lightBgBase;
  @Deprecated('Use darkBgBase instead')
  static const Color backgroundDark = darkBgBase;

  @Deprecated('Use moodUplifting instead')
  static const Color moodHappy = moodUplifting;
  @Deprecated('Use moodEnergetic instead')
  static const Color energeticColor = moodEnergetic;
  @Deprecated('Use moodFocus instead')
  static const Color focusColor = moodFocus;
  @Deprecated('Use moodCalm instead')
  static const Color chillColor = moodCalm;
  @Deprecated('Use moodUplifting instead')
  static const Color upliftingColor = moodUplifting;
  @Deprecated('Use moodCalm instead')
  static const Color moodRelaxed = moodCalm;
  @Deprecated('Use moodFocus instead')
  static const Color moodFocused = moodFocus;

  // ==========================================
  // UTILITY METHODS
  // ==========================================
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  static Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? textPrimary : textOnAccent;
  }

  static Color glassmorphism({double opacity = 0.2}) {
    return lightBgContainer.withValues(alpha: opacity);
  }

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

  static Color getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'calm':
      case 'chill':
      case 'relax':
      case 'relaxed':
        return moodCalm;
      case 'energetic':
      case 'energy':
        return moodEnergetic;
      case 'focus':
      case 'focused':
        return moodFocus;
      case 'social':
        return moodSocial;
      case 'romantic':
        return moodRomantic;
      case 'uplifting':
      case 'happy':
        return moodUplifting;
      default:
        return moodDefault;
    }
  }
}
