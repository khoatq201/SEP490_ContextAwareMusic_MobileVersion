import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/entities/search_category.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/search_music_usecase.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';

// ===========================================================================
// SearchTabPage – entry point (wires up its own BlocProvider)
// ===========================================================================
class SearchTabPage extends StatelessWidget {
  const SearchTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = SearchRepositoryImpl();
    return BlocProvider(
      create: (_) => SearchBloc(
        getCategories: GetCategoriesUseCase(repo),
        searchMusic: SearchMusicUseCase(repo),
      )..add(const LoadCategoriesEvent()),
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
            // Large title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spacingMd,
                  AppDimensions.spacingXl,
                  AppDimensions.spacingMd,
                  AppDimensions.spacingMd,
                ),
                child: Text(
                  'Search',
                  style: AppTypography.headlineLarge.copyWith(
                    color: isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingMd),
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

            const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.spacingXl)),

            // Body: results or browse
            BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) => state.isSearching
                  ? _SearchResultsSliver(state: state, isDark: isDark)
                  : _BrowseAllSliver(state: state, isDark: isDark),
            ),

            const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.spacingXxl)),
          ],
        ),
      ),
    );
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
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
// "Browse all" sliver
// ===========================================================================
class _BrowseAllSliver extends StatelessWidget {
  final SearchState state;
  final bool isDark;
  const _BrowseAllSliver({required this.state, required this.isDark});

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
            _CategoryGrid(categories: state.categories),
        ]),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<SearchCategory> categories;
  const _CategoryGrid({required this.categories});

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
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening "${category.name}"...')),
      ),
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        decoration: BoxDecoration(
          color: category.color,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
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
// Search results sliver
// ===========================================================================
class _SearchResultsSliver extends StatelessWidget {
  final SearchState state;
  final bool isDark;
  const _SearchResultsSliver({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
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

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => _ResultTile(result: state.results[i], isDark: isDark),
        childCount: state.results.length,
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final SearchResult result;
  final bool isDark;
  const _ResultTile({required this.result, required this.isDark});

  IconData get _icon {
    switch (result.type) {
      case SearchResultType.song:
        return Icons.music_note;
      case SearchResultType.artist:
        return Icons.person;
      case SearchResultType.playlist:
        return Icons.queue_music;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingXs,
      ),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primaryOrange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Icon(_icon, color: AppColors.primaryOrange, size: 24),
      ),
      title: Text(
        result.title,
        style: TextStyle(
          color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        result.subtitle,
        style: TextStyle(
          color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      onTap: () {
        // TODO: navigate to detail
      },
    );
  }
}
