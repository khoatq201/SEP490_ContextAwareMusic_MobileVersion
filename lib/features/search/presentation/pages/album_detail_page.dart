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
import '../../../../core/player/local_preview_feedback.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../injection_container.dart';
import '../../../space_control/domain/entities/track.dart';
import '../../domain/entities/album_entity.dart';
import '../bloc/album_detail_cubit.dart';

class AlbumDetailPage extends StatelessWidget {
  final String albumId;

  const AlbumDetailPage({super.key, required this.albumId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AlbumDetailCubit>()..load(albumId),
      child: const _AlbumDetailView(),
    );
  }
}

class _AlbumDetailView extends StatelessWidget {
  const _AlbumDetailView();

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.fromBrightness(Theme.of(context).brightness);

    return Scaffold(
      backgroundColor: palette.bg,
      body: BlocBuilder<AlbumDetailCubit, AlbumDetailState>(
        builder: (context, state) {
          if (state.status == AlbumDetailStatus.loading ||
              state.status == AlbumDetailStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == AlbumDetailStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: palette.textMuted),
                  const SizedBox(height: 12),
                  Text(state.errorMessage ?? 'An error occurred',
                      style: TextStyle(color: palette.textMuted)),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go back'),
                  ),
                ],
              ),
            );
          }

          final album = state.album!;
          return _AlbumBody(album: album, palette: palette);
        },
      ),
    );
  }
}

class _AlbumBody extends StatelessWidget {
  final AlbumEntity album;
  final _Palette palette;

  const _AlbumBody({required this.album, required this.palette});

  List<Track> get _tracks => album.songs
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

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── SliverAppBar with album cover ─────────────────────────────
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
              album.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: palette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            background: _CoverBackground(
              coverUrl: album.coverUrl,
              palette: palette,
            ),
          ),
        ),

        // ── Album info & Play to Space button ─────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Album title
                Text(
                  album.name,
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: 4),

                // Artist name
                Text(
                  album.artistName,
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 8),

                // Meta: year · tracks
                Row(
                  children: [
                    if (album.releaseYear != null) ...[
                      Text(
                        album.releaseYear.toString(),
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
                    ],
                    Icon(LucideIcons.music4,
                        color: palette.textMuted, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      '${album.songs.length} tracks',
                      style: GoogleFonts.inter(
                        color: palette.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Play to Space button
                PlayToSpaceButton(
                  tracks: _tracks,
                  playlistName: album.name,
                ),

                const SizedBox(height: 4),
                Divider(color: palette.border.withOpacity(0.6), height: 28),
              ],
            ),
          ),
        ),

        // ── Song list ─────────────────────────────────────────────────
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              final song = album.songs[i];
              return SongListTile(
                song: song,
                onTap: () {
                  final session = ctx.read<SessionCubit>().state;
                  if (!session.isPlaybackDevice) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text(kManagerPlaylistOnlyMessage),
                      ),
                    );
                    return;
                  }
                  showLocalPreviewStartedSnackBar(
                    ctx,
                    spaceName: session.currentSpace?.name,
                  );
                  ctx.read<PlayerBloc>().add(PlayerPlaylistStarted(
                        tracks: _tracks,
                        startIndex: i,
                        playlistName: album.name,
                      ));
                },
              );
            },
            childCount: album.songs.length,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 160)),
      ],
    );
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
        child: Icon(Icons.album, color: Colors.grey.shade400, size: 72),
      ),
    );
  }
}

// ── Palette ─────────────────────────────────────────────────────────────────
class _Palette {
  const _Palette({
    required this.isDark,
    required this.bg,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
  });

  factory _Palette.fromBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    if (isDark) {
      return _Palette(
        isDark: true,
        bg: AppColors.backgroundDarkPrimary,
        card: AppColors.surfaceDark,
        border: AppColors.borderDarkMedium,
        textPrimary: AppColors.textDarkPrimary,
        textMuted: AppColors.textDarkSecondary,
        accent: AppColors.primaryCyan,
      );
    }
    return const _Palette(
      isDark: false,
      bg: AppColors.backgroundPrimary,
      card: AppColors.surface,
      border: AppColors.borderLight,
      textPrimary: AppColors.textPrimary,
      textMuted: AppColors.textTertiary,
      accent: AppColors.primaryOrange,
    );
  }

  final bool isDark;
  final Color bg;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;
}
