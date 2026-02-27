import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/player/player_event.dart';
import '../../../../core/widgets/song_list_tile.dart';
import '../../../../features/space_control/domain/entities/track.dart';
import '../../domain/entities/playlist_entity.dart';

class PlaylistDetailPage extends StatelessWidget {
  final PlaylistEntity playlist;

  const PlaylistDetailPage({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.fromBrightness(Theme.of(context).brightness);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── 1. SliverAppBar with cover image ────────────────────────────
          _CoverSliverAppBar(playlist: playlist, palette: palette),

          // ── 2. Title / Description / Play button ─────────────────────────
          SliverToBoxAdapter(
            child: _PlaylistHeader(playlist: playlist, palette: palette)
                .animate()
                .fadeIn(duration: 320.ms)
                .slideY(begin: 0.06),
          ),

          // ── 3. Song list ─────────────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = playlist.songs[index];
                return SongListTile(
                  song: song,
                  onTap: () {
                    final track = Track(
                      id: song.id,
                      title: song.title,
                      artist: song.artist,
                      fileUrl: '',
                      moodTags: const [],
                      duration: song.duration,
                      albumArt: song.coverUrl,
                    );
                    context.read<PlayerBloc>().add(PlayerTrackChanged(
                          track: track,
                          isPlaying: true,
                          currentPosition: 0,
                          duration: song.duration,
                        ));
                  },
                  onOptionSelected: (option) {
                    // TODO: handle option (addToPlaylist, block, etc.)
                    debugPrint('Option: $option for ${song.title}');
                  },
                )
                    .animate()
                    .fadeIn(duration: 280.ms, delay: (index * 40).ms)
                    .slideX(begin: 0.05);
              },
              childCount: playlist.songs.length,
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SliverAppBar — expandedHeight 250, cover image background
// ─────────────────────────────────────────────────────────────────────────────
class _CoverSliverAppBar extends StatelessWidget {
  const _CoverSliverAppBar({required this.playlist, required this.palette});
  final PlaylistEntity playlist;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 250,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(LucideIcons.chevronLeft,
              color: Colors.white, size: 20),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 14, right: 16),
        title: Text(
          playlist.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: palette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        background: _CoverBackground(
          coverUrl: playlist.coverUrl,
          palette: palette,
        ),
      ),
    );
  }
}

class _CoverBackground extends StatelessWidget {
  const _CoverBackground({required this.coverUrl, required this.palette});
  final String? coverUrl;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    if (coverUrl != null) {
      return Image.network(
        coverUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _Fallback(palette: palette),
      );
    }
    return _Fallback(palette: palette);
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.palette});
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: palette.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.music_note,
          color: Colors.grey.shade400,
          size: 72,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Playlist header — title, description, track count, Play button
// ─────────────────────────────────────────────────────────────────────────────
class _PlaylistHeader extends StatelessWidget {
  const _PlaylistHeader({required this.playlist, required this.palette});
  final PlaylistEntity playlist;
  final _Palette palette;

  String _formatTotalDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '$m phút';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            playlist.title,
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),

          // Description
          if (playlist.description != null) ...[
            const SizedBox(height: 6),
            Text(
              playlist.description!,
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Meta row: track count · total duration
          Row(
            children: [
              Icon(LucideIcons.music4, color: palette.textMuted, size: 14),
              const SizedBox(width: 5),
              Text(
                '${playlist.totalTracks} bài',
                style: GoogleFonts.inter(
                  color: palette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: palette.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              Icon(LucideIcons.clock, color: palette.textMuted, size: 14),
              const SizedBox(width: 5),
              Text(
                _formatTotalDuration(playlist.totalDuration),
                style: GoogleFonts.inter(
                  color: palette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Play button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(LucideIcons.play, size: 18),
              label: Text(
                'Phát tất cả',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                // TODO: dispatch PlayMusic event when wired to MusicControlBloc
              },
            ),
          ),

          // ── "Thêm bài hát" — only shown when playlist is empty ─────────
          if (playlist.songs.isEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.accent,
                  side: BorderSide(color: palette.accent, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'Thêm bài hát',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () => context.go('/search'),
              ),
            ),
          ],

          const SizedBox(height: 4),

          // Divider
          Divider(color: palette.border.withOpacity(0.6), height: 28),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Palette — same factory as home_tab_page.dart
// ─────────────────────────────────────────────────────────────────────────────
class _Palette {
  const _Palette({
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

  factory _Palette.fromBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    if (isDark) {
      return _Palette(
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
    return const _Palette(
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
