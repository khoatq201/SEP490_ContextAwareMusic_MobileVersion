import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/presentation/shell_layout_metrics.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/session/session_state.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/playlist_entity.dart';
import '../../domain/entities/sensor_entity.dart';
import '../../../moods/domain/entities/mood.dart';
import '../bloc/home_cubit.dart';
import '../bloc/home_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — wraps the page with its own HomeCubit (DI-resolved)
// ─────────────────────────────────────────────────────────────────────────────
class HomeTabPage extends StatelessWidget {
  const HomeTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<HomeCubit>()..load();
        final spaceId = context.read<SessionCubit>().state.currentSpace?.id;
        cubit.syncForSpace(spaceId);
        return cubit;
      },
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
    final hasMiniPlayer =
        context.select((PlayerBloc bloc) => bloc.state.hasTrack);
    final bottomSpacing = ShellLayoutMetrics.reservedBottom(
      context,
      hasMiniPlayer: hasMiniPlayer,
      extra: 24,
    );

    return BlocListener<SessionCubit, SessionState>(
      listenWhen: (previous, current) =>
          previous.currentSpace?.id != current.currentSpace?.id,
      listener: (context, sessionState) {
        context.read<HomeCubit>().syncForSpace(sessionState.currentSpace?.id);
      },
      child: Scaffold(
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
                // 1. SliverAppBar
                _HomeSliverAppBar(palette: palette),

                // 2. Current Mood Chip
                if (state.currentMoodName != null)
                  SliverToBoxAdapter(
                    child: _CurrentMoodChip(
                      moodName: state.currentMoodName!,
                      playlistName: state.currentPlaylistName,
                      isStreaming: state.isStreaming,
                      palette: palette,
                    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.04),
                  ),

                // 3. Sensors Row
                SliverToBoxAdapter(
                  child: _SensorsRow(sensors: state.sensors, palette: palette)
                      .animate()
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.06),
                ),

                // 4. Master Control Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _MasterControlCard(
                      autoModeEnabled: state.autoModeEnabled,
                      manualModeActive: state.isManualMode,
                      manualSelectionOpen: state.isManualSelectionOpen,
                      hasSpaceSelected: state.activeSpaceId != null,
                      isApplying: state.isApplyingOverride,
                      isPendingTranscode: state.isPendingTranscode,
                      currentPlaylistName: state.currentPlaylistName,
                      modeMessage: state.modeMessage,
                      palette: palette,
                      onSelectAuto: () =>
                          context.read<HomeCubit>().selectAutoMode(),
                      onSelectManual: () =>
                          context.read<HomeCubit>().openManualSelection(),
                      onCloseManualPicker: () =>
                          context.read<HomeCubit>().closeManualSelection(),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08),
                  ),
                ),

                if (state.showMoodPicker)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _MoodPickerCard(
                        moods: state.moods,
                        currentMoodName: state.currentMoodName,
                        isLoading: state.isApplyingOverride,
                        palette: palette,
                        onClose: () =>
                            context.read<HomeCubit>().closeManualSelection(),
                        onSelectMood: (mood) {
                          context.read<HomeCubit>().applyMoodOverride(mood.id);
                        },
                      ),
                    ),
                  ),

                // 5. Dynamic Category Sections
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
                SliverToBoxAdapter(child: SizedBox(height: bottomSpacing)),
              ],
            );
          },
        ),
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
    final session = context.watch<SessionCubit>().state;
    final isPlayback = session.isPlaybackDevice;

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
          onTap: isPlayback ? null : () => _showSpaceSheet(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPlayback ? 'PLAYBACK DEVICE' : 'REMOTE CONTROLLING',
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
                    session.currentSpace?.name ?? 'No Space Selected',
                    style: GoogleFonts.poppins(
                      color: palette.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (!isPlayback) ...[
                    const SizedBox(width: 4),
                    Icon(LucideIcons.chevronsUpDown,
                        color: palette.accent, size: 14),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => context.push('/settings'),
          child: Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            decoration: BoxDecoration(
              color: palette.overlay,
              shape: BoxShape.circle,
              border: Border.all(color: palette.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(LucideIcons.settings,
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
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + safeBottom),
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
              'Current Space',
              style: GoogleFonts.poppins(
                color: palette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Builder(builder: (context) {
              final spaceName =
                  context.read<SessionCubit>().state.currentSpace?.name ??
                      'No Space Selected';
              return Text(
                spaceName,
                style: GoogleFonts.inter(
                  color: palette.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              );
            }),
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
                  final playerStoreId =
                      context.read<PlayerBloc>().state.activeStoreId;
                  final sessionStoreId =
                      context.read<SessionCubit>().state.currentStore?.id;
                  final storeId = playerStoreId ?? sessionStoreId;
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
            'Environment',
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
// Current Mood Chip — shows the active mood of the selected space
// ─────────────────────────────────────────────────────────────────────────────
class _CurrentMoodChip extends StatelessWidget {
  const _CurrentMoodChip({
    required this.moodName,
    required this.palette,
    this.playlistName,
    this.isStreaming = false,
  });
  final String moodName;
  final String? playlistName;
  final bool isStreaming;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: palette.accent.withOpacity(palette.isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: palette.accent.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: palette.accent.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                LucideIcons.sparkles,
                color: palette.accent,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Current Mood',
                        style: GoogleFonts.inter(
                          color: palette.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                      if (isStreaming) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.green.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    moodName,
                    style: GoogleFonts.poppins(
                      color: palette.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (playlistName != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      playlistName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: palette.textMuted,
                        fontSize: 11,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Master Control Card
// ─────────────────────────────────────────────────────────────────────────────
class _MasterControlCard extends StatelessWidget {
  const _MasterControlCard({
    required this.autoModeEnabled,
    required this.manualModeActive,
    required this.manualSelectionOpen,
    required this.hasSpaceSelected,
    required this.isApplying,
    required this.isPendingTranscode,
    required this.palette,
    required this.onSelectAuto,
    required this.onSelectManual,
    required this.onCloseManualPicker,
    this.modeMessage,
    this.currentPlaylistName,
  });
  final bool autoModeEnabled;
  final bool manualModeActive;
  final bool manualSelectionOpen;
  final bool hasSpaceSelected;
  final bool isApplying;
  final bool isPendingTranscode;
  final _Palette palette;
  final VoidCallback onSelectAuto;
  final VoidCallback onSelectManual;
  final VoidCallback onCloseManualPicker;
  final String? modeMessage;
  final String? currentPlaylistName;

  @override
  Widget build(BuildContext context) {
    final modeTitle = !hasSpaceSelected
        ? 'No space selected'
        : autoModeEnabled
            ? 'AI Auto is active'
            : manualSelectionOpen
                ? 'Choose a manual mood'
                : 'Manual override is active';
    final modeDescription = !hasSpaceSelected
        ? 'Pick a space before changing playback mode.'
        : autoModeEnabled
            ? 'AI analyzes context and picks mood or playlist for this space.'
            : manualSelectionOpen
                ? 'Select a mood below to replace AI decisions for this space.'
                : 'A playlist, track, or mood was manually chosen. AI stays paused until you switch back.';
    final gradientColors = palette.isDark
        ? [
            palette.accent.withOpacity(0.80),
            palette.accentAlt.withOpacity(0.55),
          ]
        : [
            palette.accent,
            palette.accentAlt,
          ];

    return Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        autoModeEnabled
                            ? LucideIcons.cpu
                            : manualSelectionOpen
                                ? LucideIcons.sparkles
                                : Icons.tune_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            modeTitle,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            modeDescription,
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.80),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.music2,
                                color: Colors.white.withOpacity(0.70),
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  currentPlaylistName ?? 'No playlist active',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.65),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _ModeActionButton(
                        label: 'AI Auto',
                        icon: LucideIcons.cpu,
                        selected: autoModeEnabled,
                        enabled: hasSpaceSelected && !isApplying,
                        onTap: onSelectAuto,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ModeActionButton(
                        label: 'Manual',
                        icon: Icons.tune_rounded,
                        selected: manualModeActive,
                        enabled: hasSpaceSelected && !isApplying,
                        onTap: onSelectManual,
                      ),
                    ),
                  ],
                ),
                if (manualModeActive && !manualSelectionOpen) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: hasSpaceSelected && !isApplying
                          ? onSelectManual
                          : null,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: Text(
                        'Change mood',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
                if (manualSelectionOpen) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white.withOpacity(0.88),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Mood options below only open because you explicitly entered manual setup here.',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.90),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: isApplying ? null : onCloseManualPicker,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        child: Text(
                          'Hide',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (isApplying ||
                    isPendingTranscode ||
                    modeMessage != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (isApplying)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        Icon(
                          isPendingTranscode
                              ? LucideIcons.loader
                              : LucideIcons.info,
                          color: Colors.white.withOpacity(0.85),
                          size: 14,
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isApplying
                              ? 'Applying changes...'
                              : (modeMessage ??
                                  (isPendingTranscode
                                      ? 'Accepted (202). Stream starts when transcode is ready.'
                                      : '')),
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeActionButton extends StatelessWidget {
  const _ModeActionButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withOpacity(0.22)
                : Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? Colors.white.withOpacity(0.78)
                  : Colors.white.withOpacity(0.24),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(enabled ? 0.96 : 0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodPickerCard extends StatelessWidget {
  const _MoodPickerCard({
    required this.moods,
    required this.currentMoodName,
    required this.isLoading,
    required this.palette,
    required this.onClose,
    required this.onSelectMood,
  });

  final List<Mood> moods;
  final String? currentMoodName;
  final bool isLoading;
  final _Palette palette;
  final VoidCallback onClose;
  final ValueChanged<Mood> onSelectMood;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Select mood override',
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: isLoading ? null : onClose,
                style: TextButton.styleFrom(
                  foregroundColor: palette.textMuted,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Choose a mood only when you want to take control away from AI for this space.',
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (moods.isEmpty)
            Text(
              'No moods available.',
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 12,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: moods.map((mood) {
                final selected = currentMoodName != null &&
                    currentMoodName!.toLowerCase() == mood.name.toLowerCase();
                return ChoiceChip(
                  label: Text(
                    mood.name.toUpperCase(),
                    style: GoogleFonts.inter(
                      color:
                          selected ? palette.textOnAccent : palette.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  selected: selected,
                  selectedColor: palette.accent,
                  backgroundColor: palette.overlay,
                  side: BorderSide(
                      color: selected ? palette.accent : palette.border),
                  onSelected: isLoading ? null : (_) => onSelectMood(mood),
                );
              }).toList(),
            ),
        ],
      ),
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
        context.push('/home/playlist-detail', extra: playlist.id);
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
            message ?? 'An error occurred',
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
              'Retry',
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
