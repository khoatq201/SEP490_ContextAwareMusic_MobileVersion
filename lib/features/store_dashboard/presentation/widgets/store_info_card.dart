import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/cams_theme_tokens.dart';
import '../../../config_governance/domain/entities/config_governance_enums.dart';
import '../../domain/entities/store.dart';

class StoreInfoCard extends StatelessWidget {
  final Store store;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onDelete;

  const StoreInfoCard({
    super.key,
    required this.store,
    this.onEdit,
    this.onToggleStatus,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.camsTokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasActions =
        onEdit != null || onToggleStatus != null || onDelete != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tokens.bgElevated.withValues(alpha: isDark ? 0.94 : 0.99),
            tokens.bgContainer.withValues(alpha: isDark ? 0.76 : 0.97),
          ],
        ),
        border: Border.all(
          color: tokens.borderSecondary.withValues(alpha: isDark ? 0.7 : 1),
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.shadow.withValues(alpha: isDark ? 0.34 : 0.1),
            blurRadius: isDark ? 28 : 18,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _StoreHeroPatternPainter(
                  color: colorScheme.primary,
                  isDark: isDark,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StoreIconTile(color: colorScheme.primary),
                      const SizedBox(width: AppDimensions.spacingMd),
                      Expanded(child: _StoreHeader(store: store)),
                      if (hasActions)
                        _StoreActionsMenu(
                          store: store,
                          onEdit: onEdit,
                          onToggleStatus: onToggleStatus,
                          onDelete: onDelete,
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Divider(color: tokens.divider),
                  const SizedBox(height: 18),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: store.fullAddress,
                  ),
                  const SizedBox(height: 14),
                  if (store.contactNumber != null) ...[
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: store.contactNumber!,
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (store.timeZone != null)
                    _InfoRow(
                      icon: Icons.access_time_outlined,
                      label: 'Timezone',
                      value: store.timeZone!,
                    ),
                  if (store.areaSquareMeters != null ||
                      store.maxCapacity != null) ...[
                    const SizedBox(height: 18),
                    Divider(color: tokens.divider),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (store.areaSquareMeters != null)
                          Expanded(
                            child: _MetricTile(
                              child: _StatItem(
                                label: 'Area (m2)',
                                value:
                                    store.areaSquareMeters!.toStringAsFixed(0),
                              ),
                            ),
                          ),
                        if (store.areaSquareMeters != null &&
                            store.maxCapacity != null)
                          const SizedBox(width: 12),
                        if (store.maxCapacity != null)
                          Expanded(
                            child: _MetricTile(
                              child: _CapacityMeter(
                                value: store.maxCapacity!,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          store.name,
          style: AppTypography.headlineSmall.copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusBadge(
              label: store.status.displayName,
              isActive: store.isActive,
            ),
            if (store.governanceMode != null)
              _GovernanceModeBadge(mode: store.governanceMode!),
          ],
        ),
      ],
    );
  }
}

class _StoreActionsMenu extends StatelessWidget {
  const _StoreActionsMenu({
    required this.store,
    this.onEdit,
    this.onToggleStatus,
    this.onDelete,
  });

  final Store store;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Store actions',
      icon: Icon(
        Icons.more_vert_rounded,
        color: context.camsTokens.textPrimary,
      ),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'toggle':
            onToggleStatus?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        if (onEdit != null)
          const PopupMenuItem<String>(
            value: 'edit',
            child: Text('Edit store'),
          ),
        if (onToggleStatus != null)
          PopupMenuItem<String>(
            value: 'toggle',
            child: Text(store.isActive ? 'Set inactive' : 'Set active'),
          ),
        if (onDelete != null)
          const PopupMenuItem<String>(
            value: 'delete',
            child: Text('Delete store'),
          ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.bgBase.withValues(alpha: isDark ? 0.46 : 0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: tokens.borderSecondary.withValues(alpha: isDark ? 0.62 : 1),
        ),
      ),
      child: child,
    );
  }
}

