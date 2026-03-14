import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/space_summary.dart';

class SpaceGridCard extends StatelessWidget {
  final SpaceSummary space;
  final VoidCallback onTap;

  const SpaceGridCard({
    super.key,
    required this.space,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moodLabel = _formatMoodLabel(space.currentMood);
    return Card(
      elevation: AppDimensions.elevationMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      space.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: space.isOnline
                          ? AppColors.success
                          : AppColors.textTertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingSm),

              // Mood Badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingSm,
                  vertical: AppDimensions.spacingXs,
                ),
                decoration: BoxDecoration(
                  color:
                      _getMoodColor(space.currentMood).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  border: Border.all(
                    color: _getMoodColor(space.currentMood),
                    width: 1,
                  ),
                ),
                child: Text(
                  moodLabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: _getMoodColor(space.currentMood),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),

              const SizedBox(height: AppDimensions.spacingSm),

              // Stats
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatRow(
                    icon: Icons.people_outline,
                    value: '${space.customerCount}',
                    color: AppColors.primaryOrange,
                  ),
                  const SizedBox(height: 2),
                  _StatRow(
                    icon: Icons.thermostat_outlined,
                    value: '${space.temperature.toStringAsFixed(1)}°C',
                    color: AppColors.secondaryTeal,
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.spacingSm),
              const Divider(height: 1),
              const SizedBox(height: AppDimensions.spacingXs),

              // Music Status
              Row(
                children: [
                  Icon(
                    space.isMusicPlaying ? Icons.music_note : Icons.music_off,
                    size: 16,
                    color: space.isMusicPlaying
                        ? AppColors.success
                        : (isDark
                            ? AppColors.textDarkTertiary
                            : AppColors.textTertiary),
                  ),
                  const SizedBox(width: AppDimensions.spacingXs),
                  Expanded(
                    child: Text(
                      space.isMusicPlaying
                          ? (space.currentTrack ?? 'Playing')
                          : 'No music',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'energetic':
        return AppColors.warning;
      case 'calm':
        return AppColors.secondaryTeal;
      case 'welcoming':
        return AppColors.success;
      case 'relaxed':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatMoodLabel(String mood) {
    final trimmed = mood.trim();
    if (trimmed.isEmpty) return 'UNKNOWN';

    // Convert "manualoverride", "manual_override", "manual-override",
    // and camelCase forms into a readable single-line label.
    final withSpaces =
        trimmed.replaceAll(RegExp(r'[_-]+'), ' ').replaceAllMapped(
              RegExp(r'([a-z])([A-Z])'),
              (match) => '${match.group(1)} ${match.group(2)}',
            );

    final collapsed = withSpaces.replaceAll(RegExp(r'\s+'), ' ').trim();
    return collapsed.toUpperCase();
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppDimensions.spacingXs),
        Text(
          value,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
