import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/pagination_result.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/presentation/shell_layout_metrics.dart';
import '../../../../core/session/session_cubit.dart';
import '../../domain/entities/location_space.dart';
import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';
import '../bloc/location_state.dart';
import 'space_management_tile.dart';

class BrandLocationsView extends StatelessWidget {
  final Map<String, PaginationResult<LocationSpace>> brandSpaces;
  final Map<String, String> storeNamesById;

  const BrandLocationsView({
    super.key,
    required this.brandSpaces,
    required this.storeNamesById,
  });

  @override
  Widget build(BuildContext context) {
    if (brandSpaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.business_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'No locations found.',
              style: GoogleFonts.inter(
                color: AppColors.textTertiary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final palette = _AccordionPalette.of(context);
    final session = context.watch<SessionCubit>().state;
    final hasMiniPlayer =
        context.select((PlayerBloc bloc) => bloc.state.hasTrack);
    final bottomPadding = ShellLayoutMetrics.reservedBottom(
      context,
      hasMiniPlayer: hasMiniPlayer,
      extra: 24,
    );
    final locationState = context.watch<LocationBloc>().state;
    final currentStoreId = session.currentStore?.id;
    final currentSpaceName = session.currentSpace?.name;
    final storeIds = brandSpaces.keys.toList()
      ..sort((a, b) {
        if (a == currentStoreId) return -1;
        if (b == currentStoreId) return 1;
        final aName = storeNamesById[a] ?? a;
        final bName = storeNamesById[b] ?? b;
        return aName.compareTo(bName);
      });

    final selectedStoreId = storeIds.contains(locationState.selectedStoreId)
        ? locationState.selectedStoreId!
        : (currentStoreId != null && storeIds.contains(currentStoreId)
            ? currentStoreId
            : storeIds.first);
    final spacesPagination = brandSpaces[selectedStoreId]!;
    final spaces = spacesPagination.items;
    final storeName = storeNamesById[selectedStoreId] ??
        (spaces.isNotEmpty ? spaces.first.storeName : null) ??
        'Store';
    final isTargetStore = currentStoreId == selectedStoreId;
    final activeSpaces = spaces.where((space) => space.hasLivePlayback).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Viewing store',
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: palette.accent.withAlpha(18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedStoreId,
                      isExpanded: true,
                      dropdownColor: palette.card,
                      icon: Icon(
                        LucideIcons.chevronsUpDown,
                        color: palette.textMuted,
                        size: 18,
                      ),
                      style: GoogleFonts.poppins(
                        color: palette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      items: storeIds
                          .map(
                            (storeId) => DropdownMenuItem<String>(
                              value: storeId,
                              child: Text(
                                storeNamesById[storeId] ?? 'Store',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        context
                            .read<LocationBloc>()
                            .add(LocationSelectedStoreChanged(value));
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SummaryChip(
                      icon: LucideIcons.store,
                      label:
                          '${spaces.length} space${spaces.length == 1 ? '' : 's'}',
                      palette: palette,
                    ),
                    _SummaryChip(
                      icon: LucideIcons.radio,
                      label: '$activeSpaces active',
                      palette: palette,
                    ),
                    if (isTargetStore)
                      _SummaryChip(
                        icon: LucideIcons.crosshair,
                        label: currentSpaceName != null
                            ? 'Targeting $currentSpaceName'
                            : 'Target store',
                        palette: palette,
                        highlighted: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: spaces.isEmpty
              ? ListView(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: palette.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: palette.border),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 42,
                            color: palette.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No spaces found for $storeName.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: palette.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
                  itemCount: spaces.length,
                  itemBuilder: (context, index) {
                    return SpaceManagementTile(
                      space: spaces[index],
                      showStoreName: false,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.palette,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final _AccordionPalette palette;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = highlighted
        ? palette.accent.withAlpha(24)
        : palette.accent.withAlpha(14);
    final foregroundColor = highlighted ? palette.accent : palette.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: foregroundColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

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