class _StoreIconTile extends StatelessWidget {
  const _StoreIconTile({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = context.camsTokens;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.24 : 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.22 : 0.08),
            blurRadius: isDark ? 18 : 10,
          ),
        ],
      ),
      child: SizedBox.square(
        dimension: 70,
        child: Icon(
          Icons.storefront_rounded,
          size: 36,
          color: isDark ? color : tokens.brandPrimaryActive,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.isActive,
  });

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    final color = isActive ? tokens.success : tokens.textTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
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
          const SizedBox(width: AppDimensions.spacingXs),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GovernanceModeBadge extends StatelessWidget {
  const _GovernanceModeBadge({required this.mode});

  final StoreGovernanceMode mode;

  @override
  Widget build(BuildContext context) {
    final color = _modeColor(context, mode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_modeIcon(mode), size: 15, color: color),
          const SizedBox(width: AppDimensions.spacingXs),
          Text(
            mode.label,
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static Color _modeColor(BuildContext context, StoreGovernanceMode mode) {
    final tokens = context.camsTokens;
    final colorScheme = Theme.of(context).colorScheme;
    switch (mode) {
      case StoreGovernanceMode.strictSync:
        return colorScheme.primary;
      case StoreGovernanceMode.aiMode:
        return tokens.techAccent;
      case StoreGovernanceMode.freedom:
        return tokens.success;
    }
  }

  static IconData _modeIcon(StoreGovernanceMode mode) {
    switch (mode) {
      case StoreGovernanceMode.strictSync:
        return Icons.sync_lock_rounded;
      case StoreGovernanceMode.aiMode:
        return Icons.auto_awesome_rounded;
      case StoreGovernanceMode.freedom:
        return Icons.lock_open_rounded;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    final displayValue = value.trim().isEmpty ? 'Not set' : value.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 21,
          color: tokens.textTertiary,
        ),
        const SizedBox(width: AppDimensions.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: tokens.textTertiary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayValue,
                style: AppTypography.bodyMedium.copyWith(
                  color: tokens.textPrimary,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
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
  const _StatItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTypography.headlineSmall.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w900,
            shadows: isDark
                ? [
                    Shadow(
                      color: colorScheme.primary.withValues(alpha: 0.32),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.72 : 0.9),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CapacityMeter extends StatelessWidget {
  const _CapacityMeter({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value.toString(),
          style: AppTypography.headlineSmall.copyWith(
            color: tokens.success,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: List.generate(
            8,
            (index) => Container(
              width: 4,
              height: 16,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                color: index < 4
                    ? tokens.success
                    : tokens.borderSecondary.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Max Capacity',
          style: AppTypography.labelMedium.copyWith(
            color: tokens.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StoreHeroPatternPainter extends CustomPainter {
  const _StoreHeroPatternPainter({
    required this.color,
    required this.isDark,
  });

  final Color color;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: isDark ? 0.06 : 0.025);

    Path wave(double top, double height) {
      return Path()
        ..moveTo(0, top)
        ..cubicTo(
          size.width * 0.32,
          top + height,
          size.width * 0.58,
          top - height,
          size.width,
          top + height * 0.35,
        )
        ..lineTo(size.width, top + height * 2.2)
        ..cubicTo(
          size.width * 0.72,
          top + height * 1.45,
          size.width * 0.34,
          top + height * 2.45,
          0,
          top + height * 1.55,
        )
        ..close();
    }

    canvas.drawPath(wave(size.height * 0.18, size.height * 0.18), paint);
    paint.color = color.withValues(alpha: isDark ? 0.05 : 0.02);
    canvas.drawPath(wave(size.height * 0.3, size.height * 0.14), paint);
    paint.color = color.withValues(alpha: isDark ? 0.04 : 0.018);
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.1),
      size.width * 0.32,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _StoreHeroPatternPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isDark != isDark;
  }
}
