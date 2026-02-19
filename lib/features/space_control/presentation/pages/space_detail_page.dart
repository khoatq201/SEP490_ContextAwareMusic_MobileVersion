import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/player/player_event.dart';
import '../utils/mood_color_helper.dart';

import '../bloc/music_control_bloc.dart';
import '../bloc/music_control_event.dart';
import '../bloc/music_control_state.dart';
import '../bloc/space_monitoring_bloc.dart';
import '../bloc/space_monitoring_event.dart';
import '../bloc/space_monitoring_state.dart';
import '../bloc/offline_library_bloc.dart';
import '../bloc/offline_library_event.dart';
import '../../domain/entities/sensor_data.dart';
import '../widgets/space_offline_tab.dart';
import 'space_settings_page.dart';

class SpaceDetailPage extends StatefulWidget {
  final String storeId;
  final String spaceId;

  const SpaceDetailPage({
    Key? key,
    required this.storeId,
    required this.spaceId,
  }) : super(key: key);

  @override
  State<SpaceDetailPage> createState() => _SpaceDetailPageState();
}

class _SpaceDetailPageState extends State<SpaceDetailPage>
    with SingleTickerProviderStateMixin {
  double _volume = 0.6;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<SpaceMonitoringBloc>().add(
          StartMonitoring(
            storeId: widget.storeId,
            spaceId: widget.spaceId,
          ),
        );
    context.read<MusicControlBloc>().add(
          StartMusicMonitoring(
            storeId: widget.storeId,
            spaceId: widget.spaceId,
          ),
        );
    context.read<OfflineLibraryBloc>().add(const LoadOfflinePlaylists());

    // ── Global PlayerBloc: register context + attach MusicControlBloc ──
    final playerBloc = context.read<PlayerBloc>();
    playerBloc.add(PlayerContextUpdated(
      storeId: widget.storeId,
      spaceId: widget.spaceId,
    ));
    playerBloc.attachMusicBloc(context.read<MusicControlBloc>());
  }

  @override
  void dispose() {
    _tabController.dispose();
    context.read<SpaceMonitoringBloc>().add(const StopMonitoring());
    context.read<MusicControlBloc>().add(const StopMusicMonitoring());
    // Clear global player context when leaving the space
    context.read<PlayerBloc>().add(const PlayerContextCleared());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.fromBrightness(Theme.of(context).brightness);

    // ── Sync MusicControlBloc → global PlayerBloc ────────────────────
    return BlocListener<MusicControlBloc, MusicControlState>(
      listener: (context, musicState) {
        context.read<PlayerBloc>().syncFromMusicState(musicState);
      },
      child: BlocBuilder<SpaceMonitoringBloc, SpaceMonitoringState>(
        builder: (context, spaceState) {
          if (spaceState.status == SpaceMonitoringStatus.loading) {
            return Scaffold(
              backgroundColor: palette.bg,
              body: _buildLoading(palette),
            );
          }

          if (spaceState.status == SpaceMonitoringStatus.error) {
            return Scaffold(
              backgroundColor: palette.bg,
              body: SafeArea(
                child: _buildError(palette, spaceState.errorMessage),
              ),
            );
          }

          return Scaffold(
            backgroundColor: palette.bg,
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    pinned: true,
                    floating: true,
                    backgroundColor: palette.bg,
                    surfaceTintColor: Colors.transparent,
                    forceElevated: innerBoxIsScrolled,
                    elevation: innerBoxIsScrolled ? 2 : 0,
                    shadowColor: palette.shadow.withOpacity(0.1),
                    leading: GestureDetector(
                      onTap: () {
                        // Pop back to StoreDashboard; if can't pop, go to store route
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/store/${widget.storeId}');
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: palette.overlay,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: palette.border),
                        ),
                        child: Icon(
                          LucideIcons.chevronLeft,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          spaceState.space?.name ?? 'Space',
                          style: GoogleFonts.poppins(
                            color: palette.textPrimary,
                            fontSize: 20,
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
                                color: spaceState.space?.isOnline ?? false
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              spaceState.space?.isOnline ?? false
                                  ? 'Online'
                                  : 'Offline',
                              style: GoogleFonts.inter(
                                color: palette.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    centerTitle: true,
                    actions: [
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: palette.overlay,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: palette.border),
                        ),
                        child: IconButton(
                          icon: Icon(
                            LucideIcons.settings,
                            color: palette.textPrimary,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SpaceSettingsPage(
                                  storeId: widget.storeId,
                                  spaceId: widget.spaceId,
                                  spaceName: spaceState.space?.name ?? 'Space',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    bottom: TabBar(
                      controller: _tabController,
                      indicatorColor: palette.accent,
                      indicatorWeight: 2.5,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: palette.accent,
                      unselectedLabelColor: palette.textMuted,
                      dividerColor: palette.border.withOpacity(0.3),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                      unselectedLabelStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(
                          icon: Icon(LucideIcons.music4, size: 18),
                          text: 'Player',
                        ),
                        Tab(
                          icon: Icon(LucideIcons.activity, size: 18),
                          text: 'Sensors',
                        ),
                        Tab(
                          icon: Icon(LucideIcons.download, size: 18),
                          text: 'Offline',
                        ),
                      ],
                    ),
                  ),
                ];
              },
              body: BlocBuilder<MusicControlBloc, MusicControlState>(
                builder: (context, musicState) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // Player Tab
                      _buildPlayerTab(context, spaceState, musicState, palette),

                      // Sensors Tab
                      _buildSensorsTab(palette),

                      // Offline Tab
                      SpaceOfflineTab(isDarkMode: palette.isDark),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ), // end BlocBuilder
    ); // end BlocListener
  }

  Widget _buildLoading(_Palette palette) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: palette.accent),
          const SizedBox(height: 16),
          Text(
            'Connecting to your space...',
            style: GoogleFonts.inter(color: palette.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildError(_Palette palette, String? message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.alertTriangle, color: Colors.amber, size: 52),
          const SizedBox(height: 12),
          Text(
            message ?? 'Something went wrong',
            style: GoogleFonts.inter(color: palette.textMuted, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: palette.textOnAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              context.read<SpaceMonitoringBloc>().add(
                    StartMonitoring(
                      storeId: widget.storeId,
                      spaceId: widget.spaceId,
                    ),
                  );
            },
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTab(
    BuildContext context,
    SpaceMonitoringState spaceState,
    MusicControlState musicState,
    _Palette palette,
  ) {
    return Stack(
      children: [
        RefreshIndicator(
          color: palette.accent,
          backgroundColor: palette.card,
          onRefresh: () async {
            context.read<SpaceMonitoringBloc>().add(
                  StartMonitoring(
                    storeId: widget.storeId,
                    spaceId: widget.spaceId,
                  ),
                );
            context.read<MusicControlBloc>().add(
                  StartMusicMonitoring(
                    storeId: widget.storeId,
                    spaceId: widget.spaceId,
                  ),
                );
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SensorDashboard(
                  sensorData: spaceState.latestSensorData,
                  palette: palette,
                ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08),
                const SizedBox(height: 20),
                MusicPlayerHero(
                  state: musicState,
                  mood: spaceState.space?.currentMood,
                  palette: palette,
                ).animate().fadeIn(duration: 380.ms).slideY(begin: 0.1),
                const SizedBox(height: 16),
                MusicPlayerControls(
                  state: musicState,
                  onPlayPause: () => _handlePlayPause(musicState),
                  onSkip: () => _handleSkip(musicState),
                  onVolumeChanged: (v) => setState(() => _volume = v),
                  volume: _volume,
                  palette: palette,
                ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.12),
                const SizedBox(height: 20),
                ManualOverrideCTA(
                  spaceId: widget.spaceId,
                  currentMood: spaceState.space?.currentMood,
                  accent: palette.accent,
                  palette: palette,
                ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.12),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        // Next Queue Panel
        if (spaceState.status == SpaceMonitoringStatus.monitoring)
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: NextTrackPanel(
                state: musicState,
                accent: palette.accent,
                palette: palette,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSensorsTab(_Palette palette) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.activity,
            size: 64,
            color: palette.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Sensor Charts',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _handlePlayPause(MusicControlState state) {
    final spaceId = state.playerState?.currentTrack?.id;
    if (spaceId == null) return;
    if (state.status == MusicControlStatus.playing) {
      context.read<MusicControlBloc>().add(PauseMusic(spaceId));
    } else {
      context.read<MusicControlBloc>().add(PlayMusic(spaceId));
    }
  }

  void _handleSkip(MusicControlState state) {
    final spaceId = state.playerState?.currentTrack?.id;
    if (spaceId == null) return;
    context.read<MusicControlBloc>().add(SkipMusic(spaceId));
  }
}

class SpaceHeader extends StatelessWidget {
  const SpaceHeader({
    super.key,
    required this.name,
    required this.mood,
    required this.isOnline,
    required this.onBack,
    required this.onSettings,
    required this.palette,
  });

  final String name;
  final String? mood;
  final bool isOnline;
  final VoidCallback onBack;
  final VoidCallback onSettings;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.overlay,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border),
            ),
            child: Icon(LucideIcons.chevronLeft, color: palette.textPrimary),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                name,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: palette.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatusDot(isOnline: isOnline),
                  const SizedBox(width: 8),
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: GoogleFonts.inter(
                      color: palette.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (mood != null) ...[
                    const SizedBox(width: 12),
                    Icon(LucideIcons.sparkles,
                        color: palette.textMuted, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      mood!,
                      style: GoogleFonts.inter(
                        color: palette.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onSettings,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.overlay,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border),
            ),
            child: Icon(LucideIcons.settings, color: palette.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.isOnline});
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isOnline
              ? [const Color(0xFF34D399), const Color(0xFF10B981)]
              : [const Color(0xFFF59E0B), const Color(0xFFF97316)],
        ),
        boxShadow: [
          BoxShadow(
            color: (isOnline ? Colors.greenAccent : Colors.orangeAccent)
                .withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

class SensorDashboard extends StatelessWidget {
  const SensorDashboard(
      {super.key, required this.sensorData, required this.palette});
  final SensorData? sensorData;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    final cards = [
      SensorCard(
        icon: LucideIcons.thermometer,
        label: 'Temperature',
        value: sensorData != null
            ? '${sensorData!.temperature.toStringAsFixed(1)}°C'
            : '--',
        badge: 'Stable',
        gradient: [palette.accentAlt, palette.accent],
        palette: palette,
        isAlert: false,
      ),
      SensorCard(
        icon: LucideIcons.volume2,
        label: 'Noise',
        value: sensorData != null
            ? '${sensorData!.noiseLevel.toStringAsFixed(0)} dB'
            : '--',
        badge: _noiseBadge(sensorData?.noiseLevel),
        gradient: [palette.accent, palette.accentAlt],
        palette: palette,
        isAlert: _noiseBadge(sensorData?.noiseLevel) == 'Loud',
      ),
      SensorCard(
        icon: LucideIcons.users,
        label: 'Crowd',
        value: sensorData != null ? _crowdEstimate(sensorData!) : 'N/A',
        badge: 'Live',
        gradient: [palette.accentAlt, palette.accent.withOpacity(0.9)],
        palette: palette,
        isAlert: false,
      ),
      SensorCard(
        icon: LucideIcons.cloudRain,
        label: 'Humidity',
        value: sensorData != null
            ? '${sensorData!.humidity.toStringAsFixed(0)}%'
            : '--',
        badge: _humidityBadge(sensorData?.humidity),
        gradient: [palette.accent.withOpacity(0.85), palette.accentAlt],
        palette: palette,
        isAlert: false,
      ),
    ];

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => cards[index],
      ),
    );
  }

  String _noiseBadge(double? noise) {
    if (noise == null) return 'N/A';
    if (noise < 50) return 'Quiet';
    if (noise < 70) return 'Moderate';
    return 'Loud';
  }

  String _crowdEstimate(SensorData data) {
    // Simple heuristic using noise level; adjust when real metric is available.
    if (data.noiseLevel < 45) return 'Low';
    if (data.noiseLevel < 65) return 'Medium';
    return 'High';
  }

  String _humidityBadge(double? humidity) {
    if (humidity == null) return 'N/A';
    if (humidity < 30) return 'Dry';
    if (humidity < 60) return 'Optimal';
    return 'Humid';
  }
}

class SensorCard extends StatelessWidget {
  const SensorCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.badge,
    required this.gradient,
    required this.palette,
    required this.isAlert,
  });

  final IconData icon;
  final String label;
  final String value;
  final String badge;
  final List<Color> gradient;
  final _Palette palette;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    final Color dynamicTone = isAlert
        ? Theme.of(context).colorScheme.error.withOpacity(0.9)
        : palette.accent;

    final BoxDecoration wrapperDecoration = palette.isDark
        ? BoxDecoration(
            color: const Color(0xFF0B0F19),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(
              color: dynamicTone.withOpacity(0.25),
              width: 0.8,
            ),
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          );

    return Container(
      width: 160,
      decoration: wrapperDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: palette.isDark
                  ? LinearGradient(
                      colors: [
                        dynamicTone.withOpacity(0.10),
                        dynamicTone.withOpacity(0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        palette.textOnAccent
                            .withOpacity(palette.isDark ? 0.12 : 0.18),
                        palette.textOnAccent
                            .withOpacity(palette.isDark ? 0.08 : 0.12),
                      ],
                    ),
              border: Border.all(
                color: palette.isDark
                    ? dynamicTone.withOpacity(0.35)
                    : palette.border.withOpacity(0.6),
                width: palette.isDark ? 0.8 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: palette.isDark
                            ? dynamicTone.withOpacity(0.14)
                            : palette.textOnAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon,
                          color: palette.isDark
                              ? dynamicTone
                              : palette.textOnAccent,
                          size: 20),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: palette.isDark
                            ? Colors.white.withOpacity(0.05)
                            : palette.textOnAccent.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: palette.textOnAccent.withOpacity(0.2)),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.inter(
                          color: palette.textOnAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: palette.isDark ? dynamicTone : palette.textOnAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: palette.textOnAccent.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MusicPlayerHero extends StatelessWidget {
  const MusicPlayerHero({
    super.key,
    required this.state,
    required this.mood,
    required this.palette,
  });

  final MusicControlState state;
  final String? mood;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    final track = state.playerState?.currentTrack;
    final gradientColors = palette.isDark
        ? const [Color(0xFF1F2937), Color(0xFF111827)]
        : [palette.card, palette.card.withOpacity(0.92)];
    final moodGradient = MoodColorHelper.gradientFor(mood);
    final moodShadow = MoodColorHelper.shadowColorFor(mood);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: double.infinity,
                height: 260,
                decoration: BoxDecoration(
                  gradient: moodGradient,
                  boxShadow: [
                    BoxShadow(
                      color: moodShadow,
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: track?.albumArt != null
                    ? Image.network(
                        track!.albumArt!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MoodBadge(mood: mood, palette: palette),
                const SizedBox(width: 12),
                if (state.playerState?.isPlayingFromCache ?? false)
                  _MiniBadge(label: 'Offline Cache', palette: palette),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              track?.title ?? 'No track playing',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: palette.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              track?.artist ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: MoodColorHelper.gradientFor(mood),
      ),
      child: Center(
        child: Icon(LucideIcons.music4,
            color: palette.textOnAccent.withOpacity(0.8), size: 48),
      ),
    );
  }
}

class MusicPlayerControls extends StatelessWidget {
  const MusicPlayerControls({
    super.key,
    required this.state,
    required this.onPlayPause,
    required this.onSkip,
    required this.onVolumeChanged,
    required this.volume,
    required this.palette,
  });

  final MusicControlState state;
  final VoidCallback onPlayPause;
  final VoidCallback onSkip;
  final ValueChanged<double> onVolumeChanged;
  final double volume;
  final _Palette palette;

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final track = state.playerState?.currentTrack;
    final duration = track?.duration ?? 0;
    final currentPosition = state.playerState?.currentPosition ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          if (duration > 0) ...[
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: palette.accent,
                inactiveTrackColor: palette.textMuted.withOpacity(0.2),
                thumbColor: palette.accentAlt,
                overlayColor: palette.accent.withOpacity(0.2),
              ),
              child: Slider(
                value: currentPosition.clamp(0, duration).toDouble(),
                min: 0,
                max: duration.toDouble(),
                onChanged: (_) {},
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(currentPosition),
                    style: GoogleFonts.inter(
                        color: palette.textMuted, fontSize: 12),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: GoogleFonts.inter(
                        color: palette.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ControlIcon(
                icon: LucideIcons.skipBack,
                onTap: () {},
                palette: palette,
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: onPlayPause,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [palette.accent, palette.accentAlt],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: palette.accent.withOpacity(0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    state.status == MusicControlStatus.playing
                        ? LucideIcons.pause
                        : LucideIcons.play,
                    color: palette.textOnAccent,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _ControlIcon(
                icon: LucideIcons.skipForward,
                onTap: onSkip,
                palette: palette,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Volume
          Row(
            children: [
              Icon(LucideIcons.volume, color: palette.textMuted, size: 18),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: palette.accent,
                    inactiveTrackColor: palette.textMuted.withOpacity(0.2),
                    thumbColor: palette.accentAlt,
                    overlayColor: palette.accent.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: volume,
                    onChanged: onVolumeChanged,
                  ),
                ),
              ),
              Text(
                '${(volume * 100).round()}%',
                style:
                    GoogleFonts.inter(color: palette.textMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlIcon extends StatelessWidget {
  const _ControlIcon(
      {required this.icon, required this.onTap, required this.palette});
  final IconData icon;
  final VoidCallback onTap;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.overlay,
          border: Border.all(color: palette.border),
        ),
        child: Icon(icon, color: palette.textPrimary, size: 22),
      ),
    );
  }
}

class _MoodBadge extends StatelessWidget {
  const _MoodBadge({this.mood, required this.palette});
  final String? mood;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    if (mood == null) return const SizedBox.shrink();
    final gradient = MoodColorHelper.gradientFor(mood);
    final shadowColor = MoodColorHelper.shadowColorFor(mood);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
              color: shadowColor, blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.flame, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            mood!,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.palette});
  final String label;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.overlay,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: palette.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ManualOverrideCTA extends StatelessWidget {
  const ManualOverrideCTA({
    super.key,
    required this.spaceId,
    required this.currentMood,
    required this.accent,
    required this.palette,
  });

  final String spaceId;
  final String? currentMood;
  final Color accent;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    final gradientColors = palette.isDark
        ? [
            palette.accent.withOpacity(0.75),
            palette.accentAlt.withOpacity(0.55),
          ]
        : [accent, accent.withOpacity(0.7)];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: gradientColors),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        ),
        onPressed: () => _openOverrideDialog(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Override Mood',
                  style: GoogleFonts.poppins(
                    color: palette.textOnAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentMood != null
                      ? 'Current: ${currentMood!.toUpperCase()}'
                      : 'Set a new atmosphere',
                  style: GoogleFonts.inter(
                    color: palette.textOnAccent.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Icon(LucideIcons.slidersHorizontal, color: palette.textOnAccent),
          ],
        ),
      ),
    );
  }

  void _openOverrideDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: palette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        String mood = currentMood ?? 'happy';
        int duration = 30;
        final moods = ['happy', 'chill', 'energetic', 'romantic', 'focus'];

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 16),
                  Text(
                    'Override Mood',
                    style: GoogleFonts.poppins(
                      color: palette.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: moods
                        .map(
                          (m) => ChoiceChip(
                            label: Text(
                              m.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: mood == m
                                    ? palette.textOnAccent
                                    : palette.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            selected: mood == m,
                            onSelected: (_) => setModalState(() {
                              mood = m;
                            }),
                            backgroundColor: palette.overlay,
                            selectedColor: palette.accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: palette.border),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Duration (minutes)',
                    style: GoogleFonts.inter(
                        color: palette.textMuted, fontSize: 12),
                  ),
                  Slider(
                    value: duration.toDouble(),
                    min: 10,
                    max: 120,
                    divisions: 11,
                    activeColor: palette.accent,
                    inactiveColor: palette.textMuted.withOpacity(0.2),
                    label: '$duration',
                    onChanged: (v) => setModalState(() {
                      duration = v.round();
                    }),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.textMuted,
                            side: BorderSide(color: palette.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: palette.accent,
                            foregroundColor: palette.textOnAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            context.read<MusicControlBloc>().add(
                                  OverrideMoodRequested(
                                    spaceId: spaceId,
                                    moodId: mood,
                                    duration: duration,
                                  ),
                                );
                            Navigator.pop(sheetContext);
                          },
                          child: const Text(
                            'Apply',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class NextTrackPanel extends StatelessWidget {
  const NextTrackPanel(
      {super.key,
      required this.state,
      required this.accent,
      required this.palette});
  final MusicControlState state;
  final Color accent;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    final track = state.playerState?.currentTrack;
    return DraggableScrollableSheet(
      minChildSize: 0.10,
      initialChildSize: 0.10,
      maxChildSize: 0.35,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: ListView(
            controller: controller,
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 6),
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
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                leading: _NextArtwork(track?.albumArt, palette: palette),
                title: Text(
                  'Next Track',
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  track?.title ?? 'No upcoming track',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accent.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.timer, color: accent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'ETA 00:30',
                        style: GoogleFonts.inter(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NextArtwork extends StatelessWidget {
  const _NextArtwork(this.url, {required this.palette});
  final String? url;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 50,
        height: 50,
        color: palette.overlay,
        child: url != null
            ? Image.network(url!, fit: BoxFit.cover)
            : Icon(LucideIcons.music4, color: palette.textMuted, size: 20),
      ),
    );
  }
}

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
