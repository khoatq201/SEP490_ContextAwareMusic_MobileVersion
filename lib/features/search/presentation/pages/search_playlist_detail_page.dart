import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/play_to_space_button.dart';
import '../../../../core/widgets/song_list_tile.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/player/player_event.dart';
import '../../../home/domain/entities/playlist_entity.dart';
import '../../../space_control/domain/entities/track.dart';

/// Playlist detail page used within the **Search** feature.
/// Unlike the Home [PlaylistDetailPage], the primary CTA is
/// **"Play to Space"** instead of "Play All".
class SearchPlaylistDetailPage extends StatelessWidget {
  final PlaylistEntity playlist;

  const SearchPlaylistDetailPage({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.fromBrightness(Theme.of(context).brightness);

    final tracks = playlist.songs
        .map((s) => Track(
              id: s.id,
              title: s.title,
              artist: s.artist,
              fileUrl: s.streamUrl ?? '',
              moodTags: const [],
              duration: s.duration,
              albumArt: s.coverUrl,
            ))
        .toList();

    return Scaffold(
      backgroundColor: palette.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── SliverAppBar with cover image ─────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 250,
            backgroundColor: palette.bg,
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
              titlePadding:
                  const EdgeInsets.only(left: 56, bottom: 14, right: 16),
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
          ),

          // ── Header: title, description, meta, Play to Space ──────────
          SliverToBoxAdapter(
            child: Padding(
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

                  // Meta: track count · duration
                  Row(
                    children: [
                      Icon(LucideIcons.music4,
                          color: palette.textMuted, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        '${playlist.totalTracks} tracks',
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
                      Icon(LucideIcons.clock,
                          color: palette.textMuted, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        _formatDuration(playlist.totalDuration),
                        style: GoogleFonts.inter(
                          color: palette.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // "Play to Space" button (role-aware)
                  PlayToSpaceButton(
                    tracks: tracks,
                    playlistName: playlist.title,
                  ),

                  const SizedBox(height: 4),
                  Divider(color: palette.border.withOpacity(0.6), height: 28),
                ],
              ),
            ),
          ),

          // ── Song list ────────────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final song = playlist.songs[i];
                return SongListTile(
                  song: song,
                  onTap: () {
                    ctx.read<PlayerBloc>().add(PlayerPlaylistStarted(
                          tracks: tracks,
                          startIndex: i,
                          playlistName: playlist.title,
                        ));
                  },
                );
              },
              childCount: playlist.songs.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 160)),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '$m min';
  }
}

// ── Cover background ────────────────────────────────────────────────────────
class _CoverBackground extends StatelessWidget {
  final String? coverUrl;
  final _Palette palette;
  const _CoverBackground({required this.coverUrl, required this.palette});

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
  final _Palette palette;
  const _Fallback({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: palette.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      child: Center(
        child: Icon(Icons.music_note, color: Colors.grey.shade400, size: 72),
      ),
    );
  }
}

// ── Palette ─────────────────────────────────────────────────────────────────
class _Palette {
  const _Palette({
    required this.isDark,
    required this.bg,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
  });

  factory _Palette.fromBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    if (isDark) {
      return _Palette(
        isDark: true,
        bg: AppColors.backgroundDarkPrimary,
        border: AppColors.borderDarkMedium,
        textPrimary: AppColors.textDarkPrimary,
        textMuted: AppColors.textDarkSecondary,
      );
    }
    return const _Palette(
      isDark: false,
      bg: AppColors.backgroundPrimary,
      border: AppColors.borderLight,
      textPrimary: AppColors.textPrimary,
      textMuted: AppColors.textTertiary,
    );
  }

  final bool isDark;
  final Color bg;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
}
