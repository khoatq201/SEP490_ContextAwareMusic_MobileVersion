import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/player/player_state.dart' as ps;
import '../../data/datasources/mock_home_data_source.dart';
import '../../data/repositories/mock_home_repository_impl.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/playlist_entity.dart';
import '../../domain/entities/sensor_entity.dart';
import '../bloc/home_cubit.dart';
import '../bloc/home_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — wraps the page with its own HomeCubit (self-contained)
// ─────────────────────────────────────────────────────────────────────────────
class HomeTabPage extends StatelessWidget {
  const HomeTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit(
        MockHomeRepositoryImpl(dataSource: MockHomeDataSource()),
      )..load(),
      child: const _HomeDashboardView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main scaffold
// ─────────────────────────────────────────────────────────────────────────────
class _HomeDashboardView extends StatelessWidget {
  const _HomeDashboardView();

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.fromBrightness(Theme.of(context).brightness);

    return Scaffold(
      backgroundColor: palette.bg,
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state.status == HomeStatus.loading ||
              state.status == HomeStatus.initial) {
            return Center(
              child: CircularProgressIndicator(color: palette.accent),
            );
          }

          if (state.status == HomeStatus.error) {
            return _ErrorView(
              message: state.errorMessage,
              palette: palette,
              onRetry: () => context.read<HomeCubit>().load(),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── 1. SliverAppBar ─────────────────────────────────────────
              _HomeSliverAppBar(palette: palette),

              // ── 2. Sensors Row ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: _SensorsRow(sensors: state.sensors, palette: palette)
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: 0.06),
              ),

              // ── 3. Master Control Card ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _MasterControlCard(
                    autoModeEnabled: state.autoModeEnabled,
                    palette: palette,
                    onToggle: () => context.read<HomeCubit>().toggleAutoMode(),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08),
                ),
              ),

              // ── 4. Dynamic Category Sections ─────────────────────────────
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = state.categories[index];
                    return _CategorySection(
                      category: category,
                      palette: palette,
                    )
                        .animate()
                        .fadeIn(duration: 420.ms, delay: (index * 60).ms)
                        .slideY(begin: 0.10);
                  },
                  childCount: state.categories.length,
                ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. SliverAppBar
