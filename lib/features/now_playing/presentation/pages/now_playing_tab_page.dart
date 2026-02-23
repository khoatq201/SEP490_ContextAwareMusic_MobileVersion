import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/player/player_event.dart';
import '../../../../core/player/player_state.dart' as ps;
import '../../../../core/player/space_info.dart';
import '../../../../features/space_control/presentation/bloc/music_control_bloc.dart';
import '../../../../features/space_control/presentation/bloc/music_control_event.dart';
import '../../../../features/space_control/presentation/bloc/music_control_state.dart';
import '../../../../features/space_control/presentation/bloc/space_monitoring_bloc.dart';
import '../../../../features/space_control/presentation/bloc/space_monitoring_event.dart';
import '../../../../features/space_control/presentation/bloc/space_monitoring_state.dart';
import '../../../../features/space_control/domain/entities/sensor_data.dart';

/// Dedicated "Now Playing" tab â€“ always visible in BottomBar.
/// Reads from global [PlayerBloc], [MusicControlBloc], and [SpaceMonitoringBloc].
class NowPlayingTabPage extends StatefulWidget {
  const NowPlayingTabPage({super.key});

  @override
  State<NowPlayingTabPage> createState() => _NowPlayingTabPageState();
}

class _NowPlayingTabPageState extends State<NowPlayingTabPage> {
  double _volume = 0.6;

