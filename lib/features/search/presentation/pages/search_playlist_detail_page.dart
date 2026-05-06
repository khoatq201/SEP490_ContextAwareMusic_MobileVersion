import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/enums/queue_insert_mode_enum.dart';
import '../../../../core/widgets/playlist_cover_collage.dart';
import '../../../../core/widgets/play_to_space_button.dart';
import '../../../../core/widgets/shared_catalog_badge.dart';
import '../../../../core/widgets/song_list_tile.dart';
import '../../../../core/widgets/song_options_bottom_sheet.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/player/player_event.dart';
import '../../../../core/player/local_preview_feedback.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/theme/cams_theme_tokens.dart';
import '../../../../core/utils/cams_queue_actions.dart';
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
    final palette = _Palette.fromContext(context);

    final tracks = playlist.songs
        .map((s) => Track(
              id: s.id,
              brandId: s.brandId,
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
                  color: Colors.black.withValues(alpha: 0.35),
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
                coverUrls: playlist.trackCoverUrls,
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(LucideIcons.music4,
                          color: palette.textMuted, size: 14),
                      Text(
                        '${playlist.totalTracks} tracks',
                        style: GoogleFonts.inter(
                          color: palette.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(LucideIcons.clock,
                          color: palette.textMuted, size: 14),
                      Text(
                        _formatDuration(playlist.totalDuration),
                        style: GoogleFonts.inter(
                          color: palette.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (playlist.isSharedCatalog)
                        const SharedCatalogBadge(compact: true),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // "Play to Space" button (role-aware)
                  PlayToSpaceButton(
                    tracks: tracks,
                    playlistName: playlist.title,
                  ),

                  const SizedBox(height: 4),
                  Divider(
                      color: palette.border.withValues(alpha: 0.6), height: 28),
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
                    final session = ctx.read<SessionCubit>().state;
                    if (!session.isPlaybackDevice) {
                      showTrackQueueModePickerAndQueue(
                        ctx,
                        trackId: song.id,
                        playlistId: playlist.id,
                        title: song.title,
                        source: 'Search playlist tap',
                      );
                      return;
                    }
                    showLocalPreviewStartedSnackBar(
                      ctx,
                      spaceName: session.currentSpace?.name,
                    );
                    ctx.read<PlayerBloc>().add(PlayerPlaylistStarted(
                          tracks: tracks,
                          startIndex: i,
                          playlistName: playlist.title,
                        ));
                  },
                  showPlayNext: true,
                  enableAddToQueue: true,
                  addToQueueLabel: 'Add to space queue',
                  forwardPlayNowToOptionHandler: true,
                  onOptionSelected: (option) {
                    final mode = switch (option) {
                      SongOption.playNow => QueueInsertModeEnum.playNow,
                      SongOption.playNext => QueueInsertModeEnum.playNext,
                      SongOption.addToQueue => QueueInsertModeEnum.addToQueue,
                      _ => null,
                    };
                    if (mode == null) return;
                    queueTrackToCurrentSpace(
                      ctx,
                      trackId: song.id,
                      playlistId: playlist.id,
                      mode: mode,
                      reason: buildQueueActionReason(
                        source: 'Search playlist',
                        itemType: 'track',
                        mode: mode,
                      ),
                    );
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
  final List<String> coverUrls;
  final String? coverUrl;
  final _Palette palette;
  const _CoverBackground({
    required this.coverUrls,
    required this.coverUrl,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return PlaylistCoverCollage(
      coverUrls: coverUrls,
      fallbackCoverUrl: coverUrl,
      backgroundColor: palette.bg,
      iconColor: palette.textMuted,
      iconSize: 72,
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

  factory _Palette.fromContext(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.camsTokens;
    return _Palette(
      isDark: theme.brightness == Brightness.dark,
      bg: tokens.bgBase,
      border: tokens.border,
      textPrimary: tokens.textPrimary,
      textMuted: tokens.textSecondary,
    );
  }

  final bool isDark;
  final Color bg;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
}
