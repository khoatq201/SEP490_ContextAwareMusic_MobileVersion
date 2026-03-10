import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/space_control/domain/entities/space.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../session/session_cubit.dart';

/// A bottom sheet that displays a list of spaces for the user to select.
/// Used by the "Play to Space" feature in Search detail pages.
///
/// [onSpaceSelected] is called with the chosen [Space].
/// The sheet auto-closes after selection.
class PlayToSpaceBottomSheet extends StatelessWidget {
  final List<Space> spaces;
  final ValueChanged<Space> onSpaceSelected;

  const PlayToSpaceBottomSheet({
    super.key,
    required this.spaces,
    required this.onSpaceSelected,
  });

  /// Convenience method: shows the sheet and returns the selected [Space],
  /// or `null` if dismissed.
  static Future<Space?> show(
    BuildContext context, {
    required List<Space> spaces,
  }) {
    return showModalBottomSheet<Space>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlayToSpaceBottomSheet(
        spaces: spaces,
        onSpaceSelected: (space) => Navigator.of(context).pop(space),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessionState = context.read<SessionCubit>().state;
    final currentSpaceId = sessionState.currentSpace?.id;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
            child: Row(
              children: [
                Icon(
                  LucideIcons.speaker,
                  size: 22,
                  color: isDark
                      ? AppColors.textDarkPrimary
                      : AppColors.textPrimary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Play to Space',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
            child: Text(
              'Select a space to play this music',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            color: isDark ? AppColors.borderDarkMedium : AppColors.borderLight,
            height: 1,
          ),

          // Space list
          Flexible(
            child: spaces.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.wifiOff,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No spaces available',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: spaces.length,
                    itemBuilder: (ctx, i) {
                      final space = spaces[i];
                      final isSelected = space.id == currentSpaceId;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingMd,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: space.isOnline
                                ? AppColors.success.withOpacity(0.12)
                                : Colors.grey.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            space.isOnline
                                ? LucideIcons.speaker
                                : LucideIcons.volumeX,
                            color: space.isOnline
                                ? AppColors.success
                                : Colors.grey.shade500,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          space.name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textDarkPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          space.isOnline ? 'Online' : 'Offline',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: space.isOnline
                                ? AppColors.success
                                : Colors.grey.shade500,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                LucideIcons.checkCircle2,
                                color: AppColors.primaryCyan,
                                size: 22,
                              )
                            : Icon(
                                LucideIcons.circle,
                                color: Colors.grey.shade400,
                                size: 22,
                              ),
                        onTap: space.isOnline
                            ? () => onSpaceSelected(space)
                            : null,
                      );
                    },
                  ),
          ),

          // Bottom safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