  @override
  Widget build(BuildContext context) {
    final palette = _NPPalette.fromBrightness(Theme.of(context).brightness);

    return BlocBuilder<PlayerBloc, ps.PlayerState>(
      builder: (context, playerState) {
        return BlocBuilder<SpaceMonitoringBloc, SpaceMonitoringState>(
          builder: (context, spaceState) {
            return BlocBuilder<MusicControlBloc, MusicControlState>(
              builder: (context, musicState) {
                return Scaffold(
                  backgroundColor: palette.bg,
                  body: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      SliverAppBar(
                        pinned: true,
                        floating: true,
                        backgroundColor: palette.bg,
                        surfaceTintColor: Colors.transparent,
                        forceElevated: innerBoxIsScrolled,
                        elevation: innerBoxIsScrolled ? 2 : 0,
                        shadowColor: palette.shadow.withOpacity(0.1),
                        automaticallyImplyLeading: false,
                        title: _SpaceNameTitle(
                          spaceName: spaceState.space?.name ??
                              playerState.activeSpaceName ??
                              'Now Playing',
                          isOnline: spaceState.space?.isOnline ?? false,
                          hasTrack: playerState.hasTrack,
                          canSwap: playerState.availableSpaces.length > 1,
                          palette: palette,
                          onTap: playerState.availableSpaces.length > 1
                              ? () => showModalBottomSheet(
                                    context: context,
                                    useRootNavigator: true,
                                    backgroundColor: Colors.transparent,
                                    isScrollControlled: true,
                                    builder: (_) => _SpaceSwapSheet(
                                      playerState: playerState,
                                      palette: palette,
                                    ),
                                  )
                              : null,
                        ),
                        centerTitle: true,
                      ),
                    ],
                    body: _buildPlayerContent(
                      context,
                      playerState,
                      spaceState,
                      musicState,
                      palette,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPlayerContent(
    BuildContext context,
    ps.PlayerState playerState,
    SpaceMonitoringState spaceState,
    MusicControlState musicState,
    _NPPalette palette,
  ) {
    final track = playerState.currentTrack;
    final trackMoodTags = track?.moodTags;
    final mood = (trackMoodTags != null && trackMoodTags.isNotEmpty)
        ? trackMoodTags.first
        : spaceState.space?.currentMood;
    final duration = playerState.duration;
    final currentPosition = playerState.currentPosition;
    // isPlaying: prefer MusicControlBloc (space-connected) but fall back to
    // PlayerBloc's own flag (e.g. local track tapped from a playlist).
    final isPlaying = musicState.status == MusicControlStatus.playing ||
        (musicState.status == MusicControlStatus.initial &&
            playerState.isPlaying);

    // "No space" hint shown at top when neither space nor track is active
    final hasNoContext = !playerState.hasTrack && spaceState.space == null;

    return Stack(
      children: [
        RefreshIndicator(
          color: palette.accent,
          backgroundColor: palette.card,
          onRefresh: () async {},
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── "No space connected" banner ─────────────────────────
                if (hasNoContext) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: palette.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: palette.accent.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.info, color: palette.accent, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Mở một Space để bắt đầu phát nhạc tự động, '
                            'hoặc bấm vào một bài nhạc từ trang Home.',
                            style: GoogleFonts.inter(
                              color: palette.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 16),
                ],

                //  Sensor dashboard
                if (spaceState.latestSensorData != null ||
                    spaceState.status == SpaceMonitoringStatus.monitoring) ...[
                  _SensorDashboard(
                    sensorData: spaceState.latestSensorData,
                    palette: palette,
                  ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08),
                  const SizedBox(height: 20),
                ],

                //  Album art hero
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: palette.card,
                    border: Border.all(color: palette.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: SizedBox(
                            width: double.infinity,
                            height: 260,
                            child: track?.albumArt != null
                                ? Image.network(
                                    track!.albumArt!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _artPlaceholder(palette),
                                  )
                                : _artPlaceholder(palette),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (mood != null)
                              _MoodBadge(mood: mood, palette: palette),
                            if (track?.isAvailableOffline ?? false) ...[
                              const SizedBox(width: 10),
                              _MiniBadge(
                                  label: 'Offline Cache', palette: palette),
                            ],
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
                          track?.artist ?? '',
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
                ).animate().fadeIn(duration: 380.ms).slideY(begin: 0.1),

                const SizedBox(height: 16),

                //  Controls card
                Container(
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
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14),
                            activeTrackColor: palette.accent,
                            inactiveTrackColor:
                                palette.textMuted.withOpacity(0.2),
                            thumbColor: palette.accentAlt,
                            overlayColor: palette.accent.withOpacity(0.2),
                          ),
                          child: Slider(
                            value:
                                currentPosition.clamp(0, duration).toDouble(),
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
                              Text(_fmt(currentPosition),
                                  style: GoogleFonts.inter(
                                      color: palette.textMuted, fontSize: 12)),
                              Text(_fmt(duration),
                                  style: GoogleFonts.inter(
                                      color: palette.textMuted, fontSize: 12)),
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
                            onTap: () => context
                                .read<PlayerBloc>()
                                .add(const PlayerPlayPauseToggled()),
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: palette.accent,
                              ),
                              child: Icon(
                                isPlaying
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
                            onTap: () => context
                                .read<PlayerBloc>()
                                .add(const PlayerSkipRequested()),
                            palette: palette,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(LucideIcons.volume,
                              color: palette.textMuted, size: 18),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                activeTrackColor: palette.accent,
                                inactiveTrackColor:
                                    palette.textMuted.withOpacity(0.2),
                                thumbColor: palette.accentAlt,
                                overlayColor: palette.accent.withOpacity(0.2),
                              ),
                              child: Slider(
                                value: _volume,
                                onChanged: (v) => setState(() => _volume = v),
                              ),
                            ),
                          ),
                          Text('${(_volume * 100).round()}%',
                              style: GoogleFonts.inter(
                                  color: palette.textMuted, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.12),

                const SizedBox(height: 16),

                //  Override Mood CTA
                if (playerState.activeSpaceId != null)
                  _OverrideMoodCTA(
                    spaceId: playerState.activeSpaceId!,
                    currentMood: mood,
                    palette: palette,
                  ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.12),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        //  Next Queue draggable panel
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _NextTrackPanel(
              state: playerState,
              palette: palette,
            ),
          ),
        ),
      ],
    );
  }

  Widget _artPlaceholder(_NPPalette palette) {
    return Container(
      color: palette.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      child: Center(
        child: Icon(Icons.music_note, color: Colors.grey.shade400, size: 64),
      ),
    );
  }

  String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

//
// Sensor Dashboard
//
class _SensorDashboard extends StatelessWidget {
  const _SensorDashboard({required this.sensorData, required this.palette});
  final SensorData? sensorData;
  final _NPPalette palette;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SensorCard(
        icon: LucideIcons.thermometer,
        label: 'Temperature',
        value: sensorData != null
            ? '${sensorData!.temperature.toStringAsFixed(1)}C'
            : '--',
        badge: 'Stable',
        palette: palette,
        isAlert: false,
      ),
      _SensorCard(
        icon: LucideIcons.volume2,
        label: 'Noise',
        value: sensorData != null
            ? '${sensorData!.noiseLevel.toStringAsFixed(0)} dB'
            : '--',
        badge: _noiseBadge(sensorData?.noiseLevel),
        palette: palette,
        isAlert: _noiseBadge(sensorData?.noiseLevel) == 'Loud',
      ),
      _SensorCard(
        icon: LucideIcons.users,
        label: 'Crowd',
        value: sensorData != null ? _crowdEstimate(sensorData!) : 'N/A',
        badge: 'Live',
        palette: palette,
        isAlert: false,
      ),
      _SensorCard(
        icon: LucideIcons.cloudRain,
        label: 'Humidity',
        value: sensorData != null
            ? '${sensorData!.humidity.toStringAsFixed(0)}%'
            : '--',
        badge: _humidityBadge(sensorData?.humidity),
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
        itemBuilder: (_, i) => cards[i],
      ),
    );
  }

  String _noiseBadge(double? n) {
    if (n == null) return 'N/A';
    if (n < 50) return 'Quiet';
    if (n < 70) return 'Moderate';
    return 'Loud';
  }

  String _crowdEstimate(SensorData d) {
    if (d.noiseLevel < 45) return 'Low';
    if (d.noiseLevel < 65) return 'Medium';
    return 'High';
  }

  String _humidityBadge(double? h) {
    if (h == null) return 'N/A';
    if (h < 30) return 'Dry';
    if (h < 60) return 'Optimal';
    return 'Humid';
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.badge,
    required this.palette,
    required this.isAlert,
  });

  final IconData icon;
  final String label;
  final String value;
  final String badge;
  final _NPPalette palette;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    final Color accentColor =
        isAlert ? Theme.of(context).colorScheme.error : palette.accent;

    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.overlay,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border),
                ),
                child: Text(badge,
                    style: GoogleFonts.inter(
                        color: palette.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.inter(
                  color: palette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

//
// Override Mood CTA
//
class _OverrideMoodCTA extends StatelessWidget {
  const _OverrideMoodCTA({
    required this.spaceId,
    required this.currentMood,
    required this.palette,
  });

  final String spaceId;
  final String? currentMood;
  final _NPPalette palette;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      ),
      onPressed: () => _openOverrideDialog(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Override Mood',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                currentMood != null
                    ? 'Current: ${currentMood!.toUpperCase()}'
                    : 'Set a new atmosphere',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Icon(LucideIcons.slidersHorizontal),
        ],
      ),
    );
  }

  void _openOverrideDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: palette.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) {
        String mood = currentMood ?? 'happy';
        int durationMin = 30;
        final moods = ['happy', 'chill', 'energetic', 'romantic', 'focus'];
        return StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
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
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Override Mood',
                    style: GoogleFonts.poppins(
                        color: palette.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: moods
                      .map(
                        (m) => ChoiceChip(
                          label: Text(m.toUpperCase(),
                              style: GoogleFonts.inter(
                                  color: mood == m
                                      ? palette.textOnAccent
                                      : palette.textPrimary,
                                  fontWeight: FontWeight.w700)),
                          selected: mood == m,
                          onSelected: (_) => setModalState(() => mood = m),
                          backgroundColor: palette.overlay,
                          selectedColor: palette.accent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: palette.border)),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                Text('Duration (minutes)',
                    style: GoogleFonts.inter(
                        color: palette.textMuted, fontSize: 12)),
                Slider(
                  value: durationMin.toDouble(),
                  min: 10,
                  max: 120,
                  divisions: 11,
                  activeColor: palette.accent,
                  inactiveColor: palette.textMuted.withOpacity(0.2),
                  label: '$durationMin',
                  onChanged: (v) =>
                      setModalState(() => durationMin = v.round()),
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
                                borderRadius: BorderRadius.circular(14))),
                        onPressed: () => Navigator.pop(sheetCtx),
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
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () {
                          context.read<MusicControlBloc>().add(
                                OverrideMoodRequested(
                                    spaceId: spaceId,
                                    moodId: mood,
                                    duration: durationMin),
                              );
                          Navigator.pop(sheetCtx);
                        },
                        child: const Text('Apply',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

//
// Shared small widgets
//
class _ControlIcon extends StatelessWidget {
  const _ControlIcon(
      {required this.icon, required this.onTap, required this.palette});
  final IconData icon;
  final VoidCallback onTap;
  final _NPPalette palette;

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
  const _MoodBadge({required this.mood, required this.palette});
  final String mood;
  final _NPPalette palette;

  @override
  Widget build(BuildContext context) {
    final accent = palette.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: accent.withOpacity(0.12),
        border: Border.all(color: accent.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.flame, color: accent, size: 14),
          const SizedBox(width: 6),
          Text(mood.toUpperCase(),
              style: GoogleFonts.inter(
                  color: accent, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.palette});
  final String label;
  final _NPPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.overlay,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              color: palette.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.isOnline});
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Next track draggable bottom panel
// ─────────────────────────────────────────────────────────────────────────────
class _NextTrackPanel extends StatelessWidget {
  const _NextTrackPanel({required this.state, required this.palette});
  final ps.PlayerState state;
  final _NPPalette palette;

  @override
  Widget build(BuildContext context) {
    final track = state.currentTrack;
    final accent = palette.accent;
    return DraggableScrollableSheet(
      minChildSize: 0.09,
      initialChildSize: 0.09,
      maxChildSize: 0.32,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                  color: palette.shadow,
                  blurRadius: 20,
                  offset: const Offset(0, -6))
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
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 50,
                    height: 50,
                    color: palette.overlay,
                    child: track?.albumArt != null
                        ? Image.network(track!.albumArt!, fit: BoxFit.cover)
                        : Icon(LucideIcons.music4,
                            color: palette.textMuted, size: 20),
                  ),
                ),
                title: Text('Next Track',
                    style: GoogleFonts.inter(
                        color: palette.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                subtitle: Text(
                  track?.title ?? 'No upcoming track',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      color: palette.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700),
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
                      Text('ETA 00:30',
                          style: GoogleFonts.inter(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Space Name Title (AppBar widget — tappable if multiple spaces available)
// ─────────────────────────────────────────────────────────────────────────────

class _SpaceNameTitle extends StatelessWidget {
  const _SpaceNameTitle({
    required this.spaceName,
    required this.isOnline,
    required this.hasTrack,
    required this.canSwap,
    required this.palette,
    this.onTap,
  });

  final String spaceName;
  final bool isOnline;
  final bool hasTrack;
  final bool canSwap;
  final _NPPalette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                spaceName,
                style: GoogleFonts.poppins(
                  color: palette.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (canSwap) ...[
                const SizedBox(width: 4),
                Icon(Icons.expand_more, color: palette.textMuted, size: 20),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusDot(isOnline: isOnline),
              const SizedBox(width: 6),
              Text(
                isOnline
                    ? 'Online'
                    : hasTrack
                        ? 'Streaming'
                        : 'No active space',
                style: GoogleFonts.inter(
                  color: palette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (canSwap) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Đổi',
                    style: GoogleFonts.inter(
                      color: palette.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Space Swap Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SpaceSwapSheet extends StatelessWidget {
  const _SpaceSwapSheet({
    required this.playerState,
    required this.palette,
  });

  final ps.PlayerState playerState;
  final _NPPalette palette;

  void _switchSpace(BuildContext context, SpaceInfo space) {
    context.read<SpaceMonitoringBloc>().add(
          StartMonitoring(storeId: space.storeId, spaceId: space.id),
        );
    context.read<MusicControlBloc>().add(
          StartMusicMonitoring(storeId: space.storeId, spaceId: space.id),
        );
    context.read<PlayerBloc>().add(
          PlayerContextUpdated(
            storeId: space.storeId,
            spaceId: space.id,
            spaceName: space.name,
            availableSpaces: playerState.availableSpaces,
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final spaces = playerState.availableSpaces;
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 32 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle bar ──────────────────────────────────────────────
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
          // ── Title ───────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.spatial_audio_outlined,
                  color: palette.accent, size: 22),
              const SizedBox(width: 10),
              Text(
                'Chọn không gian',
                style: GoogleFonts.poppins(
                  color: palette.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Đổi space sẽ cập nhật cảm biến, nhạc và trạng thái Hub.',
            style: GoogleFonts.inter(color: palette.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Divider(color: palette.border, height: 1),
          // ── Space list ──────────────────────────────────────────────
          if (spaces.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Không có không gian nào.',
                  style: GoogleFonts.inter(color: palette.textMuted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: spaces.length,
              separatorBuilder: (_, __) =>
                  Divider(color: palette.border, height: 1),
              itemBuilder: (context, i) {
                final space = spaces[i];
                final isActive = space.id == playerState.activeSpaceId;
                final moodColor = _moodColor(space.currentMood, palette);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isActive
                          ? palette.accent.withOpacity(0.15)
                          : palette.overlay,
                      borderRadius: BorderRadius.circular(12),
                      border: isActive
                          ? Border.all(color: palette.accent, width: 1.5)
                          : null,
                    ),
                    child: Icon(
                      Icons.spatial_audio_outlined,
                      color: isActive ? palette.accent : palette.textMuted,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    space.name,
                    style: GoogleFonts.inter(
                      color: palette.textPrimary,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  subtitle: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: space.isOnline ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        space.isOnline ? 'Online' : 'Offline',
                        style: GoogleFonts.inter(
                            color: palette.textMuted, fontSize: 11),
                      ),
                      if (space.currentMood != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: moodColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            space.currentMood!.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: moodColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: isActive
                      ? Icon(Icons.check_circle_rounded,
                          color: palette.accent, size: 22)
                      : Icon(Icons.chevron_right,
                          color: palette.textMuted, size: 22),
                  onTap: isActive ? null : () => _switchSpace(context, space),
                );
              },
            ),
        ],
      ),
    );
  }

  Color _moodColor(String? mood, _NPPalette palette) {
    if (mood == null) return palette.accent;
    switch (mood.toLowerCase()) {
      case 'energetic':
        return Colors.orange;
      case 'calm':
      case 'chill':
        return Colors.blue;
      case 'happy':
        return Colors.amber;
      case 'romantic':
        return Colors.pink;
      case 'focus':
        return Colors.teal;
      case 'welcoming':
        return Colors.green;
      default:
        return palette.accent;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────────────────────
class _NPPalette {
  const _NPPalette({
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

  factory _NPPalette.fromBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    if (isDark) {
      return _NPPalette(
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
    return _NPPalette(
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
