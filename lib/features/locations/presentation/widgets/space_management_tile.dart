import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/session/session_cubit.dart';
import '../../domain/entities/location_space.dart';
import 'space_settings_sheet.dart';

/// A rich card representing a single space inside a store.
/// Shows status, playlist info, volume, and action buttons.
class SpaceManagementTile extends StatelessWidget {
  final LocationSpace space;

  const SpaceManagementTile({super.key, required this.space});

  @override
  Widget build(BuildContext context) {
    final palette = _SpacePalette.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: name + status badge ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                // Space icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.accent.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    space.isOnline ? LucideIcons.radio : LucideIcons.radioReceiver,
                    color: palette.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Name
                Expanded(
                  child: Text(
                    space.name,
                    style: GoogleFonts.poppins(
                      color: palette.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Status badge
                _StatusBadge(isOnline: space.isOnline, palette: palette),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Info rows: playlist + volume ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _InfoRow(
                  icon: LucideIcons.music4,
                  label: 'PLAYLIST',
                  value: space.currentTrackName ?? 'Không có',
                  palette: palette,
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  icon: LucideIcons.volume2,
                  label: 'VOLUME',
                  value: '${space.volume.toInt()}%',
                  palette: palette,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Divider ────────────────────────────────────────────────
          Container(height: 1, color: palette.border),

          // ── Action-row: Control/Pair · Schedule · Settings ──────────
          _ActionRow(space: space, palette: palette),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.palette,
  });
  final IconData icon;
  final String label;
  final String value;
  final _SpacePalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: palette.textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: palette.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              color: palette.accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.space, required this.palette});
  final LocationSpace space;
  final _SpacePalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Control / Pair
        Expanded(
          child: _ActionButton(
            icon: space.isOnline ? LucideIcons.play : LucideIcons.link,
            label: space.isOnline ? 'Control' : 'Pair',
            palette: palette,
            onTap: () {
              if (space.isOnline) {
                context.go('/now-playing');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Device pairing will be available soon.')),
                );
              }
            },
          ),
        ),
        Container(width: 1, height: 48, color: palette.border),
        // Schedule
        Expanded(
          child: _ActionButton(
            icon: LucideIcons.calendar,
            label: 'Schedule',
            palette: palette,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scheduling will be available soon.')),
              );
            },
          ),
        ),
        Container(width: 1, height: 48, color: palette.border),
        // Settings
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
  });
  final IconData icon;
  final String label;
  final _SpacePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: palette.textMuted, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Palette — resolves from Theme brightness
// ─────────────────────────────────────────────────────────────────────────────
class _SpacePalette {
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;

  const _SpacePalette({
    required this.card,
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
        border: AppColors.borderDarkLight,
        textPrimary: AppColors.textDarkPrimary,
        textMuted: AppColors.textDarkSecondary,
        accent: AppColors.primaryCyan,
      );
    }
    return const _SpacePalette(
      card: AppColors.surface,
      border: AppColors.borderLight,
      textPrimary: AppColors.textPrimary,
      textMuted: AppColors.textTertiary,
      accent: AppColors.primaryOrange,
    );
  }
}
