import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../widgets/cams_button.dart';
import '../widgets/cams_card.dart';

/// Demo page to showcase all CAMS signature components
class ComponentShowcasePage extends StatelessWidget {
  const ComponentShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CAMS Component Showcase'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.paleOrange.withOpacity(0.3),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Typography Section
              _buildSection(
                'Typography',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Display Large',
                        style: AppTypography.displayLarge),
                    const SizedBox(height: 8),
                    const Text('Headline Large',
                        style: AppTypography.headlineLarge),
                    const SizedBox(height: 8),
                    const Text('Title Large', style: AppTypography.titleLarge),
                    const SizedBox(height: 8),
                    const Text('Body Large', style: AppTypography.bodyLarge),
                    const SizedBox(height: 8),
                    Text(
                      'CAMS Brand',
                      style: AppTypography.brand.copyWith(
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXxl),

              // Buttons Section
              _buildSection(
                'Buttons',
                Column(
                  children: [
                    CAMSButton(
                      text: 'Primary Button',
                      onPressed: () {},
                      isFullWidth: true,
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    CAMSButton(
                      text: 'Secondary Button',
                      variant: CAMSButtonVariant.secondary,
                      onPressed: () {},
                      isFullWidth: true,
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    CAMSButton(
                      text: 'Outlined Button',
                      variant: CAMSButtonVariant.outlined,
                      onPressed: () {},
                      isFullWidth: true,
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    CAMSButton(
                      text: 'Text Button',
                      variant: CAMSButtonVariant.text,
                      onPressed: () {},
                      isFullWidth: true,
                      icon: Icons.star,
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CAMSButton(
                          text: 'Small',
                          size: CAMSButtonSize.small,
                          onPressed: () {},
                        ),
                        CAMSButton(
                          text: 'Medium',
                          size: CAMSButtonSize.medium,
                          onPressed: () {},
                        ),
                        CAMSButton(
                          text: 'Large',
                          size: CAMSButtonSize.large,
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CAMSIconButton(
                          icon: Icons.favorite,
                          onPressed: () {},
                          hasShadow: true,
                        ),
                        CAMSIconButton(
                          icon: Icons.share,
                          onPressed: () {},
                          backgroundColor: AppColors.secondaryTeal,
                          hasShadow: true,
                        ),
                        CAMSIconButton(
                          icon: Icons.settings,
                          onPressed: () {},
                          backgroundColor: AppColors.moodEnergetic,
                          hasShadow: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXxl),

              // Cards Section
              _buildSection(
                'Cards',
                const Column(
                  children: [
                    CAMSCard(
                      variant: CAMSCardVariant.solid,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solid Card',
                            style: AppTypography.titleMedium,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'This card has a solid background with minimal shadow.',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppDimensions.spacingMd),
                    CAMSCard(
                      variant: CAMSCardVariant.outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Outlined Card',
                            style: AppTypography.titleMedium,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Card with border outline.',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppDimensions.spacingMd),
                    CAMSCard(
                      variant: CAMSCardVariant.outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Outlined Card',
                            style: AppTypography.titleMedium,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Card with orange border only.',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXxl),

              // Sensor Cards
              _buildSection(
                'Sensor Cards',
                const Wrap(
                  spacing: AppDimensions.spacingMd,
                  runSpacing: AppDimensions.spacingMd,
                  children: [
                    CAMSSensorCard(
                      label: 'Temperature',
                      value: '24',
                      unit: '°C',
                      icon: Icons.thermostat,
                      iconColor: AppColors.moodEnergetic,
                      valueColor: AppColors.moodEnergetic,
                    ),
                    CAMSSensorCard(
                      label: 'Humidity',
                      value: '65',
                      unit: '%',
                      icon: Icons.water_drop,
                      iconColor: AppColors.secondaryTeal,
                      valueColor: AppColors.secondaryTeal,
                    ),
                    CAMSSensorCard(
                      label: 'Sound',
                      value: '45',
                      unit: 'dB',
                      icon: Icons.graphic_eq,
                      iconColor: AppColors.primaryOrange,
                      valueColor: AppColors.primaryOrange,
                    ),
                    CAMSSensorCard(
                      label: 'Motion',
                      value: '12',
                      unit: 'ppl',
                      icon: Icons.sensors,
                      iconColor: AppColors.focusColor,
                      valueColor: AppColors.focusColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXxl),

              // Info Cards
              _buildSection(
                'Info Cards',
                Column(
                  children: [
                    const CAMSInfoCard(
                      title: 'Space Status',
                      subtitle: 'Currently active',
                      icon: Icons.check_circle,
                      iconColor: AppColors.success,
                      trailing: Icon(Icons.chevron_right),
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    const CAMSInfoCard(
                      title: 'Music Player',
                      subtitle: 'Playing Energetic mood',
                      icon: Icons.music_note,
                      iconColor: AppColors.moodEnergetic,
                      trailing: Icon(Icons.pause_circle),
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    CAMSInfoCard(
                      title: 'Notifications',
                      subtitle: '3 new alerts',
                      icon: Icons.notifications,
                      iconColor: AppColors.warning,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '3',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXxl),

              // Color Palette
              _buildSection(
                'Color Palette',
                Wrap(
                  spacing: AppDimensions.spacingMd,
                  runSpacing: AppDimensions.spacingMd,
                  children: [
                    _buildColorBox('Primary', AppColors.primaryOrange),
                    _buildColorBox('Dark', AppColors.primaryOrangeDark),
                    _buildColorBox('Light', AppColors.primaryOrangeLight),
                    _buildColorBox('Pale', AppColors.primaryOrangePale),
                    _buildColorBox('Teal', AppColors.secondaryTeal),
                    _buildColorBox('Energetic', AppColors.energeticColor),
                    _buildColorBox('Focus', AppColors.focusColor),
                    _buildColorBox('Chill', AppColors.chillColor),
                    _buildColorBox('Success', AppColors.success),
                    _buildColorBox('Warning', AppColors.warning),
                    _buildColorBox('Error', AppColors.error),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.primaryOrange,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        content,
      ],
    );
  }

  Widget _buildColorBox(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTypography.caption,
        ),
      ],
    );
  }
}
