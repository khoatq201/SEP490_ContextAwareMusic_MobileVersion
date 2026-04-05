import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../hub_management/presentation/pages/space_hub_page.dart';

class SpaceSettingsPage extends StatelessWidget {
  const SpaceSettingsPage({
    super.key,
    required this.storeId,
    required this.spaceId,
    required this.spaceName,
  });

  final String storeId;
  final String spaceId;
  final String spaceName;

  @override
  Widget build(BuildContext context) {
    final palette = _SpaceSettingsPalette.of(context);

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: palette.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Space Settings',
          style: GoogleFonts.poppins(
            color: palette.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        children: [
          _SectionCard(
            palette: palette,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spaceName,
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage hardware provisioning and review the context used when binding an ESP32 hub to this space.',
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  palette: palette,
                  icon: LucideIcons.store,
                  label: 'Store ID',
                  value: storeId,
                ),
                _InfoRow(
                  palette: palette,
                  icon: LucideIcons.layoutTemplate,
                  label: 'Space ID',
                  value: spaceId,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            palette: palette,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connectivity',
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Provision the ESP32 over BLE, choose the Wi-Fi network, and save the hub-to-space binding for backend sync.',
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                _NavigationTile(
                  palette: palette,
                  icon: LucideIcons.router,
                  label: 'IoT Hub & Wi-Fi',
                  subtitle:
                      'Scan CAM devices, push Wi-Fi credentials, and manage the saved ESP assignment.',
                  onTap: () async {
                    await context.push<bool>(
                      buildSpaceHubLocation(
                        spaceId: spaceId,
                        storeId: storeId,
                        spaceName: spaceName,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            palette: palette,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notes',
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Playback controls, sensors, and offline content remain on the Space Detail screen. Provisioning is separated here so the ESP BLE flow stays focused and easier to retry.',
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.palette,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final _SpaceSettingsPalette palette;
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: palette.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: palette.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: palette.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              LucideIcons.chevronRight,
              color: palette.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.palette,
    required this.child,
  });

  final _SpaceSettingsPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.palette,
    required this.icon,
    required this.label,
    required this.value,
  });

  final _SpaceSettingsPalette palette;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: palette.textMuted, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                color: palette.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceSettingsPalette {
  const _SpaceSettingsPalette({
    required this.bg,
    required this.card,
    required this.panel,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
  });

  final Color bg;
  final Color card;
  final Color panel;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;

  factory _SpaceSettingsPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _SpaceSettingsPalette(
      bg: isDark
          ? AppColors.backgroundDarkPrimary
          : AppColors.backgroundPrimary,
      card: isDark ? AppColors.surfaceDark : Colors.white,
      panel: isDark
          ? AppColors.surfaceDark.withValues(alpha: 0.8)
          : AppColors.backgroundPrimary,
      border: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.divider,
      textPrimary: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
      textMuted: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
      accent: isDark ? AppColors.primaryCyan : AppColors.primaryOrange,
    );
  }
}
