import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/enums/queue_insert_mode_enum.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/presentation/shell_layout_metrics.dart';
import '../../../../core/theme/cams_theme_tokens.dart';
import '../../../../core/utils/cams_queue_actions.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_inline_error_card.dart';
import '../../../../core/widgets/cams_skeleton.dart';
import '../../../../core/widgets/playlist_cover_collage.dart';
import '../../../../core/widgets/queue_mode_picker_bottom_sheet.dart';
import '../../../../core/widgets/select_playlist_bottom_sheet.dart';
import '../../../../core/widgets/shared_catalog_badge.dart';
import '../../../../core/widgets/song_list_tile.dart';
import '../../../../core/widgets/song_options_bottom_sheet.dart';
import '../../../../injection_container.dart';
import '../../../home/domain/entities/playlist_entity.dart';
import '../../../home/domain/entities/song_entity.dart';
import '../../domain/entities/search_category.dart';
import '../../domain/entities/search_filter_tag.dart';
import '../../domain/entities/search_result.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';

// ===========================================================================
// SearchTabPage – entry point (wires up BlocProvider from DI)
// ===========================================================================
class SearchTabPage extends StatelessWidget {
  const SearchTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SearchBloc>()..add(const LoadCategoriesEvent()),
      child: const _SearchView(),
    );
  }
}

bool _isSearchSongPlayable(SearchResult result) => result.isPlayableTrack;

String? _searchResultArtistName(SearchResult result) {
  return navigableSongArtist(result.subtitle);
}

const List<SearchCategory> _popularGenres = [
  SearchCategory(
    id: 'Pop',
    name: 'Pop',
    color: Color(0xFFEF4444),
    icon: Icons.auto_awesome,
  ),
  SearchCategory(
    id: 'Rock',
    name: 'Rock',
    color: Color(0xFF7C2D12),
    icon: Icons.music_note,
  ),
  SearchCategory(
    id: 'Jazz',
    name: 'Jazz',
    color: Color(0xFFCA8A04),
    icon: Icons.graphic_eq,
  ),
  SearchCategory(
    id: 'Classical',
    name: 'Classical',
    color: Color(0xFF6D28D9),
    icon: Icons.piano,
  ),
  SearchCategory(
    id: 'Electronic',
    name: 'Electronic',
    color: Color(0xFF0891B2),
    icon: Icons.speaker,
  ),
  SearchCategory(
    id: 'Hip Hop',
    name: 'Hip Hop',
    color: Color(0xFFBE123C),
    icon: Icons.mic,
  ),
  SearchCategory(
    id: 'R&B',
    name: 'R&B',
    color: Color(0xFF9333EA),
    icon: Icons.headphones,
  ),
  SearchCategory(
    id: 'Country',
    name: 'Country',
    color: Color(0xFF15803D),
    icon: Icons.place,
  ),
  SearchCategory(
    id: 'Folk',
    name: 'Folk',
    color: Color(0xFFB45309),
    icon: Icons.eco,
  ),
  SearchCategory(
    id: 'Latin',
    name: 'Latin',
    color: Color(0xFFDB2777),
    icon: Icons.local_fire_department,
  ),
  SearchCategory(
    id: 'Ambient',
    name: 'Ambient',
    color: Color(0xFF0F766E),
    icon: Icons.cloud,
  ),
  SearchCategory(
    id: 'Lo-fi',
    name: 'Lo-fi',
    color: Color(0xFF475569),
    icon: Icons.waves,
  ),
  SearchCategory(
    id: 'Indie',
    name: 'Indie',
    color: Color(0xFF4D7C0F),
    icon: Icons.album,
  ),
  SearchCategory(
    id: 'Blues',
    name: 'Blues',
    color: Color(0xFF1D4ED8),
    icon: Icons.queue_music,
  ),
  SearchCategory(
    id: 'Reggae',
    name: 'Reggae',
    color: Color(0xFFF59E0B),
    icon: Icons.wb_sunny,
  ),
];

