import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/player/player_bloc.dart';
import '../../../../core/player/player_event.dart';
import '../../../../core/theme/cams_theme_tokens.dart';
import '../../../../core/widgets/cams_skeleton.dart';
import '../../../cams/presentation/bloc/cams_playback_bloc.dart';
import '../../../cams/presentation/bloc/cams_playback_event.dart';
import '../../../now_playing/presentation/pages/now_playing_tab_page.dart';
import '../../domain/entities/sensor_data.dart';
import '../bloc/offline_library_bloc.dart';
import '../bloc/offline_library_event.dart';
import '../bloc/space_monitoring_bloc.dart';
import '../bloc/space_monitoring_event.dart';
import '../bloc/space_monitoring_state.dart';
import '../widgets/space_offline_tab.dart';
import 'space_settings_page.dart';

class SpaceDetailPage extends StatefulWidget {
  const SpaceDetailPage({
    super.key,
    required this.storeId,
    required this.spaceId,
  });

  final String storeId;
  final String spaceId;

  @override
  State<SpaceDetailPage> createState() => _SpaceDetailPageState();
}

class _SpaceDetailPageState extends State<SpaceDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bootstrapSpaceContext();
  }

  @override
  void didUpdateWidget(covariant SpaceDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final spaceChanged = oldWidget.spaceId != widget.spaceId;
    final storeChanged = oldWidget.storeId != widget.storeId;
    if (spaceChanged || storeChanged) {
      _bootstrapSpaceContext();
    }
  }

  void _bootstrapSpaceContext() {
    context.read<SpaceMonitoringBloc>().add(
          StartMonitoring(
            storeId: widget.storeId,
            spaceId: widget.spaceId,
          ),
        );
    context.read<CamsPlaybackBloc>().add(
          CamsInitPlayback(spaceId: widget.spaceId),
        );
    context.read<OfflineLibraryBloc>().add(const LoadOfflinePlaylists());
    context.read<PlayerBloc>().add(
          PlayerContextUpdated(
            storeId: widget.storeId,
            spaceId: widget.spaceId,
            spaceName: widget.spaceId,
          ),
        );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _SpaceDetailPalette.fromContext(context);

    return BlocBuilder<SpaceMonitoringBloc, SpaceMonitoringState>(
      builder: (context, state) {
        final spaceName = state.space?.name ?? 'Space';
        final isOnline = state.space?.isOnline ?? false;

        return Scaffold(
          backgroundColor: palette.bg,
          appBar: AppBar(
            backgroundColor: palette.bg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(LucideIcons.chevronLeft, color: palette.textPrimary),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  spaceName,
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? palette.success : palette.warning,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: GoogleFonts.inter(
                        color: palette.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(LucideIcons.settings, color: palette.textPrimary),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SpaceSettingsPage(
                        storeId: widget.storeId,
                        spaceId: widget.spaceId,
                        spaceName: spaceName,
                      ),
                    ),
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: palette.accent,
              labelColor: palette.accent,
              unselectedLabelColor: palette.textMuted,
              tabs: const [
                Tab(icon: Icon(LucideIcons.music4, size: 18), text: 'Player'),
                Tab(
                    icon: Icon(LucideIcons.activity, size: 18),
                    text: 'Sensors'),
                Tab(
                    icon: Icon(LucideIcons.download, size: 18),
                    text: 'Offline'),
              ],
            ),
          ),
          body: switch (state.status) {
            SpaceMonitoringStatus.loading => const _SpaceLoadingView(),
            SpaceMonitoringStatus.error => _SpaceErrorView(
                palette: palette,
                message: state.errorMessage,
                onRetry: _bootstrapSpaceContext,
              ),
            _ => TabBarView(
                controller: _tabController,
                children: [
                  const NowPlayingTabPage(
                    embedInParentScaffold: true,
                    showTopBar: false,
                  ),
                  _SensorsTab(
                    palette: palette,
                    latestSensorData: state.latestSensorData,
                    sensorHistory: state.sensorHistory,
                  ),
                  SpaceOfflineTab(isDarkMode: palette.isDark),
                ],
              ),
          },
        );
      },
    );
  }
}

