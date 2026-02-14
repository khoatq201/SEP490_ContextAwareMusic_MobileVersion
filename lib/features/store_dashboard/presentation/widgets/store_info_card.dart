import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/store.dart';

class StoreInfoCard extends StatelessWidget {
  final Store store;

  const StoreInfoCard({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: AppDimensions.elevationMd,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrangePale,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: const Icon(
                    Icons.store,
                    size: 32,
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        style: AppTypography.titleLarge.copyWith(
                          color: isDark
                              ? AppColors.textDarkPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXs),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: store.isActive
                                  ? AppColors.success
                                  : AppColors.textTertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingXs),
                          Text(
                            store.isActive ? 'Active' : 'Inactive',
                            style: AppTypography.labelSmall.copyWith(
                              color: store.isActive
                                  ? AppColors.success
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            const Divider(),
            const SizedBox(height: AppDimensions.spacingMd),

            // Address
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: store.address,
            ),
            const SizedBox(height: AppDimensions.spacingSm),

            // Phone
            if (store.phone != null)
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: store.phone!,
              ),
            if (store.phone != null)
              const SizedBox(height: AppDimensions.spacingSm),

            // Email
            if (store.email != null)
              _InfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: store.email!,
              ),
            if (store.email != null)
              const SizedBox(height: AppDimensions.spacingMd),

            const Divider(),
            const SizedBox(height: AppDimensions.spacingMd),

            // Statistics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Total Spaces',
                  value: store.totalSpaces.toString(),
                  color: AppColors.primaryOrange,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.borderLight,
                ),
                _StatItem(
                  label: 'Active Spaces',
                  value: store.activeSpaces.toString(),
                  color: AppColors.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
        ),
        const SizedBox(width: AppDimensions.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.textDarkTertiary
                      : AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textDarkPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headlineMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color:
                isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
