import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../injection_container.dart';
import '../../../home/domain/entities/playlist_entity.dart';
import '../bloc/category_detail_cubit.dart';

class CategoryDetailPage extends StatelessWidget {
  final String categoryId;
  final String? categoryName;

  const CategoryDetailPage({
    super.key,
    required this.categoryId,
    this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CategoryDetailCubit>()..load(categoryId),
      child: _CategoryDetailView(
        categoryName: categoryName ?? 'Category',
      ),
    );
  }
}

class _CategoryDetailView extends StatelessWidget {
  final String categoryName;
  const _CategoryDetailView({required this.categoryName});

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
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
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
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == CategoryDetailStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64,
                      color: isDark
                          ? AppColors.textDarkTertiary
                          : AppColors.textTertiary),
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage ?? 'An error occurred',
                    style: TextStyle(
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return _PlaylistGrid(
            playlists: state.playlists,
            isDark: isDark,
          );
        },
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
    if (playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.music4,
                size: 64,
                color: isDark
                    ? AppColors.textDarkTertiary
                    : AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'No playlists in this category',
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

    return GridView.builder(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
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
            ],
          ),
        );
      },
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
