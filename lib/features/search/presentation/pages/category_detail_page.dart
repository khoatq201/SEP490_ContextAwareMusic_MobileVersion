import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/enums/queue_insert_mode_enum.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/presentation/shell_layout_metrics.dart';
import '../../../../core/theme/cams_theme_tokens.dart';
import '../../../../core/utils/cams_queue_actions.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/cams_skeleton.dart';
import '../../../../core/widgets/playlist_cover_collage.dart';
import '../../../../core/widgets/shared_catalog_badge.dart';
import '../../../../core/widgets/song_list_tile.dart';
import '../../../../core/widgets/song_options_bottom_sheet.dart';
import '../../../../injection_container.dart';
import '../../../home/domain/entities/playlist_entity.dart';
import '../../../home/domain/entities/song_entity.dart';
import '../../domain/entities/search_result.dart';
import '../bloc/category_detail_cubit.dart';

class CategoryDetailPage extends StatelessWidget {
  final String categoryId;
  final String? categoryName;
  final CategoryDetailSource source;

  const CategoryDetailPage({
    super.key,
    required this.categoryId,
    this.categoryName,
    this.source = CategoryDetailSource.mood,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<CategoryDetailCubit>();
        switch (source) {
          case CategoryDetailSource.mood:
            cubit.load(categoryId);
            break;
          case CategoryDetailSource.genre:
            cubit.loadGenre(categoryId);
            break;
        }
        return cubit;
      },
      child: _CategoryDetailView(
        categoryId: categoryId,
        categoryName: categoryName ?? 'Category',
        source: source,
      ),
    );
  }
}

enum CategoryDetailSource { mood, genre }

class _CategoryDetailView extends StatelessWidget {
  final String categoryId;
  final String categoryName;
  final CategoryDetailSource source;
  const _CategoryDetailView({
    required this.categoryId,
    required this.categoryName,
    required this.source,
  });

  void _reload(BuildContext context) {
    final cubit = context.read<CategoryDetailCubit>();
    switch (source) {
      case CategoryDetailSource.mood:
        cubit.load(categoryId);
        break;
      case CategoryDetailSource.genre:
        cubit.loadGenre(categoryId);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDarkPrimary
          : AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.backgroundDarkPrimary
            : AppColors.backgroundPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.chevronLeft,
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
        title: Text(
          categoryName,
          style: GoogleFonts.poppins(
            color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<CategoryDetailCubit, CategoryDetailState>(
        builder: (context, state) {
          if (state.status == CategoryDetailStatus.loading ||
              state.status == CategoryDetailStatus.initial) {
            return const CamsSkeletonCardGrid(
              itemCount: 8,
              childAspectRatio: 0.85,
              padding: EdgeInsets.all(AppDimensions.spacingMd),
            );
          }
          if (state.status == CategoryDetailStatus.error) {
            return AppErrorView(
              failure: state.failure,
              title: source == CategoryDetailSource.genre
                  ? 'Genre unavailable'
                  : 'Category unavailable',
              onRetry: () => _reload(context),
              onSecondaryAction: () => context.pop(),
              secondaryLabel: 'Go back',
            );
          }

          return _CategoryContent(
            playlists: state.playlists,
            tracks: state.tracks,
            categoryName: categoryName,
            source: source,
            isDark: isDark,
          );
        },
      ),
    );
  }
}

bool _isCategoryTrackPlayable(SearchResult result) => result.isPlayableTrack;

String _categoryTrackPlaybackTagLabel(SearchResult result) {
  return result.copyrightClearanceStatus?.displayName ?? 'Unknown';
}

String _categoryTrackPlaybackMessage(SearchResult result) {
  final clearance = result.copyrightClearanceStatus;
  if (clearance == null) {
    return 'This track is missing playback clearance data.';
  }
  if (!clearance.isPlayable) {
    return 'This track cannot be played until copyright clearance is ${clearance.displayName.toLowerCase()}.';
  }
  final trackStatus = result.trackStatus;
  if (trackStatus == null || !trackStatus.isActive) {
    return 'This track is not active.';
  }
  return 'This track is not available for playback.';
}

void _showCategoryTrackPlaybackBlocked(
  BuildContext context,
  SearchResult result,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(_categoryTrackPlaybackMessage(result))),
  );
}

SongEntity _categoryTrackToSongEntity(SearchResult result) {
  return SongEntity(
    id: result.id,
    brandId: result.brandId,
    title: result.title,
    artist: result.subtitle,
    duration: result.durationSeconds ?? 0,
    coverUrl: result.imageUrl ?? result.thumbnailUrl,
    streamUrl: result.streamUrl,
  );
}

String? _categoryTrackArtistName(SearchResult result) {
  return navigableSongArtist(result.subtitle);
}

void _playCategoryTrackOrShowMessage(
  BuildContext context,
  SearchResult result,
) {
  if (!_isCategoryTrackPlayable(result)) {
    _showCategoryTrackPlaybackBlocked(context, result);
    return;
  }

  showTrackQueueModePickerAndQueue(
    context,
    trackId: result.id,
    title: result.title,
    source: 'Search category tap',
  );
}

