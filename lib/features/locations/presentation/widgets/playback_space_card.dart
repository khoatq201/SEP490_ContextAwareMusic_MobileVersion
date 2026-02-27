import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/location_space.dart';

/// Space card for playback device mode.
/// Uses the same rich card design as [SpaceManagementTile] but without
/// the action row (no Control/Schedule/Settings for a paired device).
class PlaybackSpaceCard extends StatelessWidget {
  final LocationSpace space;

  const PlaybackSpaceCard({super.key, required this.space});

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: icon + name + status badge ─────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          space.name,
                          style: GoogleFonts.poppins(
                            color: palette.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          space.storeName,
                          style: GoogleFonts.inter(
                            color: palette.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(isOnline: space.isOnline),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Info rows: playlist + volume ───────────────────
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

            const SizedBox(height: 16),

            // ── Paired device label ───────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: palette.border, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.link, color: palette.textMuted, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Paired Device',
                    style: GoogleFonts.inter(
                      color: palette.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isOnline});
  final bool isOnline;

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
            width: 7, height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color, fontSize: 10,
              fontWeight: FontWeight.w800, letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon, required this.label,
    required this.value, required this.palette,
  });
  final IconData icon;
  final String label;
  final String value;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: palette.textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: palette.textMuted, fontSize: 10,
            fontWeight: FontWeight.w700, letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              color: palette.accent, fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _Palette {
  final Color card, border, textPrimary, textMuted, accent;

  const _Palette({
    required this.card, required this.border,
    required this.textPrimary, required this.textMuted, required this.accent,
  });

  factory _Palette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const _Palette(
        card: AppColors.surfaceDark, border: AppColors.borderDarkLight,
        textPrimary: AppColors.textDarkPrimary, textMuted: AppColors.textDarkSecondary,
        accent: AppColors.primaryCyan,
      );
    }
    return const _Palette(
      card: AppColors.surface, border: AppColors.borderLight,
      textPrimary: AppColors.textPrimary, textMuted: AppColors.textTertiary,
      accent: AppColors.primaryOrange,
    );
  }
}