String _searchPlaybackTagLabel(SearchResult result) {
  return result.copyrightClearanceStatus?.displayName ?? 'Unknown';
}

String _searchSongPlaybackMessage(SearchResult result) {
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

void _showSearchSongPlaybackBlocked(
  BuildContext context,
  SearchResult result,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(_searchSongPlaybackMessage(result))),
  );
}

void _playSearchSongOrShowMessage(
  BuildContext context,
  SearchResult result,
) {
  if (!_isSearchSongPlayable(result)) {
    _showSearchSongPlaybackBlocked(context, result);
    return;
  }

  showTrackQueueModePickerAndQueue(
    context,
    trackId: result.id,
    title: result.title,
    source: 'Search tap',
  );
}

SongEntity _searchResultToSongEntity(SearchResult result) {
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

Future<void> _handleSearchSongOption(
  BuildContext context,
  SearchResult result,
  SongOption option,
) async {
  if (option == SongOption.goToArtist) {
    final artist = _searchResultArtistName(result);
    if (artist == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This track has no artist information.')),
      );
      return;
    }
    context.go('/search/artist/${Uri.encodeComponent(artist)}');
    return;
  }

  if (option != SongOption.addToPlaylist && !_isSearchSongPlayable(result)) {
    _showSearchSongPlaybackBlocked(context, result);
    return;
  }

  final song = _searchResultToSongEntity(result);

  switch (option) {
    case SongOption.addToPlaylist:
      await showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SelectPlaylistBottomSheet(song: song),
      );
      return;
    case SongOption.playNow:
      queueTrackToCurrentSpace(
        context,
        trackId: result.id,
        mode: QueueInsertModeEnum.playNow,
        reason: buildQueueActionReason(
          source: 'Search',
          itemType: 'track',
          mode: QueueInsertModeEnum.playNow,
        ),
      );
      return;
    case SongOption.playNext:
      queueTrackToCurrentSpace(
        context,
        trackId: result.id,
        mode: QueueInsertModeEnum.playNext,
        reason: buildQueueActionReason(
          source: 'Search',
          itemType: 'track',
          mode: QueueInsertModeEnum.playNext,
        ),
      );
      return;
    case SongOption.addToQueue:
      queueTrackToCurrentSpace(
        context,
        trackId: result.id,
        mode: QueueInsertModeEnum.addToQueue,
        reason: buildQueueActionReason(
          source: 'Search',
          itemType: 'track',
          mode: QueueInsertModeEnum.addToQueue,
        ),
      );
      return;
    case SongOption.goToAlbum:
    case SongOption.goToArtist:
    case SongOption.block:
    case SongOption.share:
      return;
  }
}

Future<void> _openSearchSongOptions(
  BuildContext context,
  SearchResult result,
) async {
  final option = await showModalBottomSheet<SongOption>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SongOptionsBottomSheet(
      song: _searchResultToSongEntity(result),
      showPlayNow: true,
      showPlayNext: true,
      enableAddToQueue: _isSearchSongPlayable(result),
      addToQueueLabel: 'Add to space queue',
      enableGoToArtist: _searchResultArtistName(result) != null,
    ),
  );

  if (!context.mounted || option == null) return;
  await _handleSearchSongOption(context, result, option);
}

Future<void> _openSearchPlaylistOptions(
  BuildContext context, {
  required String playlistId,
  required String playlistTitle,
  String source = 'Search',
}) async {
  final mode = await showQueueModePickerBottomSheet(
    context,
    title: 'Add playlist to queue',
    subtitle: playlistTitle,
  );
  if (!context.mounted || mode == null) return;

  queuePlaylistToCurrentSpace(
    context,
    playlistId: playlistId,
    mode: mode,
    reason: buildQueueActionReason(
      source: source,
      itemType: 'playlist',
      mode: mode,
    ),
  );
}