// ─────────────────────────────────────────────────────────────────────────────
class _HomeSliverAppBar extends StatelessWidget {
  const _HomeSliverAppBar({required this.palette});
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: palette.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 86,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
        title: GestureDetector(
          onTap: () => _showSpaceSheet(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REMOTE CONTROLLING',
                style: GoogleFonts.inter(
                  color: palette.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sảnh Chính',
                    style: GoogleFonts.poppins(
                      color: palette.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(LucideIcons.chevronsUpDown,
                      color: palette.accent, size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => _showSpaceSheet(context),
          child: Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            decoration: BoxDecoration(
              color: palette.overlay,
              shape: BoxShape.circle,
              border: Border.all(color: palette.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(LucideIcons.settings2,
                  color: palette.textPrimary, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  void _showSpaceSheet(BuildContext context) {
    final palette = _Palette.fromBrightness(Theme.of(context).brightness);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true, // renders above shell Scaffold (+ MiniPlayer)
      backgroundColor: palette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SwitchSpaceSheet(palette: palette),
    );
  }
}

class _SwitchSpaceSheet extends StatelessWidget {
  const _SwitchSpaceSheet({required this.palette});
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
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
            'Không gian hiện tại',
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sảnh Chính',
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: palette.textOnAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(LucideIcons.arrowLeftRight, size: 18),
              label: Text(
                'Switch Space',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                final storeId = context.read<PlayerBloc>().state.activeStoreId;
                if (storeId != null && storeId.isNotEmpty) {
                  context.go('/store/$storeId');
                } else {
                  context.go('/store-selection');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Sensors Row
// ─────────────────────────────────────────────────────────────────────────────
class _SensorsRow extends StatelessWidget {
  const _SensorsRow({required this.sensors, required this.palette});
  final List<SensorEntity> sensors;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Text(
            'Môi trường',
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sensors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) =>
                _SensorChip(sensor: sensors[i], palette: palette),
          ),
        ),
      ],
    );
  }
}

class _SensorChip extends StatelessWidget {
  const _SensorChip({required this.sensor, required this.palette});
  final SensorEntity sensor;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    final accent = sensor.accentColor ?? palette.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withOpacity(palette.isDark ? 0.12 : 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(sensor.icon, color: accent, size: 18),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sensor.value,
                style: GoogleFonts.poppins(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              Text(
                sensor.name,
                style: GoogleFonts.inter(
                  color: palette.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (sensor.badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                sensor.badge!,
                style: GoogleFonts.inter(
                  color: accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Master Control Card
// ─────────────────────────────────────────────────────────────────────────────
class _MasterControlCard extends StatelessWidget {
  const _MasterControlCard({
    required this.autoModeEnabled,
    required this.palette,
    required this.onToggle,
  });
  final bool autoModeEnabled;
  final _Palette palette;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final gradientColors = palette.isDark
        ? [
            palette.accent.withOpacity(0.80),
            palette.accentAlt.withOpacity(0.55),
          ]
        : [
            palette.accent,
            palette.accentAlt,
          ];

    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withOpacity(0.30),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                // Left: icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    autoModeEnabled ? LucideIcons.cpu : LucideIcons.pauseCircle,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Center: info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        autoModeEnabled ? 'Auto Mode' : 'Thủ công',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        autoModeEnabled
                            ? 'Hệ thống đang tự điều chỉnh nhạc'
                            : 'Chờ điều khiển từ người dùng',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.80),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(LucideIcons.music2,
                              color: Colors.white.withOpacity(0.70), size: 13),
                          const SizedBox(width: 5),
                          Text(
                            'Chill Morning — Lo-Fi Beats',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Xem & quản lý luật',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            LucideIcons.chevronRight,
                            color: Colors.white.withOpacity(0.65),
                            size: 12,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Right: animated toggle
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 52,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: autoModeEnabled
                          ? Colors.white.withOpacity(0.90)
                          : Colors.white.withOpacity(0.25),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.40),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedAlign(
                          duration: const Duration(milliseconds: 250),
                          alignment: autoModeEnabled
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: autoModeEnabled
                                  ? palette.accent
                                  : Colors.white.withOpacity(0.60),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return GestureDetector(
      onTap: () => context.push('/context-rules'),
      child: card,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Category Section (SliverList item)
// ─────────────────────────────────────────────────────────────────────────────
class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category, required this.palette});
  final CategoryEntity category;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: title + < > arrows
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    category.title,
                    style: GoogleFonts.poppins(
                      color: palette.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Icon(LucideIcons.chevronLeft,
                      color: palette.textMuted, size: 20),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {},
                  child: Icon(LucideIcons.chevronRight,
                      color: palette.accent, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Horizontal playlist scroll
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: category.playlists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _PlaylistCard(
                playlist: category.playlists[i],
                palette: palette,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Playlist card — cover bg + gradient overlay + bottom-left title
// (Soundtrack "Restaurant" / "Family-friendly" style)
// ─────────────────────────────────────────────────────────────────────────────
class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({required this.playlist, required this.palette});
  final PlaylistEntity playlist;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/home/playlist-detail', extra: playlist);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 155,
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background cover image
              if (playlist.coverUrl != null)
                Image.network(
                  playlist.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _FallbackCover(palette: palette),
                )
              else
                _FallbackCover(palette: palette),

              // Gradient overlay — bottom ⅔
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.45),
                        Colors.black.withOpacity(0.82),
                      ],
                      stops: const [0.0, 0.30, 0.65, 1.0],
                    ),
                  ),
                ),
              ),

              // Track count badge — top right
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.50),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Text(
                    '${playlist.totalTracks} tracks',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.90),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Bottom-left: title + description
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      playlist.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        shadows: const [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    if (playlist.description != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        playlist.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FallbackCover extends StatelessWidget {
  const _FallbackCover({required this.palette});
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: palette.accent.withOpacity(0.20),
      child: Icon(LucideIcons.music4, color: palette.textMuted, size: 40),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  const _ErrorView({
    this.message,
    required this.palette,
    required this.onRetry,
  });
  final String? message;
  final _Palette palette;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.alertTriangle, color: Colors.amber, size: 52),
          const SizedBox(height: 12),
          Text(
            message ?? 'Đã xảy ra lỗi',
            style: GoogleFonts.inter(color: palette.textMuted, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: palette.textOnAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: Text(
              'Thử lại',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Palette — identical pattern to space_detail_page.dart
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
    return _Palette(
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
