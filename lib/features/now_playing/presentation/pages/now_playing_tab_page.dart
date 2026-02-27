import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
import '../../../../core/session/session_cubit.dart';

/// Redesigned "Now Playing" tab — Spotify-style full-screen player.
class NowPlayingTabPage extends StatefulWidget {
  const NowPlayingTabPage({super.key});

  @override
  State<NowPlayingTabPage> createState() => _NowPlayingTabPageState();
}

class _NowPlayingTabPageState extends State<NowPlayingTabPage> {
  double _volume = 0.6;
  bool _isShuffleOn = false;

  @override
  Widget build(BuildContext context) {
    final palette = _NPPalette.fromBrightness(Theme.of(context).brightness);
    final session = context.watch<SessionCubit>().state;
    final isPlayback = session.isPlaybackDevice;

    return BlocBuilder<PlayerBloc, ps.PlayerState>(
      builder: (context, playerState) {
        return BlocBuilder<SpaceMonitoringBloc, SpaceMonitoringState>(
          builder: (context, spaceState) {
            return BlocBuilder<MusicControlBloc, MusicControlState>(
              builder: (context, musicState) {
                return Scaffold(
                  backgroundColor: palette.bg,
                  body: SafeArea(
                    bottom: false,
                    child: _buildBody(
                      context,
                      playerState,
                      spaceState,
                      musicState,
                      palette,
                      isPlayback,
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

  Widget _buildBody(
    BuildContext context,
    ps.PlayerState playerState,
    SpaceMonitoringState spaceState,
    MusicControlState musicState,
    _NPPalette palette,
    bool isPlayback,
  ) {
    final track = playerState.currentTrack;
    final trackMoodTags = track?.moodTags;
    final mood = (trackMoodTags != null && trackMoodTags.isNotEmpty)
        ? trackMoodTags.first
        : spaceState.space?.currentMood;
    final duration = playerState.duration;
    final currentPosition = playerState.currentPosition;
    final isPlaying = musicState.status == MusicControlStatus.playing ||
        (musicState.status == MusicControlStatus.initial &&
            playerState.isPlaying);

    final spaceName =
        spaceState.space?.name ?? playerState.activeSpaceName ?? 'No Space';
    final playlistName = mood?.toUpperCase() ?? 'MUSIC';

    // Device label for "Playing from"
    final String deviceLabel;
    if (isPlayback) {
      deviceLabel = 'This Device';
    } else {
      deviceLabel = spaceName;
    }

    return Column(
      children: [
        // ── Top bar: ↓  title  ⋮ ──────────────────────────────────────
        _TopBar(
          spaceName: spaceName,
          playlistName: playlistName,
          palette: palette,
          canSwap: !isPlayback && playerState.availableSpaces.length > 1,
          onMinimize: () {
            // Navigate back to previous tab (go to home)
            context.go('/home');
          },
          onMenu: () => _showSongOptionsSheet(context, playerState, palette),
          onTitleTap: (!isPlayback && playerState.availableSpaces.length > 1)
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

        // ── Scrollable content ────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Sensor dashboard (if monitoring)
                if (spaceState.latestSensorData != null ||
                    spaceState.status == SpaceMonitoringStatus.monitoring) ...[
                  _SensorDashboard(
                    sensorData: spaceState.latestSensorData,
                    palette: palette,
                  ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08),
                  const SizedBox(height: 16),
                ],

                // ── Album art ───────────────────────────────────────
                Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
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
                )
                    .animate()
                    .fadeIn(duration: 380.ms)
                    .scale(begin: const Offset(0.96, 0.96)),

                const SizedBox(height: 28),

                // ── Song title + artist ─────────────────────────────
                Text(
                  track?.title ?? 'No track playing',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  track?.artist ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 24),

                // ── Progress bar ────────────────────────────────────
                _ProgressBar(
                  duration: duration,
                  currentPosition: currentPosition,
                  palette: palette,
                ),

                const SizedBox(height: 20),

                // ── Controls row ────────────────────────────────────
                _ControlsRow(
                  isPlaying: isPlaying,
                  isShuffleOn: _isShuffleOn,
                  volume: _volume,
                  palette: palette,
                  onShuffle: () => setState(() => _isShuffleOn = !_isShuffleOn),
                  onPlayPause: () => context
                      .read<PlayerBloc>()
                      .add(const PlayerPlayPauseToggled()),
                  onSkip: () => context
                      .read<PlayerBloc>()
                      .add(const PlayerSkipRequested()),
                  onVolumeChanged: (v) => setState(() => _volume = v),
                ),

                const SizedBox(height: 24),

                // ── Override Mood CTA ───────────────────────────────
                if (playerState.activeSpaceId != null)
                  _OverrideMoodCTA(
                    spaceId: playerState.activeSpaceId!,
                    currentMood: mood,
                    palette: palette,
                  ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.12),

                const SizedBox(height: 100), // breathing space
              ],
            ),
          ),
        ),

        // ── Bottom bar: "Playing from…" + Queue ────────────────────────
        _BottomBar(
          deviceLabel: deviceLabel,
          isPlayback: isPlayback,
          palette: palette,
          onQueue: () => _showQueueSheet(context, playerState, palette),
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

  // ── Song Options Bottom Sheet ──────────────────────────────────────────────
  void _showSongOptionsSheet(
      BuildContext ctx, ps.PlayerState state, _NPPalette palette) {
    final track = state.currentTrack;
    showModalBottomSheet(
      context: ctx,
      useRootNavigator: true,
      backgroundColor: palette.isDark ? palette.card : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
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
              // Song info header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: track?.albumArt != null
                            ? Image.network(track!.albumArt!, fit: BoxFit.cover)
                            : Container(
                                color: palette.overlay,
                                child: Icon(Icons.music_note,
                                    color: palette.textMuted, size: 24),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track?.title ?? 'No track',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: palette.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            track?.artist ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                color: palette.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Divider(color: palette.border, height: 1),
              _SheetOption(
                  icon: LucideIcons.listMusic,
                  label: 'Go to playlist',
                  palette: palette,
                  onTap: () => Navigator.pop(ctx)),
              _SheetOption(
                  icon: LucideIcons.listPlus,
                  label: 'Add to playlist',
                  palette: palette,
                  onTap: () => Navigator.pop(ctx)),
              _SheetOption(
                  icon: LucideIcons.ban,
                  label: 'Block song',
                  palette: palette,
                  onTap: () => Navigator.pop(ctx)),
              _SheetOption(
                  icon: LucideIcons.listEnd,
                  label: 'Add to queue',
                  palette: palette,
                  onTap: () => Navigator.pop(ctx)),
              _SheetOption(
                  icon: LucideIcons.disc,
                  label: 'Go to album',
                  palette: palette,
                  onTap: () => Navigator.pop(ctx)),
              _SheetOption(
                  icon: LucideIcons.mic2,
                  label: 'Go to artist',
                  palette: palette,
                  onTap: () => Navigator.pop(ctx)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Queue Bottom Sheet ─────────────────────────────────────────────────────
  void _showQueueSheet(
      BuildContext ctx, ps.PlayerState state, _NPPalette palette) {
    final track = state.currentTrack;
    // Mock upcoming tracks for demo
    final upNext = [
      {'title': 'Maybe This Time', 'artist': 'Empress Of'},
      {'title': 'One in a Million', 'artist': 'Bebe Rexha, David Guetta'},
      {'title': 'Kings & Queens', 'artist': 'Ava Max'},
      {'title': 'Kids Again', 'artist': 'Sam Smith'},
    ];

    showModalBottomSheet(
      context: ctx,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: palette.isDark ? palette.card : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        builder: (_, controller) => SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Queue',
                        style: GoogleFonts.poppins(
                          color: palette.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        )),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Clear',
                          style: GoogleFonts.inter(
                            color: palette.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ],
                ),
              ),
              // Current track
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _QueueTrackTile(
                  title: track?.title ?? 'No track',
                  artist: track?.artist ?? '',
                  artUrl: track?.albumArt,
                  isPlaying: true,
                  palette: palette,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('Up next',
                    style: GoogleFonts.poppins(
                      color: palette.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    )),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: upNext.length,
                  itemBuilder: (_, i) => _QueueTrackTile(
                    title: upNext[i]['title']!,
                    artist: upNext[i]['artist']!,
                    artUrl: null,
                    isPlaying: false,
                    palette: palette,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ═════════════════════════════════════════════════════════════════════════════

// ── Top Bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.spaceName,
    required this.playlistName,
    required this.palette,
    required this.canSwap,
    required this.onMinimize,
    required this.onMenu,
    this.onTitleTap,
  });
  final String spaceName, playlistName;
  final _NPPalette palette;
  final bool canSwap;
  final VoidCallback onMinimize, onMenu;
  final VoidCallback? onTitleTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(LucideIcons.chevronDown,
                color: palette.textMuted, size: 26),
            onPressed: onMinimize,
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTitleTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          spaceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: palette.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (canSwap) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.expand_more,
                            color: palette.textMuted, size: 18),
                      ],
                    ],
                  ),
                  Text(
                    playlistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: palette.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.moreVertical,
                color: palette.textMuted, size: 22),
            onPressed: onMenu,
          ),
        ],
      ),
    );
  }
}

// ── Progress Bar ─────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  const _ProgressBar(
      {required this.duration,
      required this.currentPosition,
      required this.palette});
  final int duration, currentPosition;
  final _NPPalette palette;

  String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: palette.textPrimary,
            inactiveTrackColor: palette.textMuted.withOpacity(0.25),
            thumbColor: palette.textPrimary,
            overlayColor: palette.textPrimary.withOpacity(0.15),
          ),
          child: Slider(
            value: duration > 0
                ? currentPosition.clamp(0, duration).toDouble()
                : 0,
            min: 0,
            max: duration > 0 ? duration.toDouble() : 1,
            onChanged: (_) {},
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(currentPosition),
                  style: GoogleFonts.inter(
                      color: palette.textMuted, fontSize: 12)),
              Text(
                  duration > 0
                      ? '-${_fmt(duration - currentPosition)}'
                      : '--:--',
                  style: GoogleFonts.inter(
                      color: palette.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Controls Row ─────────────────────────────────────────────────────────────
class _ControlsRow extends StatelessWidget {
  const _ControlsRow({
    required this.isPlaying,
    required this.isShuffleOn,
    required this.volume,
    required this.palette,
    required this.onShuffle,
    required this.onPlayPause,
    required this.onSkip,
    required this.onVolumeChanged,
  });
  final bool isPlaying, isShuffleOn;
  final double volume;
  final _NPPalette palette;
  final VoidCallback onShuffle, onPlayPause, onSkip;
  final ValueChanged<double> onVolumeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Shuffle
            IconButton(
              icon: Icon(
                LucideIcons.shuffle,
                color: isShuffleOn ? palette.accent : palette.textMuted,
                size: 22,
              ),
              onPressed: onShuffle,
            ),
            // Play/Pause (large)
            GestureDetector(
              onTap: onPlayPause,
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.textPrimary,
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: palette.bg,
                  size: 38,
                ),
              ),
            ),
            // Skip
            IconButton(
              icon: Icon(LucideIcons.skipForward,
                  color: palette.textPrimary, size: 28),
              onPressed: onSkip,
            ),
            // Volume
            IconButton(
              icon: Icon(
                volume > 0 ? LucideIcons.volume2 : LucideIcons.volumeX,
                color: palette.textMuted,
                size: 22,
              ),
              onPressed: () {
                // Toggle mute
                onVolumeChanged(volume > 0 ? 0 : 0.6);
              },
            ),
          ],
        ),
      ],
    );
  }
}

