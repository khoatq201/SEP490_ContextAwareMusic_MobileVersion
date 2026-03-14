import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../cams/presentation/bloc/cams_playback_bloc.dart';
import '../../../space_control/domain/entities/space.dart';
import '../../../store_dashboard/domain/entities/store.dart';
import '../../domain/entities/location_space.dart';
import 'space_settings_sheet.dart';

/// A role-aware card representing a single space inside the Location tab.
/// It highlights the targeted space, shows live playback context when possible,
/// and lets managers quickly swap the active space.
class SpaceManagementTile extends StatelessWidget {
  final LocationSpace space;
  final bool showStoreName;

  const SpaceManagementTile({
    super.key,
    required this.space,
    this.showStoreName = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _SpacePalette.of(context);
    final session = context.watch<SessionCubit>().state;
    final playerState = context.watch<PlayerBloc>().state;
    final camsState = context.watch<CamsPlaybackBloc>().state;
    final isTargeted = session.currentSpace?.id == space.id;

    final displayMood = _firstNonEmpty([
      if (isTargeted) camsState.currentMoodName,
      space.currentMoodName,
    ]);
    final displayPlaylist = _firstNonEmpty([
      if (isTargeted) camsState.currentPlaylistName,
      space.currentPlaylistName,
    ]);
    final displayTrackName = _firstNonEmpty([
      if (isTargeted) playerState.currentTrack?.title,
      space.currentTrackName,
    ]);
    final displayTrackArtist = _firstNonEmpty([
      if (isTargeted) playerState.currentTrack?.artist,
      space.currentTrackArtist,
    ]);
    final isOnline = space.status.isActive || space.isOnline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTargeted ? palette.accent.withAlpha(130) : palette.border,
          width: isTargeted ? 1.4 : 1,
        ),
        boxShadow: isTargeted
            ? [
                BoxShadow(
                  color: palette.accent.withAlpha(18),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: palette.accent.withAlpha(22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isOnline ? LucideIcons.radio : LucideIcons.radioReceiver,
                    color: palette.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              space.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: palette.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isTargeted)
                            _HeaderBadge(
                              icon: LucideIcons.crosshair,
                              label: 'TARGET',
                              color: palette.accent,
                            ),
                          if (isTargeted) const SizedBox(width: 8),
                          _StatusBadge(isOnline: isOnline, palette: palette),
                        ],
                      ),
                      if (showStoreName && space.storeName != null) ...[
                        const SizedBox(height: 6),
                        _StorePill(
                          storeName: space.storeName!,
                          palette: palette,
                        ),
                      ],
                      if (space.description != null &&
                          space.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          space.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: palette.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                  icon: LucideIcons.layoutTemplate,
                  label: space.type.displayName,
                  palette: palette,
                ),
                _MetaChip(
                  icon: LucideIcons.sparkles,
                  label: displayMood ?? 'No mood',
                  palette: palette,
                ),
                _MetaChip(
                  icon: LucideIcons.listMusic,
                  label: displayPlaylist ?? 'Idle',
                  palette: palette,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.panel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: palette.accent.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      displayTrackName != null
                          ? LucideIcons.music4
                          : Icons.graphic_eq,
                      color: palette.accent,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTrackName ?? 'No active track',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: palette.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayTrackArtist ??
                              (space.hasLivePlayback
                                  ? 'Streaming in this space'
                                  : 'Waiting for playback'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: palette.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: palette.border),
          _ActionRow(
            space: space,
            palette: palette,
            isTargeted: isTargeted,
            isPlaybackDevice: session.isPlaybackDevice,
            onSwap: () => _activateTarget(context, openSpace: false),
            onOpen: () => _activateTarget(context, openSpace: true),
          ),
        ],
      ),
    );
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  void _activateTarget(
    BuildContext context, {
    required bool openSpace,
  }) {
    final sessionCubit = context.read<SessionCubit>();
    final session = sessionCubit.state;

    final targetStoreName =
        space.storeName ?? session.currentStore?.name ?? 'Store';
    final targetStore = Store(
      id: space.storeId,
      name: targetStoreName,
      brandId: session.currentStore?.brandId ?? '',
    );
    final targetSpace = Space(
      id: space.id,
      name: space.name,
      storeId: space.storeId,
      type: space.type,
      description: space.description,
      status: space.status,
      currentPlaylistId: space.currentPlaylistId,
      currentMood: space.currentMoodName,
    );

    if (session.currentStore?.id != space.storeId) {
      sessionCubit.changeStore(targetStore);
    }
    sessionCubit.changeSpace(targetSpace);

    if (openSpace) {
      context.go('/now-playing');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Targeting ${space.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StorePill extends StatelessWidget {
  const _StorePill({
    required this.storeName,
    required this.palette,
  });

  final String storeName;
  final _SpacePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.store, size: 13, color: palette.textMuted),
          const SizedBox(width: 6),
          Text(
            storeName,
            style: GoogleFonts.inter(
              color: palette.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isOnline, required this.palette});
  final bool isOnline;
  final _SpacePalette palette;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? AppColors.success : AppColors.error;
    final label = isOnline ? 'ONLINE' : 'OFFLINE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final _SpacePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: palette.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: palette.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.space,
    required this.palette,
    required this.isTargeted,
    required this.isPlaybackDevice,
    required this.onSwap,
    required this.onOpen,
  });

  final LocationSpace space;
  final _SpacePalette palette;
  final bool isTargeted;
  final bool isPlaybackDevice;
  final VoidCallback onSwap;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: isPlaybackDevice
                ? LucideIcons.link2
                : isTargeted
                    ? LucideIcons.checkCircle2
                    : LucideIcons.arrowRightLeft,
            label: isPlaybackDevice
                ? 'Paired'
                : isTargeted
                    ? 'Targeted'
                    : 'Swap here',
            palette: palette,
            enabled: !isPlaybackDevice && !isTargeted,
            onTap: onSwap,
          ),
        ),
        Container(width: 1, height: 52, color: palette.border),
        Expanded(
          child: _ActionButton(
            icon: LucideIcons.panelTopOpen,
            label: 'Open',
            palette: palette,
            onTap: onOpen,
          ),
        ),
        Container(width: 1, height: 52, color: palette.border),
        Expanded(
          child: _ActionButton(
            icon: LucideIcons.settings,
            label: 'Settings',
            palette: palette,
            onTap: () {
              final session = context.read<SessionCubit>().state;
              showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => SpaceSettingsSheet(
                  space: space,
                  isPlaybackDevice: session.isPlaybackDevice,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final _SpacePalette palette;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color =
        enabled ? palette.textPrimary : palette.textMuted.withAlpha(140);

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpacePalette {
  final Color card;
  final Color panel;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;

  const _SpacePalette({
    required this.card,
    required this.panel,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
  });

  factory _SpacePalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const _SpacePalette(
        card: AppColors.surfaceDark,
        panel: Color(0xFF121B26),
        border: AppColors.borderDarkLight,
        textPrimary: AppColors.textDarkPrimary,
        textMuted: AppColors.textDarkSecondary,
        accent: AppColors.primaryCyan,
      );
    }
    return const _SpacePalette(
      card: AppColors.surface,
      panel: Color(0xFFF8F6F2),
      border: AppColors.borderLight,
      textPrimary: AppColors.textPrimary,
      textMuted: AppColors.textTertiary,
      accent: AppColors.primaryOrange,
    );
  }
}