// ===========================================================================
// _SearchView
// ===========================================================================
class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = context.camsTokens;
    final hasMiniPlayer =
        context.select((PlayerBloc bloc) => bloc.state.hasTrack);
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSpacing = keyboardInset > 0
        ? AppDimensions.spacingLg
        : ShellLayoutMetrics.reservedBottom(
            context,
            hasMiniPlayer: hasMiniPlayer,
            extra: AppDimensions.spacingLg,
          );

    return Scaffold(
      backgroundColor: tokens.bgBase,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<SearchBloc>().add(const RefreshSearchEvent());
            await Future<void>.delayed(const Duration(milliseconds: 350));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              // ── Search bar ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.spacingMd,
                    AppDimensions.spacingMd,
                    AppDimensions.spacingMd,
                    0,
                  ),
                  child: _SearchBar(
                    controller: _controller,
                    focusNode: _focusNode,
                    isDark: isDark,
                    onChanged: (q) => context
                        .read<SearchBloc>()
                        .add(QueryChangedEvent(q, debounce: true)),
                    onClear: () {
                      _controller.clear();
                      _focusNode.unfocus();
                      context.read<SearchBloc>().add(const ClearSearchEvent());
                    },
                  ),
                ),
              ),

              // ── Filter tag chips ───────────────────────────────────────
              SliverToBoxAdapter(
                child: BlocBuilder<SearchBloc, SearchState>(
                  buildWhen: (prev, curr) => prev.activeTag != curr.activeTag,
                  builder: (context, state) => _FilterTagRow(
                    activeTag: state.activeTag,
                    isDark: isDark,
                    onTagSelected: (tag) => context
                        .read<SearchBloc>()
                        .add(FilterTagChangedEvent(tag)),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                  child: SizedBox(height: AppDimensions.spacingMd)),

              // ── Body: depends on isSearching + activeTag ───────────────
              BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  if (!state.isSearching) {
                    return _buildBrowse(state, isDark);
                  }
                  return _buildSearchResults(context, state, isDark);
                },
              ),

              SliverToBoxAdapter(child: SizedBox(height: bottomSpacing)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Browse mode (no query)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBrowse(SearchState state, bool isDark) {
    final tokens = context.camsTokens;
    final tag = state.activeTag;

    if (tag == SearchFilterTag.all) {
      return _BrowseAllSliver(state: state, isDark: isDark);
    }
    if (tag == SearchFilterTag.categories) {
      return _BrowseCategoriesSliver(state: state, isDark: isDark);
    }
    if (tag == SearchFilterTag.genres) {
      return const _BrowseGenresSliver();
    }
    if (tag == SearchFilterTag.featuring) {
      return _FeaturedPlaylistsSliver(
          playlists: state.featuredPlaylists, isDark: isDark);
    }

    // For other tags with no query — show a hint
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: tokens.textTertiary),
            const SizedBox(height: AppDimensions.spacingMd),
            Text(
              'Search for ${tag.label.toLowerCase()}',
              style: TextStyle(
                color: tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Search results mode
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSearchResults(
      BuildContext context, SearchState state, bool isDark) {
    final tokens = context.camsTokens;

    if (state.status == SearchStatus.loading) {
      return const SliverToBoxAdapter(
        child: CamsSkeletonList(
          itemCount: 8,
          showTrailing: true,
          padding: EdgeInsets.fromLTRB(16, 12, 16, 160),
        ),
      );
    }

    if (state.status == SearchStatus.failure && state.failure != null) {
      return SliverFillRemaining(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
          child: AppErrorView(
            failure: state.failure,
            title: 'Search unavailable',
            message: state.failure!.message,
            onRetry: () =>
                context.read<SearchBloc>().add(QueryChangedEvent(state.query)),
          ),
        ),
      );
    }

    if (state.results.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: tokens.textTertiary),
              const SizedBox(height: AppDimensions.spacingMd),
              Text(
                'No results for "${state.query}"',
                style: TextStyle(
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final tag = state.activeTag;

    switch (tag) {
      case SearchFilterTag.all:
        return _AllResultsSliver(state: state, isDark: isDark);
      case SearchFilterTag.artists:
        return _ArtistGridSliver(results: state.artistResults, isDark: isDark);
      case SearchFilterTag.playlists:
        return _PlaylistGridSliver(
            results: state.playlistResults, isDark: isDark);
      case SearchFilterTag.songs:
        return _SongListSliver(results: state.songResults, isDark: isDark);
      case SearchFilterTag.genres:
        return _SongListSliver(results: state.songResults, isDark: isDark);
      case SearchFilterTag.albums:
        return _AlbumGridSliver(results: state.albumResults, isDark: isDark);
      case SearchFilterTag.categories:
        return _CategoryListSliver(
            results: state.categoryResults, isDark: isDark);
      case SearchFilterTag.featuring:
        return _AllResultsSliver(state: state, isDark: isDark);
    }
  }
}

// ===========================================================================
// Search bar
// ===========================================================================
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: tokens.bgContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: TextStyle(
          color: tokens.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search songs, artists, playlists...',
          hintStyle: TextStyle(
            color: tokens.textTertiary,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: tokens.textTertiary,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) => value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: tokens.textTertiary,
                    onPressed: onClear,
                  )
                : const SizedBox.shrink(),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ===========================================================================
// Filter tag row (horizontal scrollable chips)
// ===========================================================================
class _FilterTagRow extends StatelessWidget {
  final SearchFilterTag activeTag;
  final bool isDark;
  final ValueChanged<SearchFilterTag> onTagSelected;

  const _FilterTagRow({
    required this.activeTag,
    required this.isDark,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.camsTokens;

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingSm,
        ),
        itemCount: _visibleTags.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppDimensions.spacingSm),
        itemBuilder: (context, index) {
          final tag = _visibleTags[index];
          final isActive = tag == activeTag;

          return GestureDetector(
            onTap: () => onTagSelected(tag),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? Colors.transparent : tokens.borderSecondary,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  tag.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        isActive ? colorScheme.onPrimary : tokens.textPrimary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static const List<SearchFilterTag> _visibleTags = [
    SearchFilterTag.all,
    SearchFilterTag.featuring,
    SearchFilterTag.playlists,
    SearchFilterTag.artists,
    SearchFilterTag.songs,
    SearchFilterTag.genres,
  ];
}

// ===========================================================================
// Browse all sliver (moods + genres)
// ===========================================================================
class _BrowseAllSliver extends StatelessWidget {
  final SearchState state;
  final bool isDark;
  const _BrowseAllSliver({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(
            'Browse moods',
            style: AppTypography.titleMedium.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          if (state.status == SearchStatus.loading)
            const _CategoryGridSkeleton()
          else if (state.status == SearchStatus.failure)
            AppInlineErrorCard(
              failure: state.failure,
              title: 'Browse unavailable',
              onRetry: () =>
                  context.read<SearchBloc>().add(const LoadCategoriesEvent()),
            )
          else
            _CategoryGrid(categories: state.categories, isDark: isDark),
          const SizedBox(height: AppDimensions.spacingLg),
          Text(
            'Browse genres',
            style: AppTypography.titleMedium.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          const _GenreGrid(),
        ]),
      ),
    );
  }
}

// ===========================================================================
// Browse categories sliver (no search query, "All" or "Categories" tag)
// ===========================================================================
class _BrowseCategoriesSliver extends StatelessWidget {
  final SearchState state;
  final bool isDark;
  const _BrowseCategoriesSliver({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(
            'Browse moods',
            style: AppTypography.titleMedium.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          if (state.status == SearchStatus.loading)
            const _CategoryGridSkeleton()
          else if (state.status == SearchStatus.failure)
            AppInlineErrorCard(
              failure: state.failure,
              title: 'Browse unavailable',
              onRetry: () =>
                  context.read<SearchBloc>().add(const LoadCategoriesEvent()),
            )
          else
            _CategoryGrid(categories: state.categories, isDark: isDark),
        ]),
      ),
    );
  }
}

class _BrowseGenresSliver extends StatelessWidget {
  const _BrowseGenresSliver();

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(
            'Browse genres',
            style: AppTypography.titleMedium.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          const _GenreGrid(),
        ]),
      ),
    );
  }
}

