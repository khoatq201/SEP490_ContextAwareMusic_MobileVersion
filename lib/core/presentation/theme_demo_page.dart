import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../widgets/cams_button.dart';
import '../widgets/cams_logo.dart';
import '../widgets/theme_toggle.dart';

/// Theme Demo Page - Shows both light and dark themes
class ThemeDemoPage extends StatelessWidget {
  const ThemeDemoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CAMS Theme Demo'),
        actions: const [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: ThemeToggleSwitch(showLabel: false),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Theme Info Card
            const ThemeSelectorCard(),

            const SizedBox(height: AppDimensions.spacingXl),

            // Logo Demo
            Center(
              child: Column(
                children: [
                  Text(
                    'Theme-Aware Logo',
                    style: AppTypography.headlineSmall.copyWith(
                      color: isDark
                          ? AppColors.primaryCyan
                          : AppColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  const CAMSLogo(size: 150),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.spacingXxl),

            // Color Palette
            Text(
              'Color Palette',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            _buildColorGrid(isDark),

            const SizedBox(height: AppDimensions.spacingXxl),
          ],
        ),
      ),
      floatingActionButton: const ThemeToggleFAB(),
    );
  }

  Widget _buildColorGrid(bool isDark) {
    final colors = isDark
        ? [
            _ColorData('Primary Cyan', AppColors.primaryCyan),
            _ColorData('Cyan Bright', AppColors.primaryCyanBright),
            _ColorData('Secondary Lime', AppColors.secondaryLime),
            _ColorData('Lime Bright', AppColors.secondaryLimeBright),
            _ColorData('Success Neon', AppColors.successNeon),
            _ColorData('Warning Neon', AppColors.warningNeon),
            _ColorData('Error Neon', AppColors.errorNeon),
            _ColorData('Info', AppColors.info),
          ]
        : [
            _ColorData('Primary Orange', AppColors.primaryOrange),
            _ColorData('Orange Light', AppColors.primaryOrangeLight),
            _ColorData('Secondary Teal', AppColors.secondaryTeal),
            _ColorData('Teal Light', AppColors.secondaryTealLight),
            _ColorData('Success', AppColors.success),
            _ColorData('Warning', AppColors.warning),
            _ColorData('Error', AppColors.error),
            _ColorData('Info', AppColors.info),
          ];

    return Wrap(
      spacing: AppDimensions.spacingMd,
      runSpacing: AppDimensions.spacingMd,
      children: colors.map((colorData) {
        return Container(
          width: 100,
          padding: const EdgeInsets.all(AppDimensions.spacing8),
          decoration: BoxDecoration(
            color: colorData.color,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Text(
            colorData.name,
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? AppColors.backgroundDarkPrimary : Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
    );
  }
}

class _ColorData {
  final String name;
  final Color color;

  _ColorData(this.name, this.color);
}
