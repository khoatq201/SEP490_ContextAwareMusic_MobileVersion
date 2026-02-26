import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/location_space.dart';

/// Bottom sheet showing settings for a single space.
/// Conditionally shows "Soundtrack Remote" only in remote-control mode.
class SpaceSettingsSheet extends StatelessWidget {
  final LocationSpace space;
  final bool isPlaybackDevice;

  const SpaceSettingsSheet({
    super.key,
    required this.space,
    required this.isPlaybackDevice,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _SheetPalette.of(context);

    return SafeArea(
      bottom: true,
      child: Container(
        decoration: BoxDecoration(
          color: palette.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ───────────────────────────────────────────
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.textMuted.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Title row ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Space Settings',
                      style: GoogleFonts.poppins(
                        color: palette.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: palette.textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Info section ──────────────────────────────────────────
            _InfoGroup(
              palette: palette,
              children: [
                _InfoRow(label: 'Name', value: space.name, palette: palette),
                _InfoRow(label: 'Location', value: space.storeName, palette: palette),
              ],
            ),

            const SizedBox(height: 16),

            // ── Navigation tiles ──────────────────────────────────────
            _TileGroup(
              palette: palette,
              children: [
                _NavTile(
                  icon: LucideIcons.music4,
                  iconColor: palette.accent,
                  label: 'Music settings',
                  palette: palette,
                  onTap: () => _comingSoon(context, 'Music settings'),
                ),
                _NavTile(
                  icon: LucideIcons.clock,
                  iconColor: palette.accent,
                  label: 'Recently played songs',
                  palette: palette,
                  onTap: () => _comingSoon(context, 'Recently played songs'),
                ),
                _NavTile(
                  icon: LucideIcons.ban,
                  iconColor: AppColors.error,
                  label: 'Blocked songs',
                  palette: palette,
                  onTap: () => _comingSoon(context, 'Blocked songs'),
                ),
              ],
            ),

            // ── Soundtrack Remote (only for remote control mode) ──────
            if (!isPlaybackDevice) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'REMOTE CONTROL',
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _TileGroup(
                palette: palette,
                children: [
                  _NavTile(
                    icon: LucideIcons.smartphone,
                    iconColor: palette.accent,
                    label: 'Soundtrack Remote',
                    trailing: Text(
                      'Enabled',
                      style: GoogleFonts.inter(
                        color: palette.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    palette: palette,
                    onTap: () => _comingSoon(context, 'Soundtrack Remote'),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will be available soon.')),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _InfoGroup extends StatelessWidget {
  const _InfoGroup({required this.palette, required this.children});
  final _SheetPalette palette;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Divider(height: 1, color: palette.border),
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, required this.palette});
  final String label;
  final String value;
  final _SheetPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: palette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _TileGroup extends StatelessWidget {
  const _TileGroup({required this.palette, required this.children});
  final _SheetPalette palette;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Divider(height: 1, color: palette.border),
              ),
          ],
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.palette,
    required this.onTap,
    this.trailing,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final _SheetPalette palette;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: palette.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing != null) const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: palette.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────────────────────
class _SheetPalette {
  final Color bg;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;

  const _SheetPalette({
    required this.bg,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
  });

  factory _SheetPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const _SheetPalette(
        bg: AppColors.backgroundDarkPrimary,
        card: AppColors.surfaceDark,
        border: AppColors.borderDarkLight,
        textPrimary: AppColors.textDarkPrimary,
        textMuted: AppColors.textDarkSecondary,
        accent: AppColors.primaryCyan,
      );
    }
    return const _SheetPalette(
      bg: AppColors.backgroundPrimary,
      card: AppColors.surface,
      border: AppColors.borderLight,
      textPrimary: AppColors.textPrimary,
      textMuted: AppColors.textTertiary,
      accent: AppColors.primaryOrange,
    );
  }
}
