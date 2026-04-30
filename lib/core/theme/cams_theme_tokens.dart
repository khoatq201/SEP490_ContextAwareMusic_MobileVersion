import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

@immutable
class CamsThemeTokens extends ThemeExtension<CamsThemeTokens> {
  const CamsThemeTokens({
    required this.bgBase,
    required this.bgLayout,
    required this.bgContainer,
    required this.bgElevated,
    required this.sidebar,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnAccent,
    required this.brandPrimary,
    required this.brandPrimaryHover,
    required this.brandPrimaryActive,
    required this.brandPrimarySoft,
    required this.techAccent,
    required this.techAccentHover,
    required this.techAccentSoft,
    required this.border,
    required this.borderSecondary,
    required this.divider,
    required this.shadow,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.alertErrorBg,
    required this.alertWarningBg,
    required this.alertSuccessBg,
    required this.alertInfoBg,
    required this.trackBg,
    required this.trackHover,
    required this.moodChill,
    required this.moodFocus,
    required this.moodEnergetic,
    required this.moodDefault,
    required this.moodChillGlow,
    required this.moodFocusGlow,
    required this.moodEnergeticGlow,
    required this.moodDefaultGlow,
  });

  final Color bgBase;
  final Color bgLayout;
  final Color bgContainer;
  final Color bgElevated;
  final Color sidebar;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnAccent;
  final Color brandPrimary;
  final Color brandPrimaryHover;
  final Color brandPrimaryActive;
  final Color brandPrimarySoft;
  final Color techAccent;
  final Color techAccentHover;
  final Color techAccentSoft;
  final Color border;
  final Color borderSecondary;
  final Color divider;
  final Color shadow;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color alertErrorBg;
  final Color alertWarningBg;
  final Color alertSuccessBg;
  final Color alertInfoBg;
  final Color trackBg;
  final Color trackHover;
  final Color moodChill;
  final Color moodFocus;
  final Color moodEnergetic;
  final Color moodDefault;
  final Color moodChillGlow;
  final Color moodFocusGlow;
  final Color moodEnergeticGlow;
  final Color moodDefaultGlow;

  static const CamsThemeTokens light = CamsThemeTokens(
    bgBase: AppColors.lightBgBase,
    bgLayout: AppColors.lightBgLayout,
    bgContainer: AppColors.lightBgContainer,
    bgElevated: AppColors.lightBgElevated,
    sidebar: AppColors.lightSidebar,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textTertiary: AppColors.lightTextTertiary,
    textOnAccent: AppColors.lightTextOnAccent,
    brandPrimary: AppColors.lightBrandPrimary,
    brandPrimaryHover: AppColors.lightBrandHover,
    brandPrimaryActive: AppColors.lightBrandActive,
    brandPrimarySoft: AppColors.lightBrandSoft,
    techAccent: AppColors.lightTechAccent,
    techAccentHover: AppColors.lightTechAccentHover,
    techAccentSoft: AppColors.lightTechAccentSoft,
    border: AppColors.lightBorder,
    borderSecondary: AppColors.lightBorderSecondary,
    divider: AppColors.lightDivider,
    shadow: AppColors.lightShadow,
    success: AppColors.success,
    warning: AppColors.warningDark,
    error: AppColors.lightBrandPrimary,
    info: AppColors.lightBrandHover,
    alertErrorBg: AppColors.lightAlertErrorBg,
    alertWarningBg: AppColors.lightAlertWarningBg,
    alertSuccessBg: AppColors.lightAlertSuccessBg,
    alertInfoBg: AppColors.lightAlertInfoBg,
    trackBg: AppColors.lightTrackBg,
    trackHover: AppColors.lightTrackHover,
    moodChill: AppColors.moodChill,
    moodFocus: AppColors.lightTechAccent,
    moodEnergetic: AppColors.moodEnergetic,
    moodDefault: AppColors.moodDefault,
    moodChillGlow: AppColors.moodChillGlow,
    moodFocusGlow: AppColors.moodFocusGlow,
    moodEnergeticGlow: AppColors.moodEnergeticGlow,
    moodDefaultGlow: AppColors.moodDefaultGlow,
  );

