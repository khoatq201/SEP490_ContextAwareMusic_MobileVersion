import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../constants/app_colors.dart';
import '../player_bloc.dart';
import '../player_event.dart';
import '../player_state.dart' as ps;

/// Full-screen music player shown via showModalBottomSheet.
/// Receives [PlayerBloc] from parent via BlocProvider.value.
class FullScreenPlayerPage extends StatelessWidget {
  const FullScreenPlayerPage({super.key});

  String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = _FSPalette.fromBrightness(Theme.of(context).brightness);
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.92,
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: BlocBuilder<PlayerBloc, ps.PlayerState>(
        builder: (context, state) {
          final track = state.currentTrack;
          final isPlaying = state.isPlaying;
          final moodTags = track?.moodTags;
          final mood =
              (moodTags != null && moodTags.isNotEmpty) ? moodTags.first : null;

          return Column(
            children: [
              // ── Drag handle ─────────────────────────────────────────
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              // ── Toolbar row ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: palette.overlay,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: palette.border),
                        ),
                        child: Icon(LucideIcons.chevronDown,
                            color: palette.textPrimary, size: 20),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Now Playing',
                      style: GoogleFonts.poppins(
                        color: palette.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: palette.overlay,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: palette.border),
                        ),
                        child: Icon(LucideIcons.moreHorizontal,
                            color: palette.textMuted, size: 20),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 250.ms),

              // ── Album art ───────────────────────────────────────────
              Expanded(
                flex: 5,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: track?.albumArt != null
                        ? Image.network(
                            track!.albumArt!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => _placeholder(palette),
                          )
                        : _placeholder(palette),
                  ),
                ),
              ).animate().fadeIn(duration: 350.ms).scale(
                    begin: const Offset(0.94, 0.94),
                    duration: 400.ms,
                    curve: Curves.easeOutBack,
                  ),

              // ── Track info + mood badge ──────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Mood badge
                    if (mood != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: palette.accent.withOpacity(0.12),
                          border: Border.all(
                            color: palette.accent.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.flame,
                                color: palette.accent, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              mood.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: palette.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      track?.title ?? 'No track playing',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: palette.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track?.artist ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: palette.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (track?.isAvailableOffline ?? false) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: palette.overlay,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: palette.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.wifiOff,
                                size: 12, color: palette.textMuted),
                            const SizedBox(width: 5),
                            Text(
                              'Offline Cache',
                              style: GoogleFonts.inter(
                                color: palette.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(duration: 380.ms).slideY(begin: 0.08),

              // ── Seek slider ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: palette.card,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: palette.accent,
                          inactiveTrackColor:
                              palette.textMuted.withOpacity(0.2),
                          thumbColor: palette.accentAlt,
                          overlayColor: palette.accent.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: state.progress,
                          onChanged: (_) {},
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _fmt(state.currentPosition),
                              style: GoogleFonts.inter(
                                  color: palette.textMuted, fontSize: 12),
                            ),
                            Text(
                              _fmt(state.duration),
                              style: GoogleFonts.inter(
                                  color: palette.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

              // ── Controls ────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Skip previous
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.overlay,
                          border: Border.all(color: palette.border),
                        ),
                        child: Icon(LucideIcons.skipBack,
                            color: palette.textPrimary, size: 22),
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Play / Pause
                    GestureDetector(
                      onTap: () => context
                          .read<PlayerBloc>()
                          .add(const PlayerPlayPauseToggled()),
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.accent,
                        ),
                        child: Icon(
                          isPlaying ? LucideIcons.pause : LucideIcons.play,
                          color: palette.textOnAccent,
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Skip next
                    GestureDetector(
                      onTap: () => context
                          .read<PlayerBloc>()
                          .add(const PlayerSkipRequested()),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.overlay,
                          border: Border.all(color: palette.border),
                        ),
                        child: Icon(LucideIcons.skipForward,
                            color: palette.textPrimary, size: 22),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.12),

              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  Widget _placeholder(_FSPalette palette) {
    return Container(
      color: palette.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      child: Center(
        child: Icon(Icons.music_note, color: Colors.grey.shade400, size: 64),
      ),
    );
  }
}

// ── Internal palette (mirrors _Palette in space_detail_page) ──────────────────
class _FSPalette {
  const _FSPalette({
    required this.isDark,
    required this.bg,
    required this.card,
    required this.overlay,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
    required this.accentAlt,
    required this.textOnAccent,
    required this.shadow,
  });

  factory _FSPalette.fromBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    if (isDark) {
      return _FSPalette(
        isDark: true,
        bg: AppColors.backgroundDarkPrimary,
        card: AppColors.surfaceDark,
        overlay: Colors.white.withOpacity(0.06),
        border: AppColors.borderDarkMedium,
        textPrimary: AppColors.textDarkPrimary,
        textMuted: AppColors.textDarkSecondary,
        accent: AppColors.primaryCyan,
        accentAlt: AppColors.secondaryLime,
        textOnAccent: AppColors.textDarkPrimary,
        shadow: AppColors.shadowDark,
      );
    }
    return const _FSPalette(
      isDark: false,
      bg: AppColors.backgroundPrimary,
      card: AppColors.surface,
      overlay: AppColors.backgroundSecondary,
      border: AppColors.borderLight,
      textPrimary: AppColors.textPrimary,
      textMuted: AppColors.textTertiary,
      accent: AppColors.primaryOrange,
      accentAlt: AppColors.secondaryTeal,
      textOnAccent: AppColors.textInverse,
      shadow: AppColors.shadow,
    );
  }

  final bool isDark;
  final Color bg;
  final Color card;
  final Color overlay;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;
  final Color accentAlt;
  final Color textOnAccent;
  final Color shadow;
}