// ── Bottom Bar ───────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.deviceLabel,
    required this.isPlayback,
    required this.palette,
    required this.onQueue,
  });
  final String deviceLabel;
  final bool isPlayback;
  final _NPPalette palette;
  final VoidCallback onQueue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            isPlayback ? LucideIcons.speaker : LucideIcons.smartphone,
            color: palette.accent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Playing from',
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  deviceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.listMusic,
                color: palette.textPrimary, size: 22),
            onPressed: onQueue,
          ),
        ],
      ),
    );
  }
}

// ── Sheet Option ─────────────────────────────────────────────────────────────
class _SheetOption extends StatelessWidget {
  const _SheetOption(
      {required this.icon,
      required this.label,
      required this.palette,
      required this.onTap});
  final IconData icon;
  final String label;
  final _NPPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: palette.textPrimary, size: 20),
            const SizedBox(width: 16),
            Text(label,
                style: GoogleFonts.inter(
                  color: palette.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Queue Track Tile ─────────────────────────────────────────────────────────
class _QueueTrackTile extends StatelessWidget {
  const _QueueTrackTile({
    required this.title,
    required this.artist,
    this.artUrl,
    required this.isPlaying,
    required this.palette,
  });
  final String title, artist;
  final String? artUrl;
  final bool isPlaying;
  final _NPPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: artUrl != null
                  ? Image.network(artUrl!, fit: BoxFit.cover)
                  : Container(
                      color: palette.overlay,
                      child: Icon(Icons.music_note,
                          color: palette.textMuted, size: 22),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: isPlaying ? palette.accent : palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      GoogleFonts.inter(color: palette.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Sensor Dashboard (kept from original)
// ═════════════════════════════════════════════════════════════════════════════
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
          isAlert: false),
      _SensorCard(
          icon: LucideIcons.volume2,
          label: 'Noise',
          value: sensorData != null
              ? '${sensorData!.noiseLevel.toStringAsFixed(0)} dB'
              : '--',
          badge: _noiseBadge(sensorData?.noiseLevel),
          palette: palette,
          isAlert: _noiseBadge(sensorData?.noiseLevel) == 'Loud'),
      _SensorCard(
          icon: LucideIcons.users,
          label: 'Crowd',
          value: sensorData != null ? _crowdEstimate(sensorData!) : 'N/A',
          badge: 'Live',
          palette: palette,
          isAlert: false),
      _SensorCard(
          icon: LucideIcons.cloudRain,
          label: 'Humidity',
          value: sensorData != null
              ? '${sensorData!.humidity.toStringAsFixed(0)}%'
              : '--',
          badge: _humidityBadge(sensorData?.humidity),
          palette: palette,
          isAlert: false),
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
  const _SensorCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.badge,
      required this.palette,
      required this.isAlert});
  final IconData icon;
  final String label, value, badge;
  final _NPPalette palette;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    final accentColor =
        isAlert ? Theme.of(context).colorScheme.error : palette.accent;
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: accentColor, size: 18)),
          const Spacer(),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: palette.overlay,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border)),
              child: Text(badge,
                  style: GoogleFonts.inter(
                      color: palette.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600))),
        ]),
        const Spacer(),
        Text(value,
            style: GoogleFonts.poppins(
                color: palette.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Override Mood CTA (kept from original)
// ═════════════════════════════════════════════════════════════════════════════
class _OverrideMoodCTA extends StatelessWidget {
  const _OverrideMoodCTA(
      {required this.spaceId,
      required this.currentMood,
      required this.palette});
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
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Override Mood',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
              currentMood != null
                  ? 'Current: ${currentMood!.toUpperCase()}'
                  : 'Set a new atmosphere',
              style:
                  GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        const Icon(LucideIcons.slidersHorizontal),
      ]),
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
                              borderRadius: BorderRadius.circular(20)))),
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
                          .map((m) => ChoiceChip(
                                label: Text(m.toUpperCase(),
                                    style: GoogleFonts.inter(
                                        color: mood == m
                                            ? palette.textOnAccent
                                            : palette.textPrimary,
                                        fontWeight: FontWeight.w700)),
                                selected: mood == m,
                                onSelected: (_) =>
                                    setModalState(() => mood = m),
                                backgroundColor: palette.overlay,
                                selectedColor: palette.accent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(color: palette.border)),
                              ))
                          .toList()),
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
                          setModalState(() => durationMin = v.round())),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                foregroundColor: palette.textMuted,
                                side: BorderSide(color: palette.border),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14))),
                            onPressed: () => Navigator.pop(sheetCtx),
                            child: const Text('Cancel'))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: palette.accent,
                                foregroundColor: palette.textOnAccent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14)),
                            onPressed: () {
                              context.read<MusicControlBloc>().add(
                                  OverrideMoodRequested(
                                      spaceId: spaceId,
                                      moodId: mood,
                                      duration: durationMin));
                              Navigator.pop(sheetCtx);
                            },
                            child: const Text('Apply',
                                style:
                                    TextStyle(fontWeight: FontWeight.w700)))),
                  ]),
                ]),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Space Swap Sheet (kept from original)
