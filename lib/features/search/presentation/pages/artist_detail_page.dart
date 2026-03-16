import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/player/player_event.dart';
import '../../../../core/player/local_preview_feedback.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/widgets/song_list_tile.dart';
import '../../../../injection_container.dart';
import '../../../space_control/domain/entities/track.dart';
import '../../domain/entities/artist_entity.dart';
import '../bloc/artist_detail_cubit.dart';

class ArtistDetailPage extends StatelessWidget {
  final String artistId;

  const ArtistDetailPage({super.key, required this.artistId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ArtistDetailCubit>()..load(artistId),
      child: const _ArtistDetailView(),
    );
  }
}

class _ArtistDetailView extends StatelessWidget {
  const _ArtistDetailView();

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.fromBrightness(Theme.of(context).brightness);

    return Scaffold(
      backgroundColor: palette.bg,
      body: BlocBuilder<ArtistDetailCubit, ArtistDetailState>(
        builder: (context, state) {
          if (state.status == ArtistDetailStatus.loading ||
              state.status == ArtistDetailStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == ArtistDetailStatus.error) {
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

          final artist = state.artist!;
          return _ArtistBody(artist: artist, palette: palette);
        },
      ),
    );
  }
}

class _ArtistBody extends StatelessWidget {
  final ArtistEntity artist;
  final _Palette palette;

  const _ArtistBody({required this.artist, required this.palette});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── SliverAppBar with large artist image ──────────────────────
        SliverAppBar(
          pinned: true,
          expandedHeight: 280,
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
              artist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 6),
                ],
              ),
            ),
            background: _ArtistCoverBackground(
              imageUrl: artist.imageUrl,
              palette: palette,
            ),
          ),
        ),

        // ── Artist info ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bio
                if (artist.bio != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    artist.bio!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: palette.textMuted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],

                const SizedBox(height: 4),
                Divider(color: palette.border.withOpacity(0.6), height: 28),
              ],
            ),
          ),
        ),

        // ── Popular songs section ─────────────────────────────────────
        if (artist.popularSongs.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingMd),
              child: Text(
                'Popular',
                style: AppTypography.titleMedium.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final song = artist.popularSongs[i];
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
                    final tracks = artist.popularSongs
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
                    showLocalPreviewStartedSnackBar(
                      ctx,
                      spaceName: session.currentSpace?.name,
                    );
                    ctx.read<PlayerBloc>().add(PlayerPlaylistStarted(
                          tracks: tracks,
                          startIndex: i,
                          playlistName: '${artist.name} – Popular',
                        ));
                  },
                );
              },
              childCount: artist.popularSongs.length,
            ),
          ),
        ],

        // ── Albums section (horizontal scrollable) ────────────────────
        if (artist.albums.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spacingMd, 24, AppDimensions.spacingMd, 12),
              child: Text(
                'Albums',
                style: AppTypography.titleMedium.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingMd),
                itemCount: artist.albums.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppDimensions.spacingSm),
                itemBuilder: (ctx, i) {
                  final album = artist.albums[i];
                  return GestureDetector(
                    onTap: () => ctx.push('/search/album/${album.id}'),
                    child: SizedBox(
                      width: 140,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusMd),
                              child: album.coverUrl != null
                                  ? Image.network(
                                      album.coverUrl!,
                                      width: 140,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _CoverFallback(palette: palette),
                                    )
                                  : _CoverFallback(palette: palette),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            album.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: palette.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (album.releaseYear != null)
                            Text(
                              album.releaseYear.toString(),
                              style: GoogleFonts.inter(
                                color: palette.textMuted,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 160)),
      ],
    );
  }
}

// ── Artist cover background ─────────────────────────────────────────────────
class _ArtistCoverBackground extends StatelessWidget {
  final String? imageUrl;
  final _Palette palette;
  const _ArtistCoverBackground({required this.imageUrl, required this.palette});

  @override
  Widget build(BuildContext context) {
    final image = imageUrl != null
        ? Image.network(imageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => _AvatarFallback(palette: palette))
        : _AvatarFallback(palette: palette);

    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        // Gradient overlay for readability
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                palette.bg.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final _Palette palette;
  const _AvatarFallback({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: palette.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      child: Center(
        child: Icon(Icons.person, size: 72, color: Colors.grey.shade400),
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  final _Palette palette;
  const _CoverFallback({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: palette.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      child: Center(
        child: Icon(LucideIcons.music4, size: 48, color: Colors.grey.shade400),
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
