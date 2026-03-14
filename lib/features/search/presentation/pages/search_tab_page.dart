import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/widgets/song_list_tile.dart';
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
    final bgColor =
        isDark ? AppColors.backgroundDarkPrimary : AppColors.backgroundPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
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
                  onChanged: (q) =>
                      context.read<SearchBloc>().add(QueryChangedEvent(q)),
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

            const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.spacingXxl + 80)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Browse mode (no query)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBrowse(SearchState state, bool isDark) {
    final tag = state.activeTag;

    if (tag == SearchFilterTag.categories || tag == SearchFilterTag.all) {
      return _BrowseCategoriesSliver(state: state, isDark: isDark);
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
            Icon(Icons.search,
                size: 64,
                color: isDark
                    ? AppColors.textDarkTertiary
                    : AppColors.textTertiary),
            const SizedBox(height: AppDimensions.spacingMd),
            Text(
              'Search for ${tag.label.toLowerCase()}',
              style: TextStyle(
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textSecondary,
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
    if (state.status == SearchStatus.loading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.results.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off,
                  size: 64,
                  color: isDark
                      ? AppColors.textDarkTertiary
                      : AppColors.textTertiary),
              const SizedBox(height: AppDimensions.spacingMd),
              Text(
                'No results for "${state.query}"',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textSecondary,
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
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: TextStyle(
          color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search songs, artists, playlists...',
          hintStyle: TextStyle(
            color: isDark ? AppColors.textDarkTertiary : AppColors.textTertiary,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? AppColors.textDarkTertiary : AppColors.textTertiary,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) => value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: isDark
                        ? AppColors.textDarkTertiary
                        : AppColors.textTertiary,
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
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingSm,
        ),
        itemCount: SearchFilterTag.values.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppDimensions.spacingSm),
        itemBuilder: (context, index) {
          final tag = SearchFilterTag.values[index];
          final isActive = tag == activeTag;

          return GestureDetector(
            onTap: () => onTagSelected(tag),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? (isDark ? Colors.white : Colors.black87)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? Colors.transparent
                      : (isDark
                          ? Colors.white.withOpacity(0.3)
                          : Colors.black.withOpacity(0.2)),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  tag.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textPrimary),
                  ),
                ),
              ),
            ),
          );
        },
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
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(
            'Browse all',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          if (state.status == SearchStatus.loading)
            const _CategoryGridSkeleton()
          else if (state.status == SearchStatus.failure)
            Center(
              child: Text(
                state.errorMessage ?? 'Something went wrong.',
                style: const TextStyle(color: AppColors.error),
              ),
            )
          else
            _CategoryGrid(categories: state.categories, isDark: isDark),
        ]),
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
                    category.color.withOpacity(0.6),
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
                color: Colors.white.withOpacity(0.25),
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
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppDimensions.spacingSm,
        mainAxisSpacing: AppDimensions.spacingSm,
        childAspectRatio: 1.7,
      ),
      itemCount: 8,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),
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
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // ── Top Results heading ──────────────────────────────────────
          Text(
            'Top results',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
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
        final session = context.read<SessionCubit>().state;
        final message = session.isPlaybackDevice
            ? 'This search result does not include a stream URL yet.'
            : 'Manager devices can only control playback from CMS playlists right now.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
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
          child: result.imageUrl != null
              ? Image.network(
                  result.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.primaryOrange.withOpacity(0.12),
                    child: Icon(_fallbackIcon,
                        color: AppColors.primaryOrange, size: 24),
                  ),
                )
              : Container(
                  color: AppColors.primaryOrange.withOpacity(0.12),
                  child: Icon(_fallbackIcon,
                      color: AppColors.primaryOrange, size: 24),
                ),
        ),
      ),
      title: Text(
        result.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        result.type == SearchResultType.song ? result.subtitle : _typeLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: result.type == SearchResultType.song
          ? (result.duration != null
              ? Text(
                  result.duration!,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textDarkTertiary
                        : AppColors.textTertiary,
                    fontSize: 12,
                  ),
                )
              : null)
          : Icon(
              Icons.chevron_right,
              color:
                  isDark ? AppColors.textDarkTertiary : AppColors.textTertiary,
              size: 20,
            ),
      onTap: () => _onTap(context),
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
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(
            'Artists',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
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
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textPrimary,
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
    return Container(
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      child: Icon(Icons.person, size: 48, color: Colors.grey.shade400),
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
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(
            'Playlists',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
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
                    Text(
                      r.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: isDark
                            ? AppColors.textDarkTertiary
                            : AppColors.textTertiary,
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

class _CoverFallback extends StatelessWidget {
  final bool isDark;
  const _CoverFallback({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      child: Icon(LucideIcons.music4, size: 48, color: Colors.grey.shade400),
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
                color:
                    isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          ...results.map((r) {
            final song = SongEntity(
              id: r.id,
              title: r.title,
              artist: r.subtitle,
              duration: 0,
              coverUrl: r.imageUrl,
            );
            return SongListTile(
              song: song,
              onTap: () {
                final session = context.read<SessionCubit>().state;
                final message = session.isPlaybackDevice
                    ? 'This search result does not include a stream URL yet.'
                    : 'Manager devices can only control playback from CMS playlists right now.';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              },
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
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(
            'Albums',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
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
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      r.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: isDark
                            ? AppColors.textDarkTertiary
                            : AppColors.textTertiary,
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
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(
            'Categories',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
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
                                  color: Colors.grey.shade700,
                                  child: const Icon(Icons.category,
                                      color: Colors.white54),
                                ))
                        : Container(
                            color: Colors.grey.shade700,
                            child: const Icon(Icons.category,
                                color: Colors.white54),
                          ),
                  ),
                ),
                title: Text(
                  r.title,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(Icons.chevron_right,
                    color: isDark
                        ? AppColors.textDarkTertiary
                        : AppColors.textTertiary),
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
    if (playlists.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(
            'Featured Playlists',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
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
    return GestureDetector(
      onTap: () => context.push('/search/playlist/${playlist.id}'),
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: playlist.coverUrl != null
                    ? Image.network(
                        playlist.coverUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _CoverFallback(isDark: isDark),
                      )
                    : _CoverFallback(isDark: isDark),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              playlist.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color:
                    isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
