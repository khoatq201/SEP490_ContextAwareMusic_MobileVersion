import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/constants/app_colors.dart';
import 'package:cams_store_manager/core/theme/app_theme.dart';
import 'package:cams_store_manager/core/theme/cams_theme_tokens.dart';

void main() {
  group('CAMS theme tokens', () {
    test('light theme exposes hybrid red-blue tokens', () {
      final theme = AppTheme.lightTheme;
      final tokens = theme.extension<CamsThemeTokens>();

      expect(theme.brightness, Brightness.light);
      expect(tokens, isNotNull);
      expect(theme.colorScheme.primary, AppColors.lightBrandPrimary);
      expect(theme.colorScheme.secondary, AppColors.lightTechAccent);
      expect(theme.scaffoldBackgroundColor, AppColors.lightBgBase);
      expect(tokens!.brandPrimary, AppColors.lightBrandPrimary);
      expect(tokens.techAccent, AppColors.lightTechAccent);
      expect(tokens.bgBase, AppColors.lightBgBase);
      expect(tokens.bgContainer, AppColors.lightBgContainer);
      expect(tokens.alertErrorBg, AppColors.lightAlertErrorBg);
      expect(tokens.moodFocus, AppColors.lightTechAccent);
    });

    test('dark theme exposes red primary and dark surface stack', () {
      final theme = AppTheme.darkTheme;
      final tokens = theme.extension<CamsThemeTokens>();

      expect(theme.brightness, Brightness.dark);
      expect(tokens, isNotNull);
      expect(theme.colorScheme.primary, AppColors.darkBrandPrimary);
      expect(theme.colorScheme.secondary, AppColors.darkTechAccent);
      expect(theme.scaffoldBackgroundColor, AppColors.darkBgBase);
      expect(tokens!.brandPrimary, AppColors.darkBrandPrimary);
      expect(tokens.brandPrimaryHover, AppColors.darkBrandHover);
      expect(tokens.bgContainer, AppColors.darkBgContainer);
      expect(tokens.bgElevated, AppColors.darkBgElevated);
      expect(tokens.alertInfoBg, AppColors.darkAlertInfoBg);
      expect(tokens.moodFocus, AppColors.darkTechAccent);
    });
  });
}