class _SpaceLoadingView extends StatelessWidget {
  const _SpaceLoadingView();

  @override
  Widget build(BuildContext context) {
    return const CamsSkeletonDetailPage(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 32),
      showLargeArt: false,
    );
  }
}

class _SpaceErrorView extends StatelessWidget {
  const _SpaceErrorView({
    required this.palette,
    required this.message,
    required this.onRetry,
  });

  final _SpaceDetailPalette palette;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertTriangle,
              color: palette.warning,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              message ?? 'Unable to load this space right now.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: palette.textOnAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorsTab extends StatelessWidget {
  const _SensorsTab({
    required this.palette,
    required this.latestSensorData,
    required this.sensorHistory,
  });

  final _SpaceDetailPalette palette;
  final SensorData? latestSensorData;
  final List<SensorData> sensorHistory;

  @override
  Widget build(BuildContext context) {
    final latest = latestSensorData;
    if (latest == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'No sensor telemetry has arrived for this space yet.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _SectionCard(
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live sensor snapshot',
                style: GoogleFonts.poppins(
                  color: palette.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Updated ${_formatTimestamp(latest.timestamp)}',
                style: GoogleFonts.inter(
                  color: palette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _SensorMetricCard(
                    palette: palette,
                    label: 'Temperature',
                    value: '${latest.temperature.toStringAsFixed(1)} C',
                    icon: LucideIcons.thermometer,
                  ),
                  _SensorMetricCard(
                    palette: palette,
                    label: 'Humidity',
                    value: '${latest.humidity.toStringAsFixed(0)}%',
                    icon: LucideIcons.cloudRain,
                  ),
                  _SensorMetricCard(
                    palette: palette,
                    label: 'Noise',
                    value: '${latest.noiseLevel.toStringAsFixed(0)} dB',
                    icon: LucideIcons.volume2,
                  ),
                  if (latest.lightLevel != null)
                    _SensorMetricCard(
                      palette: palette,
                      label: 'Light',
                      value: '${latest.lightLevel!.toStringAsFixed(0)} lx',
                      icon: LucideIcons.sunMedium,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          palette: palette,
          child: Row(
            children: [
              _SummaryPill(
                palette: palette,
                label: 'Samples',
                value: '${sensorHistory.length}',
              ),
              const SizedBox(width: 8),
              _SummaryPill(
                palette: palette,
                label: 'Latest mood context',
                value: latest.noiseLevel >= 70 ? 'Busy' : 'Stable',
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}

class _SensorMetricCard extends StatelessWidget {
  const _SensorMetricCard({
    required this.palette,
    required this.label,
    required this.value,
    required this.icon,
  });

  final _SpaceDetailPalette palette;
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.overlay,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: palette.accent),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.palette,
    required this.label,
    required this.value,
  });

  final _SpaceDetailPalette palette;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.overlay,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                color: palette.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.palette,
    required this.child,
  });

  final _SpaceDetailPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: child,
    );
  }
}

class _SpaceDetailPalette {
  const _SpaceDetailPalette({
    required this.bg,
    required this.card,
    required this.overlay,
    required this.border,
    required this.accent,
    required this.textPrimary,
    required this.textMuted,
    required this.textOnAccent,
    required this.success,
    required this.warning,
    required this.isDark,
  });

  final Color bg;
  final Color card;
  final Color overlay;
  final Color border;
  final Color accent;
  final Color textPrimary;
  final Color textMuted;
  final Color textOnAccent;
  final Color success;
  final Color warning;
  final bool isDark;

  factory _SpaceDetailPalette.fromContext(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.camsTokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _SpaceDetailPalette(
      bg: tokens.bgBase,
      card: tokens.bgContainer,
      overlay: tokens.bgElevated,
      border: tokens.borderSecondary,
      accent: colorScheme.primary,
      textPrimary: tokens.textPrimary,
      textMuted: tokens.textSecondary,
      textOnAccent: colorScheme.onPrimary,
      success: tokens.success,
      warning: tokens.warning,
      isDark: isDark,
    );
  }
}
