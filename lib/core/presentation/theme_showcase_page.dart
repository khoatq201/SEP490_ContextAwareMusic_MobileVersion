import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../widgets/cams_button.dart';
import '../widgets/cams_card.dart';

/// CAMS Theme Showcase - Demo all signature components
class CAMSThemeShowcase extends StatelessWidget {
  const CAMSThemeShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('CAMS Theme Showcase'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand Colors Section
            _buildSection(
              title: 'CAMS Brand Colors',
              subtitle:
                  'Retail Energy (Orange) + Technology Intelligence (Teal)',
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildColorSwatch(
                        'Primary Orange',
                        AppColors.primaryOrange,
                        AppColors.primaryOrangeLight,
                        AppColors.primaryOrangePale,
                      ),
                      const SizedBox(width: AppDimensions.spacingMd),
                      _buildColorSwatch(
                        'Secondary Teal',
                        AppColors.secondaryTeal,
                        AppColors.secondaryTealLight,
                        AppColors.secondaryTealPale,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.spacingXl),

            // Buttons Showcase
            _buildSection(
              title: 'CAMS Buttons',
              subtitle: 'All button variants with Orange & Teal',
              child: Wrap(
                spacing: AppDimensions.spacingMd,
                runSpacing: AppDimensions.spacingMd,
                children: [
                  // Primary Orange
                  CAMSButton(
                    text: 'Primary Orange',
                    onPressed: () {},
                    variant: CAMSButtonVariant.primary,
                  ),

                  // Teal Button
                  CAMSButton(
                    text: 'Technology Teal',
                    onPressed: () {},
                    variant: CAMSButtonVariant.teal,
                    icon: Icons.sensors,
                  ),

                  // Secondary
                  CAMSButton(
                    text: 'Secondary',
                    onPressed: () {},
                    variant: CAMSButtonVariant.secondary,
                  ),

                  // Outlined
                  CAMSButton(
                    text: 'Outlined',
                    onPressed: () {},
                    variant: CAMSButtonVariant.outlined,
                  ),

                  // Outlined Teal
                  CAMSButton(
                    text: 'Outlined Teal',
                    onPressed: () {},
                    variant: CAMSButtonVariant.outlined,
                    customColor: AppColors.secondaryTeal,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.spacingXl),

            // Cards Showcase
            _buildSection(
              title: 'CAMS Cards',
              subtitle: 'Minimal solid & outlined styles',
              child: const Column(
                children: [
                  // Standard Solid Card
                  CAMSCard(
                    child: Padding(
                      padding: EdgeInsets.all(AppDimensions.spacingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.store, color: AppColors.primaryOrange),
                              SizedBox(width: AppDimensions.spacing8),
                              Text('Store Status',
                                  style: AppTypography.titleMedium),
                            ],
                          ),
                          SizedBox(height: AppDimensions.spacing8),
                          Text(
                            'Solid card with standard style',
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: AppDimensions.spacingMd),

                  // Outlined Card
                  CAMSCard(
                    variant: CAMSCardVariant.outlined,
                    child: Padding(
                      padding: EdgeInsets.all(AppDimensions.spacingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shopping_cart,
                                  color: AppColors.primaryOrange),
                              SizedBox(width: AppDimensions.spacing8),
                              Text('Retail Activity',
                                  style: AppTypography.titleMedium),
                            ],
                          ),
                          SizedBox(height: AppDimensions.spacing8),
                          Text(
                            'Card with border outline',
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.spacingXl),

            // Semantic Colors
            _buildSection(
              title: 'Semantic State Colors',
              subtitle: 'Dashboard status indicators',
              child: Wrap(
                spacing: AppDimensions.spacingMd,
                runSpacing: AppDimensions.spacingMd,
                children: [
                  _buildStatusChip('Online', AppColors.success),
                  _buildStatusChip('Warning', AppColors.warning),
                  _buildStatusChip('Offline', AppColors.error),
                  _buildStatusChip('Info', AppColors.info),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.spacingXxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.headlineSmall),
        const SizedBox(height: AppDimensions.spacing4),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        child,
      ],
    );
  }

  Widget _buildColorSwatch(
    String label,
    Color primary,
    Color light,
    Color pale,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
          const SizedBox(height: AppDimensions.spacing4),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: light,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacing4),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: pale,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text(label, style: AppTypography.labelSmall),
        ],
      ),
    );
  }

  Widget _buildGradientBox(String label, Gradient gradient) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTypography.titleMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacing8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppDimensions.spacing8),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