  static const CamsThemeTokens dark = CamsThemeTokens(
    bgBase: AppColors.darkBgBase,
    bgLayout: AppColors.darkBgLayout,
    bgContainer: AppColors.darkBgContainer,
    bgElevated: AppColors.darkBgElevated,
    sidebar: AppColors.darkSidebar,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: AppColors.darkTextTertiary,
    textOnAccent: AppColors.darkTextOnAccent,
    brandPrimary: AppColors.darkBrandPrimary,
    brandPrimaryHover: AppColors.darkBrandHover,
    brandPrimaryActive: AppColors.darkBrandActive,
    brandPrimarySoft: AppColors.darkBrandSoft,
    techAccent: AppColors.darkTechAccent,
    techAccentHover: AppColors.darkTechAccentHover,
    techAccentSoft: AppColors.darkTechAccentSoft,
    border: AppColors.darkBorder,
    borderSecondary: AppColors.darkBorderSecondary,
    divider: AppColors.darkDivider,
    shadow: AppColors.darkShadow,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.darkBrandPrimary,
    info: AppColors.darkBrandHover,
    alertErrorBg: AppColors.darkAlertErrorBg,
    alertWarningBg: AppColors.darkAlertWarningBg,
    alertSuccessBg: AppColors.darkAlertSuccessBg,
    alertInfoBg: AppColors.darkAlertInfoBg,
    trackBg: AppColors.darkTrackBg,
    trackHover: AppColors.darkTrackHover,
    moodChill: AppColors.moodChill,
    moodFocus: AppColors.darkTechAccent,
    moodEnergetic: AppColors.moodEnergetic,
    moodDefault: AppColors.moodDefault,
    moodChillGlow: AppColors.moodChillGlow,
    moodFocusGlow: AppColors.moodFocusGlow,
    moodEnergeticGlow: AppColors.moodEnergeticGlow,
    moodDefaultGlow: AppColors.moodDefaultGlow,
  );

  @override
  CamsThemeTokens copyWith({
    Color? bgBase,
    Color? bgLayout,
    Color? bgContainer,
    Color? bgElevated,
    Color? sidebar,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textOnAccent,
    Color? brandPrimary,
    Color? brandPrimaryHover,
    Color? brandPrimaryActive,
    Color? brandPrimarySoft,
    Color? techAccent,
    Color? techAccentHover,
    Color? techAccentSoft,
    Color? border,
    Color? borderSecondary,
    Color? divider,
    Color? shadow,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? alertErrorBg,
    Color? alertWarningBg,
    Color? alertSuccessBg,
    Color? alertInfoBg,
    Color? trackBg,
    Color? trackHover,
    Color? moodChill,
    Color? moodFocus,
    Color? moodEnergetic,
    Color? moodDefault,
    Color? moodChillGlow,
    Color? moodFocusGlow,
    Color? moodEnergeticGlow,
    Color? moodDefaultGlow,
  }) {
    return CamsThemeTokens(
      bgBase: bgBase ?? this.bgBase,
      bgLayout: bgLayout ?? this.bgLayout,
      bgContainer: bgContainer ?? this.bgContainer,
      bgElevated: bgElevated ?? this.bgElevated,
      sidebar: sidebar ?? this.sidebar,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textOnAccent: textOnAccent ?? this.textOnAccent,
      brandPrimary: brandPrimary ?? this.brandPrimary,
      brandPrimaryHover: brandPrimaryHover ?? this.brandPrimaryHover,
      brandPrimaryActive: brandPrimaryActive ?? this.brandPrimaryActive,
      brandPrimarySoft: brandPrimarySoft ?? this.brandPrimarySoft,
      techAccent: techAccent ?? this.techAccent,
      techAccentHover: techAccentHover ?? this.techAccentHover,
      techAccentSoft: techAccentSoft ?? this.techAccentSoft,
      border: border ?? this.border,
      borderSecondary: borderSecondary ?? this.borderSecondary,
      divider: divider ?? this.divider,
      shadow: shadow ?? this.shadow,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      alertErrorBg: alertErrorBg ?? this.alertErrorBg,
      alertWarningBg: alertWarningBg ?? this.alertWarningBg,
      alertSuccessBg: alertSuccessBg ?? this.alertSuccessBg,
      alertInfoBg: alertInfoBg ?? this.alertInfoBg,
      trackBg: trackBg ?? this.trackBg,
      trackHover: trackHover ?? this.trackHover,
      moodChill: moodChill ?? this.moodChill,
      moodFocus: moodFocus ?? this.moodFocus,
      moodEnergetic: moodEnergetic ?? this.moodEnergetic,
      moodDefault: moodDefault ?? this.moodDefault,
      moodChillGlow: moodChillGlow ?? this.moodChillGlow,
      moodFocusGlow: moodFocusGlow ?? this.moodFocusGlow,
      moodEnergeticGlow: moodEnergeticGlow ?? this.moodEnergeticGlow,
      moodDefaultGlow: moodDefaultGlow ?? this.moodDefaultGlow,
    );
  }

