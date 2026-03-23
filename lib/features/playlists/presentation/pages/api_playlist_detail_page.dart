import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/player/player_event.dart';
import '../../../../core/player/playlist_queue_builder.dart';
import '../../../../core/presentation/shell_layout_metrics.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/widgets/select_playlist_bottom_sheet.dart';
import '../../../../core/widgets/song_options_bottom_sheet.dart';
import '../../../../injection_container.dart';
import '../../../home/domain/entities/song_entity.dart';
import '../../../cams/presentation/bloc/cams_playback_bloc.dart';
import '../../../cams/presentation/bloc/cams_playback_event.dart';
import '../../../cams/presentation/bloc/cams_playback_state.dart';
import '../../../space_control/data/datasources/space_remote_datasource.dart';
import '../../../space_control/domain/entities/space.dart';
import '../../domain/entities/api_playlist.dart';
import '../../domain/entities/playlist_track_item.dart';

/// Detail page for a backend ApiPlaylist (with HLS streaming & CAMS override).
class ApiPlaylistDetailPage extends StatelessWidget {
  final ApiPlaylist playlist;

  const ApiPlaylistDetailPage({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.fromBrightness(Theme.of(context).brightness);
    final hasMiniPlayer =
        context.select((PlayerBloc bloc) => bloc.state.hasTrack);
    final bottomSpacing = ShellLayoutMetrics.reservedBottom(
      context,
      hasMiniPlayer: hasMiniPlayer,
      extra: 24,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _CoverSliverAppBar(playlist: playlist, palette: palette),
          SliverToBoxAdapter(
            child: _PlaylistHeader(playlist: playlist, palette: palette)
                .animate()
                .fadeIn(duration: 320.ms)
                .slideY(begin: 0.06),
          ),
          if (playlist.tracks != null && playlist.tracks!.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = playlist.tracks![index];
                  return _TrackTile(
                    track: track,
                    index: index,
                    palette: palette,
                    playlist: playlist,
                  )
                      .animate()
                      .fadeIn(duration: 280.ms, delay: (index * 40).ms)
                      .slideX(begin: 0.05);
                },
                childCount: playlist.tracks!.length,
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'No tracks in this playlist',
                    style: GoogleFonts.inter(
                      color: palette.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: bottomSpacing)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SliverAppBar — cover image
// ─────────────────────────────────────────────────────────────────────────────
class _CoverSliverAppBar extends StatelessWidget {
  const _CoverSliverAppBar({required this.playlist, required this.palette});
  final ApiPlaylist playlist;
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
          playlist.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: palette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        background: Container(
          color: palette.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          child: Center(
            child:
                Icon(Icons.music_note, color: Colors.grey.shade400, size: 72),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header — title, description, metadata, Play All button
// ─────────────────────────────────────────────────────────────────────────────
class _PlaylistHeader extends StatelessWidget {
  const _PlaylistHeader({required this.playlist, required this.palette});
  final ApiPlaylist playlist;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            playlist.name,
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

          // Meta row: track count · duration · mood
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetaChip(
                icon: LucideIcons.music4,
                text: '${playlist.trackCount} tracks',
                palette: palette,
              ),
              _dotSeparator(),
              _MetaChip(
                icon: LucideIcons.clock,
                text: playlist.formattedDuration,
                palette: palette,
              ),
              if (playlist.moodName != null) ...[
                _dotSeparator(),
                _MetaChip(
                  icon: LucideIcons.sparkles,
                  text: playlist.moodName!,
                  palette: palette,
                ),
              ],
              if (playlist.storeName != null) ...[
                _dotSeparator(),
                _MetaChip(
                  icon: LucideIcons.store,
                  text: playlist.storeName!,
                  palette: palette,
                ),
              ],
            ],
          ),

          // HLS readiness indicator
          if (playlist.isStreamReady) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(LucideIcons.wifi, color: Colors.green.shade400, size: 14),
                const SizedBox(width: 5),
                Text(
                  'HLS stream ready',
                  style: GoogleFonts.inter(
                    color: Colors.green.shade400,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 18),

          // Play All / Override to Space button — role-based behavior
          BlocBuilder<CamsPlaybackBloc, CamsPlaybackState>(
            builder: (context, camsState) {
              final session = context.watch<SessionCubit>().state;
              final isPlaybackDevice = session.isPlaybackDevice;
              final isOverriding = camsState.isOverriding;
              final hasSpace = session.currentSpace != null;

              return Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: isOverriding
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(LucideIcons.play, size: 18),
                      label: Text(
                        isPlaybackDevice
                            ? 'Play on This Device'
                            : hasSpace
                                ? 'Play to ${session.currentSpace!.name}'
                                : 'Select Space & Play',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: isOverriding
                          ? null
                          : () => _handlePlayAction(
                                context: context,
                                playlist: playlist,
                                session: session,
                                palette: palette,
                              ),
                    ),
                  ),
                  if (isPlaybackDevice && hasSpace) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Playing on: ${session.currentSpace!.name}',
                      style: GoogleFonts.inter(
                        color: palette.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else if (!isPlaybackDevice && hasSpace) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _showSpacePickerSheet(
                        context: context,
                        playlist: playlist,
                        palette: palette,
                      ),
                      child: Text(
                        'Change space',
                        style: GoogleFonts.inter(
                          color: palette.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),

          const SizedBox(height: 4),
          Divider(color: palette.border.withOpacity(0.6), height: 28),
        ],
      ),
    );
  }

  Widget _dotSeparator() {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: palette.textMuted,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.text,
    required this.palette,
  });
  final IconData icon;
  final String text;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: palette.textMuted, size: 14),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.inter(
            color: palette.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Track tile — tap to play this track in the selected playlist.
// ─────────────────────────────────────────────────────────────────────────────
class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.track,
    required this.index,
    required this.palette,
    required this.playlist,
  });
  final PlaylistTrackItem track;
  final int index;
  final _Palette palette;
  final ApiPlaylist playlist;

  @override
  Widget build(BuildContext context) {
    final mappedSong = SongEntity(
      id: track.trackId,
      title: track.title ?? 'Unknown Track',
      artist: track.artist ?? 'Unknown Artist',
      duration: track.effectiveDuration,
      coverUrl: track.coverImageUrl,
    );

    return InkWell(
      onTap: () {
        _playTrackToCurrentSpace(
          context: context,
          playlist: playlist,
          track: track,
          palette: _Palette.fromBrightness(Theme.of(context).brightness),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            // Track number
            SizedBox(
              width: 28,
              child: Text(
                '${index + 1}',
                style: GoogleFonts.inter(
                  color: palette.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Cover image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: track.coverImageUrl != null
                  ? Image.network(
                      track.coverImageUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _trackPlaceholder(palette),
                    )
                  : _trackPlaceholder(palette),
            ),

            const SizedBox(width: 12),

            // Title + Artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title ?? 'Unknown Track',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: palette.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (track.artist != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      track.artist!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: palette.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Duration
            Text(
              track.formattedDuration,
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: palette.textMuted,
                size: 20,
              ),
              splashRadius: 20,
              onPressed: () async {
                final option = await showModalBottomSheet<SongOption>(
                  context: context,
                  useRootNavigator: true,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => SongOptionsBottomSheet(song: mappedSong),
                );
                if (!context.mounted || option == null) return;

                switch (option) {
                  case SongOption.addToPlaylist:
                    await showModalBottomSheet<void>(
                      context: context,
                      useRootNavigator: true,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) =>
                          SelectPlaylistBottomSheet(song: mappedSong),
                    );
                    break;
                  case SongOption.playNow:
                    _playTrackToCurrentSpace(
                      context: context,
                      playlist: playlist,
                      track: track,
                      palette: _Palette.fromBrightness(
                        Theme.of(context).brightness,
                      ),
                    );
                    break;
                  case SongOption.addToQueue:
                  case SongOption.goToAlbum:
                  case SongOption.goToArtist:
                  case SongOption.block:
                  case SongOption.share:
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget _trackPlaceholder(_Palette palette) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: palette.overlay,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.music_note, color: palette.textMuted, size: 20),
    );
  }
}

void _playTrackToCurrentSpace({
  required BuildContext context,
  required ApiPlaylist playlist,
  required PlaylistTrackItem track,
  required _Palette palette,
}) {
  _seedPlaylistQueue(context, playlist, force: true);

  final session = context.read<SessionCubit>().state;
  final hasSpace = session.currentSpace != null;

  if (!hasSpace) {
    _showSpacePickerSheet(
      context: context,
      playlist: playlist,
      palette: palette,
    );
    return;
  }

  context.read<CamsPlaybackBloc>().add(CamsPlayPlaylistTrack(
        playlistId: playlist.id,
        targetTrackId: track.trackId,
        reason: 'Manual track selection',
      ));
}

void _seedPlaylistQueue(
  BuildContext context,
  ApiPlaylist playlist, {
  bool force = false,
}) {
  final queue = buildPlaylistQueue(playlist);

  context.read<PlayerBloc>().add(PlayerQueueSeeded(
        tracks: queue,
        playlistName: playlist.name,
        playlistId: playlist.id,
        force: force,
      ));
}

// ─────────────────────────────────────────────────────────────────────────────
// Play action helpers — shared by header and track tile
// ─────────────────────────────────────────────────────────────────────────────

/// Called when the user taps the main "Play" button.
/// • Playback device → init CAMS for its own space (already set).
/// • Manager with space → override playlist to current space.
/// • Manager without space → show space picker sheet first.
void _handlePlayAction({
  required BuildContext context,
  required ApiPlaylist playlist,
  required dynamic session,
  required _Palette palette,
}) {
  _seedPlaylistQueue(context, playlist, force: true);

  final hasSpace = session.currentSpace != null;

  if (session.isPlaybackDevice || hasSpace) {
    // Ensure CAMS is inited for this space and override playlist
    final spaceId = session.currentSpace?.id;
    if (spaceId != null) {
      final camsBloc = context.read<CamsPlaybackBloc>();
      if (camsBloc.state.spaceId != spaceId) {
        camsBloc.add(CamsInitPlayback(spaceId: spaceId));
      }
      camsBloc.add(CamsOverridePlaylist(
        playlistId: playlist.id,
        reason: 'Manual playlist selection',
      ));
    }
  } else {
    // No space selected — show picker
    _showSpacePickerSheet(
      context: context,
      playlist: playlist,
      palette: palette,
    );
  }
}

/// Shows a bottom sheet for the user to pick a space, then
/// updates [SessionCubit] and triggers the CAMS override.
void _showSpacePickerSheet({
  required BuildContext context,
  required ApiPlaylist playlist,
  required _Palette palette,
}) {
  final session = context.read<SessionCubit>().state;
  final storeId = session.currentStore?.id;
  if (storeId == null) {
    // No store either — navigate to store selection
    context.go('/store-selection');
    return;
  }

  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: palette.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _SpacePickerSheet(
      storeId: storeId,
      playlist: playlist,
      palette: palette,
      camsBloc: context.read<CamsPlaybackBloc>(),
      sessionCubit: context.read<SessionCubit>(),
    ),
  );
}

/// Bottom sheet to pick a space for playback, then override the playlist.
class _SpacePickerSheet extends StatefulWidget {
  const _SpacePickerSheet({
    required this.storeId,
    required this.playlist,
    required this.palette,
    required this.camsBloc,
    required this.sessionCubit,
  });
  final String storeId;
  final ApiPlaylist playlist;
  final _Palette palette;
  final CamsPlaybackBloc camsBloc;
  final SessionCubit sessionCubit;

  @override
  State<_SpacePickerSheet> createState() => _SpacePickerSheetState();
}

class _SpacePickerSheetState extends State<_SpacePickerSheet> {
  late Future<List<Space>> _spacesFuture;

  @override
  void initState() {
    super.initState();
    _spacesFuture = sl<SpaceRemoteDataSource>().getSpaces(widget.storeId);
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Select a Space to Play',
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '"${widget.playlist.name}" will play on the selected space.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Space>>(
            future: _spacesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(color: palette.accent),
                );
              }
              if (snapshot.hasError || snapshot.data == null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Failed to load spaces. Please try again.',
                    style: GoogleFonts.inter(
                      color: palette.textMuted,
                      fontSize: 13,
                    ),
                  ),
                );
              }

              final spaces = snapshot.data!;
              if (spaces.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No spaces found for this store.',
                    style: GoogleFonts.inter(
                      color: palette.textMuted,
                      fontSize: 13,
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: spaces.length,
                separatorBuilder: (_, __) => Divider(
                  color: palette.border.withOpacity(0.5),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final space = spaces[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: palette.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(LucideIcons.store,
                          color: palette.accent, size: 18),
                    ),
                    title: Text(
                      space.name,
                      style: GoogleFonts.inter(
                        color: palette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: space.description != null
                        ? Text(
                            space.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: palette.textMuted,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    onTap: () {
                      // Update session with selected space
                      widget.sessionCubit.changeSpace(space);
                      Navigator.pop(context);

                      // Init CAMS for the newly selected space and override
                      widget.camsBloc.add(CamsInitPlayback(spaceId: space.id));
                      widget.camsBloc.add(CamsOverridePlaylist(
                        playlistId: widget.playlist.id,
                        reason: 'Manual playlist selection',
                      ));
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Palette — same as playlist_detail_page.dart
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