Future<void> _handleCategoryTrackOption(
  BuildContext context,
  SearchResult result,
  SongOption option,
) async {
  if (option == SongOption.goToArtist) {
    final artist = _categoryTrackArtistName(result);
    if (artist == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This track has no artist information.')),
      );
      return;
    }
    context.go('/search/artist/${Uri.encodeComponent(artist)}');
    return;
  }

  if (!_isCategoryTrackPlayable(result)) {
    _showCategoryTrackPlaybackBlocked(context, result);
    return;
  }

  final mode = switch (option) {
    SongOption.playNow => QueueInsertModeEnum.playNow,
    SongOption.playNext => QueueInsertModeEnum.playNext,
    SongOption.addToQueue => QueueInsertModeEnum.addToQueue,
    _ => null,
  };
  if (mode == null) return;

  queueTrackToCurrentSpace(
    context,
    trackId: result.id,
    mode: mode,
    reason: buildQueueActionReason(
      source: 'Search category',
      itemType: 'track',
      mode: mode,
    ),
  );
}

class _CategoryContent extends StatelessWidget {
  final List<PlaylistEntity> playlists;
  final List<SearchResult> tracks;
  final String categoryName;
  final CategoryDetailSource source;
  final bool isDark;

  const _CategoryContent({
    required this.playlists,
    required this.tracks,
    required this.categoryName,
    required this.source,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    var hasMiniPlayer = false;
    try {
      hasMiniPlayer = context.watch<PlayerBloc>().state.hasTrack;
    } catch (_) {
      hasMiniPlayer = false;
    }
    final bottomSpacing = ShellLayoutMetrics.reservedBottom(
      context,
      hasMiniPlayer: hasMiniPlayer,
      extra: 24,
    );

    if (playlists.isEmpty && tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.music4,
              size: 64,
              color:
                  isDark ? AppColors.textDarkTertiary : AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              source == CategoryDetailSource.genre
                  ? 'No tracks in this genre'
                  : 'No playlists or tracks in this mood',
              style: TextStyle(
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        if (source == CategoryDetailSource.mood && playlists.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionTitle(title: 'Playlists', isDark: isDark),
          ),
          SliverToBoxAdapter(
            child: _PlaylistGrid(playlists: playlists, isDark: isDark),
          ),
        ],
        if (tracks.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionTitle(title: 'Tracks', isDark: isDark),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, index) {
                final result = tracks[index];
                final song = _categoryTrackToSongEntity(result);
                final isPlayable = _isCategoryTrackPlayable(result);
                return SongListTile(
                  song: song,
                  enabled: isPlayable,
                  optionsEnabled: true,
                  badge: _CategoryPlaybackTag(
                    label: _categoryTrackPlaybackTagLabel(result),
                    isPlayable: isPlayable,
                  ),
                  onTap: () => _playCategoryTrackOrShowMessage(ctx, result),
                  showPlayNext: true,
                  enableAddToQueue: isPlayable,
                  addToQueueLabel: 'Add to space queue',
                  enableGoToArtist: _categoryTrackArtistName(result) != null,
                  forwardPlayNowToOptionHandler: true,
                  onOptionSelected: (option) =>
                      _handleCategoryTrackOption(ctx, result, option),
                );
              },
              childCount: tracks.length,
            ),
          ),
        ],
        SliverToBoxAdapter(child: SizedBox(height: bottomSpacing)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingMd,
        AppDimensions.spacingMd,
        AppDimensions.spacingMd,
        AppDimensions.spacingSm,
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlaylistGrid extends StatelessWidget {
  final List<PlaylistEntity> playlists;
  final bool isDark;
  const _PlaylistGrid({required this.playlists, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingMd,
        0,
        AppDimensions.spacingMd,
        AppDimensions.spacingMd,
      ),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppDimensions.spacingSm,
        mainAxisSpacing: AppDimensions.spacingMd,
        childAspectRatio: 0.75,
      ),
      itemCount: playlists.length,
      itemBuilder: (ctx, i) {
        final playlist = playlists[i];
        return GestureDetector(
          onTap: () => ctx.push('/search/playlist/${playlist.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  child: PlaylistCoverCollage(
                    coverUrls: playlist.trackCoverUrls,
                    fallbackCoverUrl: playlist.coverUrl,
                    backgroundColor: isDark
                        ? AppColors.backgroundDarkTertiary
                        : AppColors.backgroundSecondary,
                    iconColor: isDark
                        ? AppColors.textDarkTertiary
                        : AppColors.textTertiary,
                    iconSize: 34,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                playlist.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: isDark
                      ? AppColors.textDarkPrimary
                      : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (playlist.description != null)
                Text(
                  playlist.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: isDark
                        ? AppColors.textDarkTertiary
                        : AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              if (playlist.isSharedCatalog) ...[
                const SizedBox(height: 4),
                const SharedCatalogBadge(compact: true),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CategoryPlaybackTag extends StatelessWidget {
  const _CategoryPlaybackTag({
    required this.label,
    required this.isPlayable,
  });

  final String label;
  final bool isPlayable;

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    final accent = isPlayable ? tokens.success : tokens.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: accent,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
