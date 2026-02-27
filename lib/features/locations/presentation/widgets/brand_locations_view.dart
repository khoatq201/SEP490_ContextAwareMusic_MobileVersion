import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/location_space.dart';
import 'space_management_tile.dart';

/// Accordion-style view showing multiple stores, each expandable to reveal
/// its child spaces as [SpaceManagementTile] cards.
class BrandLocationsView extends StatelessWidget {
  final Map<String, List<LocationSpace>> brandSpaces;

  const BrandLocationsView({super.key, required this.brandSpaces});

  @override
  Widget build(BuildContext context) {
    if (brandSpaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.business_outlined,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'No locations found.',
              style: GoogleFonts.inter(
                  color: AppColors.textTertiary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final palette = _AccordionPalette.of(context);
    final storeIds = brandSpaces.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: storeIds.length,
      itemBuilder: (context, index) {
        final storeId = storeIds[index];
        final spaces = brandSpaces[storeId]!;
        final storeName =
            spaces.isNotEmpty ? spaces.first.storeName : 'Unknown Store';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border, width: 1),
          ),
          child: Theme(
            // Override the default expansion tile divider
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: index == 0,
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.accent.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.store, color: palette.accent, size: 20),
              ),
              title: Text(
                storeName,
                style: GoogleFonts.poppins(
                  color: palette.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                '${spaces.length} space${spaces.length > 1 ? 's' : ''}',
                style: GoogleFonts.inter(
                  color: palette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Icon(LucideIcons.chevronDown,
                  color: palette.textMuted, size: 18),
              children: spaces
                  .map((space) => SpaceManagementTile(space: space))
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────────────────────
class _AccordionPalette {
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;

  const _AccordionPalette({
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
  });

  factory _AccordionPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const _AccordionPalette(
        card: AppColors.surfaceDark,
        border: AppColors.borderDarkLight,
        textPrimary: AppColors.textDarkPrimary,
        textMuted: AppColors.textDarkSecondary,
        accent: AppColors.primaryCyan,
      );
    }
    return const _AccordionPalette(
      card: AppColors.surface,
      border: AppColors.borderLight,
      textPrimary: AppColors.textPrimary,
      textMuted: AppColors.textTertiary,
      accent: AppColors.primaryOrange,
    );
  }
}