  @override
  CamsThemeTokens lerp(ThemeExtension<CamsThemeTokens>? other, double t) {
    if (other is! CamsThemeTokens) return this;
    Color lerpColor(Color a, Color b) => Color.lerp(a, b, t) ?? b;

    return CamsThemeTokens(
      bgBase: lerpColor(bgBase, other.bgBase),
      bgLayout: lerpColor(bgLayout, other.bgLayout),
      bgContainer: lerpColor(bgContainer, other.bgContainer),
      bgElevated: lerpColor(bgElevated, other.bgElevated),
      sidebar: lerpColor(sidebar, other.sidebar),
      textPrimary: lerpColor(textPrimary, other.textPrimary),
      textSecondary: lerpColor(textSecondary, other.textSecondary),
      textTertiary: lerpColor(textTertiary, other.textTertiary),
      textOnAccent: lerpColor(textOnAccent, other.textOnAccent),
      brandPrimary: lerpColor(brandPrimary, other.brandPrimary),
      brandPrimaryHover: lerpColor(brandPrimaryHover, other.brandPrimaryHover),
      brandPrimaryActive:
          lerpColor(brandPrimaryActive, other.brandPrimaryActive),
      brandPrimarySoft: lerpColor(brandPrimarySoft, other.brandPrimarySoft),
      techAccent: lerpColor(techAccent, other.techAccent),
      techAccentHover: lerpColor(techAccentHover, other.techAccentHover),
      techAccentSoft: lerpColor(techAccentSoft, other.techAccentSoft),
      border: lerpColor(border, other.border),
      borderSecondary: lerpColor(borderSecondary, other.borderSecondary),
      divider: lerpColor(divider, other.divider),
      shadow: lerpColor(shadow, other.shadow),
      success: lerpColor(success, other.success),
      warning: lerpColor(warning, other.warning),
      error: lerpColor(error, other.error),
      info: lerpColor(info, other.info),
      alertErrorBg: lerpColor(alertErrorBg, other.alertErrorBg),
      alertWarningBg: lerpColor(alertWarningBg, other.alertWarningBg),
      alertSuccessBg: lerpColor(alertSuccessBg, other.alertSuccessBg),
      alertInfoBg: lerpColor(alertInfoBg, other.alertInfoBg),
      trackBg: lerpColor(trackBg, other.trackBg),
      trackHover: lerpColor(trackHover, other.trackHover),
      moodChill: lerpColor(moodChill, other.moodChill),
      moodFocus: lerpColor(moodFocus, other.moodFocus),
      moodEnergetic: lerpColor(moodEnergetic, other.moodEnergetic),
      moodDefault: lerpColor(moodDefault, other.moodDefault),
      moodChillGlow: lerpColor(moodChillGlow, other.moodChillGlow),
      moodFocusGlow: lerpColor(moodFocusGlow, other.moodFocusGlow),
      moodEnergeticGlow: lerpColor(moodEnergeticGlow, other.moodEnergeticGlow),
      moodDefaultGlow: lerpColor(moodDefaultGlow, other.moodDefaultGlow),
    );
  }
}

extension CamsThemeContext on BuildContext {
  CamsThemeTokens get camsTokens =>
      Theme.of(this).extension<CamsThemeTokens>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? CamsThemeTokens.dark
          : CamsThemeTokens.light);
}
