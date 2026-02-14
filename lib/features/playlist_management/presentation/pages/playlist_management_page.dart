import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_drawer.dart';

class PlaylistManagementPage extends StatelessWidget {
  const PlaylistManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDarkPrimary
          : AppColors.backgroundPrimary,
      drawer: const AppDrawer(currentRoute: '/playlists'),
      appBar: AppBar(
        title: const Text('Playlists'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Storage Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.storage,
                          color: AppColors.primaryOrange,
                          size: 32,
                        ),
                        const SizedBox(width: AppDimensions.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Storage',
                                style: AppTypography.titleMedium.copyWith(
                                  color: isDark
                                      ? AppColors.textDarkPrimary
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.spacingXs),
                              Text(
                                '0 MB of 0 MB used',
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.textDarkSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    LinearProgressIndicator(
                      value: 0.0,
                      backgroundColor: AppColors.backgroundSecondary,
                      color: AppColors.primaryOrange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingLg),

            // Section Header
            Text(
              'Cached Playlists',
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMd),

            // Empty State
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.queue_music,
                      size: 80,
                      color: isDark
                          ? AppColors.textDarkTertiary
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    Text(
                      'No Playlists Downloaded',
                      style: AppTypography.titleMedium.copyWith(
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingSm),
                    Text(
                      'Download playlists to play offline',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textDarkTertiary
                            : AppColors.textTertiary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Browse available playlists
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Playlist download feature coming soon'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Browse Playlists'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