class _GenreGrid extends StatelessWidget {
  const _GenreGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppDimensions.spacingSm,
        mainAxisSpacing: AppDimensions.spacingSm,
        childAspectRatio: 1.7,
      ),
      itemCount: _popularGenres.length,
      itemBuilder: (ctx, i) => _GenreCard(genre: _popularGenres[i]),
    );
  }
}

class _GenreCard extends StatelessWidget {
  final SearchCategory genre;
  const _GenreCard({required this.genre});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(
        '/search/genre/${Uri.encodeComponent(genre.id)}',
        extra: genre.name,
      ),
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        decoration: BoxDecoration(
          color: genre.color,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Text(
              genre.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            Positioned(
              bottom: -8,
              right: -8,
              child: Icon(
                genre.icon,
                size: 52,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<SearchCategory> categories;
  final bool isDark;
  const _CategoryGrid({required this.categories, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppDimensions.spacingSm,
        mainAxisSpacing: AppDimensions.spacingSm,
        childAspectRatio: 1.7,
      ),
      itemCount: categories.length,
      itemBuilder: (ctx, i) => _CategoryCard(category: categories[i]),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final SearchCategory category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(
        '/search/category/${category.id}',
        extra: category.name,
      ),
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        decoration: BoxDecoration(
          color: category.color,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          image: category.imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(category.imageUrl!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    category.color.withValues(alpha: 0.6),
                    BlendMode.srcOver,
                  ),
                )
              : null,
        ),
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Text(
              category.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            Positioned(
              bottom: -8,
              right: -8,
              child: Icon(
                category.icon,
                size: 52,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGridSkeleton extends StatelessWidget {
  const _CategoryGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return const CamsSkeletonCardGrid(
      itemCount: 8,
      childAspectRatio: 1.7,
      padding: EdgeInsets.zero,
    );
  }
}

// ===========================================================================
// "All" results sliver — shows mixed top results + featuring section
// ===========================================================================
class _AllResultsSliver extends StatelessWidget {
  final SearchState state;
  final bool isDark;
  const _AllResultsSliver({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // ── Top Results heading ──────────────────────────────────────
          Text(
            'Top results',
            style: AppTypography.titleMedium.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),

          // ── Mixed result list ────────────────────────────────────────
          ...state.results.map((r) => _ResultTile(result: r, isDark: isDark)),

          // ── Featuring section (horizontal playlists) ─────────────────
          if (state.featuredPlaylists.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingLg),
            _SectionHeader(title: 'Featuring', isDark: isDark),
            const SizedBox(height: AppDimensions.spacingSm),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.featuredPlaylists.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppDimensions.spacingSm),
                itemBuilder: (ctx, i) => _PlaylistCard(
                  playlist: state.featuredPlaylists[i],
                  isDark: isDark,
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// ===========================================================================
// Result tile (universal — used in "All" view)
// ===========================================================================
class _ResultTile extends StatelessWidget {
  final SearchResult result;
  final bool isDark;
  const _ResultTile({required this.result, required this.isDark});

  IconData get _fallbackIcon {
    switch (result.type) {
      case SearchResultType.song:
        return Icons.music_note;
      case SearchResultType.artist:
        return Icons.person;
      case SearchResultType.playlist:
        return Icons.queue_music;
      case SearchResultType.album:
        return Icons.album;
      case SearchResultType.category:
        return Icons.category;
    }
  }

  String get _typeLabel {
    switch (result.type) {
      case SearchResultType.song:
        return 'Song';
      case SearchResultType.artist:
        return 'Artist';
      case SearchResultType.playlist:
        return 'Playlist';
      case SearchResultType.album:
        return 'Album';
      case SearchResultType.category:
        return 'Category';
    }
  }

  void _onTap(BuildContext context) {
    switch (result.type) {
      case SearchResultType.artist:
        context.push('/search/artist/${result.id}');
        break;
      case SearchResultType.playlist:
        context.push('/search/playlist/${result.id}');
        break;
      case SearchResultType.album:
        context.push('/search/album/${result.id}');
        break;
      case SearchResultType.category:
        context.push('/search/category/${result.id}', extra: result.title);
        break;
      case SearchResultType.song:
        _playSearchSongOrShowMessage(context, result);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.camsTokens;
    final isPlayableSong =
        result.type == SearchResultType.song && _isSearchSongPlayable(result);
    final isDisabledSong =
        result.type == SearchResultType.song && !isPlayableSong;
    Widget? trailing;
    if (result.type == SearchResultType.song) {
      trailing = SizedBox(
        width: 78,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (result.duration != null)
              Text(
                result.duration!,
                style: TextStyle(
                  color: tokens.textTertiary,
                  fontSize: 12,
                ),
              ),
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: tokens.textTertiary,
                size: 18,
              ),
              splashRadius: 18,
              onPressed: () => _openSearchSongOptions(context, result),
            ),
          ],
        ),
      );
    } else if (result.type == SearchResultType.playlist) {
      trailing = IconButton(
        icon: Icon(
          Icons.more_vert,
          color: tokens.textTertiary,
          size: 18,
        ),
        splashRadius: 18,
        onPressed: () => _openSearchPlaylistOptions(
          context,
          playlistId: result.id,
          playlistTitle: result.title,
        ),
      );
    } else {
      trailing = Icon(
        Icons.chevron_right,
        color: tokens.textTertiary,
        size: 20,
      );
    }

    return Opacity(
      opacity: isDisabledSong ? 0.58 : 1,
      child: ListTile(
        enabled: !isDisabledSong,
        contentPadding: const EdgeInsets.symmetric(
          vertical: AppDimensions.spacingXs,
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(
            result.type == SearchResultType.artist ? 24 : 8,
          ),
          child: SizedBox(
            width: 48,
            height: 48,
            child: result.type == SearchResultType.playlist
                ? PlaylistCoverCollage(
                    coverUrls: result.playlistCoverUrls,
                    fallbackCoverUrl: result.imageUrl ?? result.thumbnailUrl,
                    backgroundColor:
                        colorScheme.primary.withValues(alpha: 0.12),
                    iconColor: colorScheme.primary,
                    iconSize: 24,
                  )
                : result.imageUrl != null
                    ? Image.network(
                        result.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          child: Icon(_fallbackIcon,
                              color: colorScheme.primary, size: 24),
                        ),
                      )
                    : Container(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        child: Icon(_fallbackIcon,
                            color: colorScheme.primary, size: 24),
                      ),
          ),
        ),
        title: Text(
          result.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                result.type == SearchResultType.song
                    ? result.subtitle
                    : _typeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            if (result.type == SearchResultType.song) ...[
              const SizedBox(width: 8),
              _SearchPlaybackTag(
                label: _searchPlaybackTagLabel(result),
                isPlayable: isPlayableSong,
              ),
            ],
            if ((result.type == SearchResultType.song ||
                    result.type == SearchResultType.playlist) &&
                result.isSharedCatalog) ...[
              const SizedBox(width: 8),
              const SharedCatalogBadge(compact: true),
            ],
          ],
        ),
        trailing: trailing,
        onTap: isDisabledSong ? null : () => _onTap(context),
      ),
    );
  }
}

class _SearchPlaybackTag extends StatelessWidget {
  const _SearchPlaybackTag({
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

// ===========================================================================
// Artist grid sliver (2 columns with circular images)
// ===========================================================================
class _ArtistGridSliver extends StatelessWidget {
  final List<SearchResult> results;
  final bool isDark;
  const _ArtistGridSliver({required this.results, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(
            'Artists',
            style: AppTypography.titleMedium.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppDimensions.spacingMd,
              mainAxisSpacing: AppDimensions.spacingMd,
              childAspectRatio: 0.85,
            ),
            itemCount: results.length,
            itemBuilder: (ctx, i) {
              final r = results[i];
              return GestureDetector(
                onTap: () => ctx.push('/search/artist/${r.id}'),
                child: Column(
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: r.imageUrl != null
                              ? Image.network(r.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _AvatarFallback(isDark: isDark))
                              : _AvatarFallback(isDark: isDark),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: tokens.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ]),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final bool isDark;
  const _AvatarFallback({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    return Container(
      color: tokens.bgElevated,
      child: Icon(Icons.person, size: 48, color: tokens.textTertiary),
    );
  }
}

// ===========================================================================
// Playlist grid sliver (2 columns with cover image cards)
// ===========================================================================
class _PlaylistGridSliver extends StatelessWidget {
  final List<SearchResult> results;
  final bool isDark;
  const _PlaylistGridSliver({required this.results, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(
            'Playlists',
            style: AppTypography.titleMedium.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppDimensions.spacingSm,
              mainAxisSpacing: AppDimensions.spacingMd,
              childAspectRatio: 0.75,
            ),
            itemCount: results.length,
            itemBuilder: (ctx, i) {
              final r = results[i];
              return GestureDetector(
                onTap: () => ctx.push('/search/playlist/${r.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                        child: PlaylistCoverCollage(
                          coverUrls: r.playlistCoverUrls,
                          fallbackCoverUrl: r.imageUrl,
                          backgroundColor: tokens.bgElevated,
                          iconColor: tokens.textTertiary,
                          iconSize: 34,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            r.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: tokens.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.more_vert,
                            color: tokens.textTertiary,
                            size: 18,
                          ),
                          splashRadius: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          onPressed: () => _openSearchPlaylistOptions(
                            ctx,
                            playlistId: r.id,
                            playlistTitle: r.title,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      r.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: tokens.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                    if (r.isSharedCatalog) ...[
                      const SizedBox(height: 4),
                      const SharedCatalogBadge(compact: true),
                    ],
                  ],
                ),
              );
            },
          ),
        ]),
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  final bool isDark;
  const _CoverFallback({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    return Container(
      width: double.infinity,
      color: tokens.bgElevated,
      child: Icon(LucideIcons.music4, size: 48, color: tokens.textTertiary),
    );
  }
}

// ===========================================================================
// Song list sliver (vertical list using SongListTile)
// ===========================================================================
class _SongListSliver extends StatelessWidget {
  final List<SearchResult> results;
  final bool isDark;
  const _SongListSliver({required this.results, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    return SliverPadding(
      padding: EdgeInsets.zero,
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
            child: Text(
              'Songs',
              style: AppTypography.titleMedium.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          ...results.map((r) {
            final song = SongEntity(
              id: r.id,
              brandId: r.brandId,
              title: r.title,
              artist: r.subtitle,
              duration: r.durationSeconds ?? 0,
              coverUrl: r.imageUrl,
              streamUrl: r.streamUrl,
            );
            final isPlayable = _isSearchSongPlayable(r);
            return SongListTile(
              song: song,
              enabled: isPlayable,
              optionsEnabled: true,
              badge: _SearchPlaybackTag(
                label: _searchPlaybackTagLabel(r),
                isPlayable: isPlayable,
              ),
              onTap: () => _playSearchSongOrShowMessage(context, r),
              showPlayNext: true,
              enableAddToQueue: isPlayable,
              addToQueueLabel: 'Add to space queue',
              enableGoToArtist: _searchResultArtistName(r) != null,
              forwardPlayNowToOptionHandler: true,
              onOptionSelected: (option) =>
                  _handleSearchSongOption(context, r, option),
            );
          }),
        ]),
      ),
    );
  }
}

// ===========================================================================
// Album grid sliver (2 columns with cover, title, artist)
// ===========================================================================
class _AlbumGridSliver extends StatelessWidget {
  final List<SearchResult> results;
  final bool isDark;
  const _AlbumGridSliver({required this.results, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(
            'Albums',
            style: AppTypography.titleMedium.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppDimensions.spacingSm,
              mainAxisSpacing: AppDimensions.spacingMd,
              childAspectRatio: 0.75,
            ),
            itemCount: results.length,
            itemBuilder: (ctx, i) {
              final r = results[i];
              return GestureDetector(
                onTap: () => ctx.push('/search/album/${r.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                        child: r.imageUrl != null
                            ? Image.network(r.imageUrl!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _CoverFallback(isDark: isDark))
                            : _CoverFallback(isDark: isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: tokens.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      r.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: tokens.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ]),
      ),
    );
  }
}

// ===========================================================================
// Category list sliver (list tiles with colour + arrow)
// ===========================================================================
class _CategoryListSliver extends StatelessWidget {
  final List<SearchResult> results;
  final bool isDark;
  const _CategoryListSliver({required this.results, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(
            'Categories',
            style: AppTypography.titleMedium.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          ...results.map((r) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: r.imageUrl != null
                        ? Image.network(r.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                  color: tokens.bgElevated,
                                  child: Icon(Icons.category,
                                      color: tokens.textTertiary),
                                ))
                        : Container(
                            color: tokens.bgElevated,
                            child: Icon(Icons.category,
                                color: tokens.textTertiary),
                          ),
                  ),
                ),
                title: Text(
                  r.title,
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: tokens.textTertiary),
                onTap: () => context.push(
                  '/search/category/${r.id}',
                  extra: r.title,
                ),
              )),
        ]),
      ),
    );
  }
}

// ===========================================================================
// Featured playlists sliver (grid when no search query, "Featuring" tab)
// ===========================================================================
class _FeaturedPlaylistsSliver extends StatelessWidget {
  final List<PlaylistEntity> playlists;
  final bool isDark;
  const _FeaturedPlaylistsSliver(
      {required this.playlists, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    if (playlists.isEmpty) {
      return const SliverToBoxAdapter(
        child: CamsSkeletonCardGrid(
          itemCount: 6,
          childAspectRatio: 0.8,
          padding: EdgeInsets.fromLTRB(16, 12, 16, 160),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(
            'Featured Playlists',
            style: AppTypography.titleMedium.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppDimensions.spacingSm,
              mainAxisSpacing: AppDimensions.spacingMd,
              childAspectRatio: 0.75,
            ),
            itemCount: playlists.length,
            itemBuilder: (ctx, i) =>
                _PlaylistCard(playlist: playlists[i], isDark: isDark),
          ),
        ]),
      ),
    );
  }
}

// ===========================================================================
// Shared playlist card widget
// ===========================================================================
class _PlaylistCard extends StatelessWidget {
  final PlaylistEntity playlist;
  final bool isDark;
  const _PlaylistCard({required this.playlist, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    return GestureDetector(
      onTap: () => context.push('/search/playlist/${playlist.id}'),
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                      child: PlaylistCoverCollage(
                        coverUrls: playlist.trackCoverUrls,
                        fallbackCoverUrl: playlist.coverUrl,
                        backgroundColor: tokens.bgElevated,
                        iconColor: tokens.textTertiary,
                        iconSize: 34,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.36),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _openSearchPlaylistOptions(
                          context,
                          playlistId: playlist.id,
                          playlistTitle: playlist.title,
                          source: 'Search featuring',
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.more_vert,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              playlist.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: tokens.textPrimary,
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
                  color: tokens.textTertiary,
                  fontSize: 11,
                ),
              ),
            if (playlist.isSharedCatalog) ...[
              const SizedBox(height: 4),
              const SharedCatalogBadge(compact: true),
            ],
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Section header with optional "See all" link
// ===========================================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