// ═════════════════════════════════════════════════════════════════════════════
class _SpaceSwapSheet extends StatelessWidget {
  const _SpaceSwapSheet({required this.playerState, required this.palette});
  final ps.PlayerState playerState;
  final _NPPalette palette;

  void _switchSpace(BuildContext context, SpaceInfo space) {
    context
        .read<SpaceMonitoringBloc>()
        .add(StartMonitoring(storeId: space.storeId, spaceId: space.id));
    context
        .read<MusicControlBloc>()
        .add(StartMusicMonitoring(storeId: space.storeId, spaceId: space.id));
    context.read<PlayerBloc>().add(PlayerContextUpdated(
          storeId: space.storeId,
          spaceId: space.id,
          spaceName: space.name,
          availableSpaces: playerState.availableSpaces,
        ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final spaces = playerState.availableSpaces;
    return Container(
      decoration: BoxDecoration(
          color: palette.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 32 + MediaQuery.of(context).viewInsets.bottom),
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
                        borderRadius: BorderRadius.circular(20)))),
            const SizedBox(height: 20),
            Row(children: [
              Icon(Icons.spatial_audio_outlined,
                  color: palette.accent, size: 22),
              const SizedBox(width: 10),
              Text('Chọn không gian',
                  style: GoogleFonts.poppins(
                      color: palette.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 4),
            Text('Đổi space sẽ cập nhật cảm biến, nhạc và trạng thái Hub.',
                style:
                    GoogleFonts.inter(color: palette.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            Divider(color: palette.border, height: 1),
            if (spaces.isEmpty)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                      child: Text('Không có không gian nào.',
                          style: GoogleFonts.inter(color: palette.textMuted))))
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
                      child: Icon(Icons.spatial_audio_outlined,
                          color: isActive ? palette.accent : palette.textMuted,
                          size: 20),
                    ),
                    title: Text(space.name,
                        style: GoogleFonts.inter(
                            color: palette.textPrimary,
                            fontSize: 14,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500)),
                    subtitle: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: space.isOnline
                                  ? Colors.green
                                  : Colors.orange)),
                      const SizedBox(width: 4),
                      Text(space.isOnline ? 'Online' : 'Offline',
                          style: GoogleFonts.inter(
                              color: palette.textMuted, fontSize: 11)),
                    ]),
                    trailing: isActive
                        ? Icon(Icons.check_circle_rounded,
                            color: palette.accent, size: 22)
                        : Icon(Icons.chevron_right,
                            color: palette.textMuted, size: 22),
                    onTap: isActive ? null : () => _switchSpace(context, space),
                  );
                },
              ),
          ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Palette (kept from original)
// ═════════════════════════════════════════════════════════════════════════════
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
          shadow: AppColors.shadowDark);
    }
    return const _NPPalette(
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
        shadow: AppColors.shadow);
  }

  final bool isDark;
  final Color bg, card, overlay, border, textPrimary, textMuted;
  final Color accent, accentAlt, textOnAccent, shadow;
}
