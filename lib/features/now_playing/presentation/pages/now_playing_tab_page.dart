import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/entity_status_enum.dart';
import '../../../../core/enums/playback_command_enum.dart';
import '../../../../core/enums/space_type_enum.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/player/player_event.dart';
import '../../../../core/player/player_state.dart' as ps;
import '../../../../core/player/space_info.dart';
import '../../../../features/cams/data/models/override_response_model.dart';
import '../../../../features/cams/presentation/bloc/cams_playback_bloc.dart';
import '../../../../features/cams/presentation/bloc/cams_playback_event.dart';
import '../../../../features/cams/presentation/bloc/cams_playback_state.dart';
import '../../../../features/moods/domain/entities/mood.dart';
import '../../../../features/space_control/domain/entities/space.dart';
import '../../../../features/space_control/domain/entities/sensor_data.dart';
import '../../../../features/space_control/domain/entities/track.dart';
import '../../../../features/space_control/presentation/bloc/music_control_bloc.dart';
import '../../../../features/space_control/presentation/bloc/music_control_event.dart';
import '../../../../features/space_control/presentation/bloc/space_monitoring_bloc.dart';
import '../../../../features/space_control/presentation/bloc/space_monitoring_event.dart';
import '../../../../features/space_control/presentation/bloc/space_monitoring_state.dart';
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

    return MultiBlocListener(
      listeners: [
        BlocListener<PlayerBloc, ps.PlayerState>(
          listenWhen: (previous, current) {
            if (!isPlayback) return false;
            final hasHlsStream =
                current.isHlsMode && (current.hlsUrl?.isNotEmpty ?? false);
            if (!hasHlsStream) return false;
            final bucketChanged = (previous.currentPosition ~/ 5) !=
                (current.currentPosition ~/ 5);
            final playingChanged = previous.isPlaying != current.isPlaying;
            final streamChanged = previous.hlsUrl != current.hlsUrl;
            return bucketChanged || playingChanged || streamChanged;
          },
          listener: (context, playerState) {
            final camsBloc = context.read<CamsPlaybackBloc>();
            final camsState = camsBloc.state;
            if (!camsState.isStreaming) return;

            final spaceId = camsState.spaceId ?? playerState.activeSpaceId;
            final hlsUrl = playerState.hlsUrl ?? camsState.hlsUrl;
            if (spaceId == null || hlsUrl == null || hlsUrl.isEmpty) return;

            camsBloc.add(CamsReportPlaybackState(
              spaceId: spaceId,
              isPlaying: playerState.isPlaying,
              positionSeconds: playerState.currentPosition.toDouble(),
              currentHlsUrl: hlsUrl,
            ));
          },
        ),
        BlocListener<CamsPlaybackBloc, CamsPlaybackState>(
          listener: (context, camsState) {
            // Show error snackbar
            if (camsState.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(camsState.errorMessage!),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<PlayerBloc, ps.PlayerState>(
        builder: (context, playerState) {
          return BlocBuilder<SpaceMonitoringBloc, SpaceMonitoringState>(
            builder: (context, spaceState) {
              return BlocBuilder<CamsPlaybackBloc, CamsPlaybackState>(
                builder: (context, camsState) {
                  return Scaffold(
                    backgroundColor: palette.bg,
                    body: SafeArea(
                      child: _buildBody(
                        context,
                        playerState,
                        spaceState,
                        camsState,
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
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ps.PlayerState playerState,
    SpaceMonitoringState spaceState,
    CamsPlaybackState camsState,
    _NPPalette palette,
    bool isPlayback,
  ) {
    final track = playerState.currentTrack;
    // Prefer CAMS mood name, then fallback to track/space
    final mood = camsState.currentMoodName ??
        ((track?.moodTags != null && track!.moodTags.isNotEmpty)
            ? track.moodTags.first
            : spaceState.space?.currentMood);
    final duration = playerState.duration;
    final currentPosition = playerState.currentPosition;
    final isPlaying = playerState.isPlaying;
    final showLocalPreviewBanner = isPlayback && playerState.isLocalPreview;

    final spaceName =
        spaceState.space?.name ?? playerState.activeSpaceName ?? 'No Space';
    final effectiveSpaceId = playerState.activeSpaceId ??
        context.read<SessionCubit>().state.currentSpace?.id;
    // Show CAMS playlist name or mood
    final playlistName = camsState.currentPlaylistName?.toUpperCase() ??
        mood?.toUpperCase() ??
        'MUSIC';

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
            // Pop back to previous screen if possible, otherwise go home
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
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
                if (playerState.playlistName != null &&
                    playerState.playlistName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Playing from: ${playerState.playlistName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: palette.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (showLocalPreviewBanner) ...[
                  const SizedBox(height: 12),
                  _LocalPreviewBanner(palette: palette),
                ],

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
                  hasNext: playerState.hasNext,
                  hasPrevious: playerState.hasPrevious || currentPosition > 3,
                  onShuffle: () => setState(() => _isShuffleOn = !_isShuffleOn),
                  onPlayPause: () {
                    // Send CAMS command + toggle local player
                    if (camsState.isStreaming) {
                      context.read<CamsPlaybackBloc>().add(CamsSendCommand(
                            command: isPlaying
                                ? PlaybackCommandEnum.pause
                                : PlaybackCommandEnum.resume,
                          ));
                    }
                    context
                        .read<PlayerBloc>()
                        .add(const PlayerPlayPauseToggled());
                  },
                  onSkipBack: () {
                    if (camsState.isStreaming) {
                      context
                          .read<CamsPlaybackBloc>()
                          .add(const CamsSendCommand(
                            command: PlaybackCommandEnum.skipPrevious,
                          ));
                    }
                    context
                        .read<PlayerBloc>()
                        .add(const PlayerSkipBackRequested());
                  },
                  onSkip: () {
                    if (camsState.isStreaming) {
                      context
                          .read<CamsPlaybackBloc>()
                          .add(const CamsSendCommand(
                            command: PlaybackCommandEnum.skipNext,
                          ));
                    }
                    context.read<PlayerBloc>().add(const PlayerSkipRequested());
                  },
                  onVolumeChanged: (v) => setState(() => _volume = v),
                ),

                const SizedBox(height: 24),

                // ── Override Mood CTA ───────────────────────────────
                if (effectiveSpaceId != null)
                  _OverrideMoodCTA(
                    spaceId: effectiveSpaceId,
                    currentMood: mood,
                    palette: palette,
                    moods: camsState.moods,
                    hasActiveOverride: camsState.hasActiveOverride,
                    isOverriding: camsState.isOverriding,
                    lastOverrideResponse: camsState.lastOverrideResponse,
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
        builder: (_, controller) => _QueueSheet(
          palette: palette,
          controller: controller,
        ),
      ),
    );
  }
}

class _QueueSheet extends StatefulWidget {
  const _QueueSheet({
    required this.palette,
    required this.controller,
  });

  final _NPPalette palette;
  final ScrollController controller;

  @override
  State<_QueueSheet> createState() => _QueueSheetState();
}

class _QueueSheetState extends State<_QueueSheet> {
  String? _pendingTrackId;

  void _handleQueueTrackTap(
    BuildContext context,
    ps.PlayerState state,
    Track track,
    int queueIndex,
  ) {
    if (_pendingTrackId != null) return;

    setState(() => _pendingTrackId = track.id);

    final camsBloc = context.read<CamsPlaybackBloc>();
    if (camsBloc.state.isStreaming &&
        state.isHlsMode &&
        state.playlistId != null &&
        state.playlistId!.isNotEmpty) {
      camsBloc.add(CamsSendCommand(
        command: PlaybackCommandEnum.skipToTrack,
        targetTrackId: track.id,
      ));
      return;
    }

    if (state.queue.isEmpty) {
      setState(() => _pendingTrackId = null);
      return;
    }

    context.read<PlayerBloc>().add(PlayerPlaylistStarted(
          tracks: state.queue,
          startIndex: queueIndex,
          playlistName: state.playlistName,
          playlistId: state.playlistId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PlayerBloc, ps.PlayerState>(
          listenWhen: (previous, current) =>
              previous.currentTrack?.id != current.currentTrack?.id ||
              previous.currentIndex != current.currentIndex,
          listener: (context, state) {
            final pendingTrackId = _pendingTrackId;
            if (pendingTrackId == null) return;
            if (state.currentTrack?.id != pendingTrackId) return;
            if (!mounted) return;
            Navigator.of(context).pop();
          },
        ),
        BlocListener<CamsPlaybackBloc, CamsPlaybackState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            if (_pendingTrackId == null) return;
            if (state.errorMessage == null || state.errorMessage!.isEmpty) {
              return;
            }
            setState(() => _pendingTrackId = null);
          },
        ),
      ],
      child: BlocBuilder<PlayerBloc, ps.PlayerState>(
        builder: (context, state) {
          final queue = state.queue;
          final resolvedCurrentIndex =
              state.currentIndex >= 0 && state.currentIndex < queue.length
                  ? state.currentIndex
                  : state.currentTrack == null
                      ? -1
                      : queue.indexWhere(
                          (item) => item.id == state.currentTrack!.id,
                        );
          final currentTrack = resolvedCurrentIndex >= 0
              ? queue[resolvedCurrentIndex]
              : state.currentTrack;
          final upNext = resolvedCurrentIndex >= 0 &&
                  resolvedCurrentIndex + 1 < queue.length
              ? queue.sublist(resolvedCurrentIndex + 1)
              : const <Track>[];

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: widget.palette.border,
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
                            color: widget.palette.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          )),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close',
                            style: GoogleFonts.inter(
                              color: widget.palette.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text('Now playing',
                      style: GoogleFonts.inter(
                        color: widget.palette.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _QueueTrackTile(
                    title: currentTrack?.title ?? 'No track',
                    artist: currentTrack?.artist ?? '',
                    artUrl: currentTrack?.albumArt,
                    isPlaying: true,
                    palette: widget.palette,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text('Up next',
                      style: GoogleFonts.poppins(
                        color: widget.palette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      )),
                ),
                Expanded(
                  child: upNext.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              state.queue.isEmpty
                                  ? 'No queue is available for this track yet.'
                                  : 'You have reached the end of the current queue.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: widget.palette.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: widget.controller,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: upNext.length,
                          itemBuilder: (_, i) {
                            final queueIndex = resolvedCurrentIndex + i + 1;
                            final queuedTrack = upNext[i];
                            return _QueueTrackTile(
                              title: queuedTrack.title,
                              artist: queuedTrack.artist,
                              artUrl: queuedTrack.albumArt,
                              isPlaying: false,
                              isPending: _pendingTrackId == queuedTrack.id,
                              palette: widget.palette,
                              onTap: () => _handleQueueTrackTap(
                                context,
                                state,
                                queuedTrack,
                                queueIndex,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ═════════════════════════════════════════════════════════════════════════════

// ── Top Bar ──────────────────────────────────────────────────────────────────
class _LocalPreviewBanner extends StatelessWidget {
  const _LocalPreviewBanner({required this.palette});

  final _NPPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.overlay,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.smartphone,
            color: palette.accent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Local preview only. Manager devices and Location sync update only for CAMS playlist streams.',
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Row(
        children: [
          // Minimize button — compact to give more room to title
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(LucideIcons.chevronDown,
                  color: palette.textMuted, size: 26),
              onPressed: onMinimize,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTitleTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          spaceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
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
                    textAlign: TextAlign.center,
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
          // Menu button — compact
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(LucideIcons.moreVertical,
                  color: palette.textMuted, size: 22),
              onPressed: onMenu,
            ),
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
            onChanged: (value) {
              context.read<PlayerBloc>().add(
                    PlayerSeekRequested(positionSeconds: value.toInt()),
                  );
            },
            onChangeEnd: (value) {
              final camsState = context.read<CamsPlaybackBloc>().state;
              if (!camsState.isStreaming) return;
              context.read<CamsPlaybackBloc>().add(
                    CamsSendCommand(
                      command: PlaybackCommandEnum.seek,
                      seekPositionSeconds: value.toDouble(),
                    ),
                  );
            },
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
    required this.hasNext,
    required this.hasPrevious,
    required this.onShuffle,
    required this.onPlayPause,
    required this.onSkipBack,
    required this.onSkip,
    required this.onVolumeChanged,
  });
  final bool isPlaying, isShuffleOn;
  final bool hasNext, hasPrevious;
  final double volume;
  final _NPPalette palette;
  final VoidCallback onShuffle, onPlayPause, onSkipBack, onSkip;
  final ValueChanged<double> onVolumeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Shuffle
        _ControlButton(
          icon: LucideIcons.shuffle,
          color: isShuffleOn ? palette.accent : palette.textMuted,
          size: 22,
          onTap: onShuffle,
        ),
        const SizedBox(width: 20),
        // Skip Previous
        _ControlButton(
          icon: LucideIcons.skipBack,
          color: hasPrevious
              ? palette.textPrimary
              : palette.textMuted.withOpacity(0.4),
          size: 26,
          onTap: onSkipBack,
        ),
        const SizedBox(width: 16),
        // Play/Pause (large center button)
        GestureDetector(
          onTap: onPlayPause,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.textPrimary,
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: palette.bg,
              size: 36,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Skip Next
        _ControlButton(
          icon: LucideIcons.skipForward,
          color: hasNext
              ? palette.textPrimary
              : palette.textMuted.withOpacity(0.4),
          size: 26,
          onTap: onSkip,
        ),
        const SizedBox(width: 20),
        // Volume
        _ControlButton(
          icon: volume > 0 ? LucideIcons.volume2 : LucideIcons.volumeX,
          color: palette.textMuted,
          size: 22,
          onTap: () => onVolumeChanged(volume > 0 ? 0 : 0.6),
        ),
      ],
    );
  }
}

/// Uniform-sized control button to keep the row balanced.
class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(icon, color: color, size: size),
        onPressed: onTap,
      ),
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
    this.isPending = false,
    required this.palette,
    this.onTap,
  });
  final String title, artist;
  final String? artUrl;
  final bool isPlaying;
  final bool isPending;
  final _NPPalette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isPlaying
            ? palette.accent.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPlaying
              ? palette.accent.withValues(alpha: 0.24)
              : Colors.transparent,
        ),
      ),
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
          if (isPending)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: palette.accent,
              ),
            )
          else if (isPlaying)
            Icon(
              LucideIcons.volume2,
              size: 18,
              color: palette.accent,
            ),
        ],
      ),
    );

    if (onTap == null) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: child,
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

// ============================================================================
// Manual / Auto Override panel (same behavior as Home)
// ============================================================================
class _OverrideMoodCTA extends StatefulWidget {
  const _OverrideMoodCTA({
    required this.spaceId,
    required this.currentMood,
    required this.palette,
    required this.moods,
    required this.hasActiveOverride,
    required this.isOverriding,
    this.lastOverrideResponse,
  });

  final String spaceId;
  final String? currentMood;
  final _NPPalette palette;
  final List<Mood> moods;
  final bool hasActiveOverride;
  final bool isOverriding;
  final OverrideResponse? lastOverrideResponse;

  @override
  State<_OverrideMoodCTA> createState() => _OverrideMoodCTAState();
}

class _OverrideMoodCTAState extends State<_OverrideMoodCTA> {
  bool _manualSelectionOpen = false;

  bool get _isManualMode => widget.hasActiveOverride || _manualSelectionOpen;

  @override
  void initState() {
    super.initState();
    _manualSelectionOpen = widget.hasActiveOverride;
  }

  @override
  void didUpdateWidget(covariant _OverrideMoodCTA oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasActiveOverride && !_manualSelectionOpen) {
      _manualSelectionOpen = true;
    } else if (!widget.hasActiveOverride && oldWidget.hasActiveOverride) {
      _manualSelectionOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingTranscode = widget.lastOverrideResponse != null &&
        !widget.lastOverrideResponse!.isStreamReady;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: widget.palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isManualMode ? 'Manual Mode' : 'Auto Mode',
                      style: GoogleFonts.poppins(
                        color: widget.palette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isManualMode
                          ? 'Select mood to override CAMS playback'
                          : 'CAMS is auto-adjusting playlist and mood',
                      style: GoogleFonts.inter(
                        color: widget.palette.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: widget.isOverriding ? null : () => _onToggle(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 52,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: _isManualMode
                        ? widget.palette.accent.withOpacity(0.30)
                        : widget.palette.overlay,
                    border: Border.all(color: widget.palette.border),
                  ),
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        alignment: _isManualMode
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 22,
                          height: 22,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isManualMode
                                ? widget.palette.accent
                                : widget.palette.textMuted.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (widget.currentMood != null) ...[
            const SizedBox(height: 10),
            Text(
              'Current mood: ${widget.currentMood!.toUpperCase()}',
              style: GoogleFonts.inter(
                color: widget.palette.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (widget.isOverriding || pendingTranscode) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (widget.isOverriding)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    LucideIcons.loader,
                    size: 14,
                    color: widget.palette.textMuted,
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isOverriding
                        ? 'Applying override...'
                        : 'Accepted (202). Stream starts after transcode finishes.',
                    style: GoogleFonts.inter(
                      color: widget.palette.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_isManualMode) ...[
            const SizedBox(height: 12),
            if (widget.moods.isEmpty)
              Text(
                'No moods available.',
                style: GoogleFonts.inter(
                  color: widget.palette.textMuted,
                  fontSize: 12,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.moods.map((mood) {
                  final selected = widget.currentMood != null &&
                      widget.currentMood!.toLowerCase() ==
                          mood.name.toLowerCase();
                  return ChoiceChip(
                    label: Text(
                      mood.name.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: selected
                            ? widget.palette.textOnAccent
                            : widget.palette.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    selected: selected,
                    selectedColor: widget.palette.accent,
                    backgroundColor: widget.palette.overlay,
                    side: BorderSide(
                      color: selected
                          ? widget.palette.accent
                          : widget.palette.border,
                    ),
                    onSelected: widget.isOverriding
                        ? null
                        : (_) {
                            context
                                .read<CamsPlaybackBloc>()
                                .add(CamsOverrideMood(moodId: mood.id));
                          },
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }

  void _onToggle(BuildContext context) {
    if (_isManualMode) {
      if (widget.hasActiveOverride) {
        context.read<CamsPlaybackBloc>().add(const CamsCancelOverride());
      } else {
        setState(() => _manualSelectionOpen = false);
      }
      return;
    }

    setState(() => _manualSelectionOpen = true);
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
    context.read<SessionCubit>().changeSpace(
          Space(
            id: space.id,
            name: space.name,
            storeId: space.storeId,
            type: SpaceTypeEnum.hall,
            status: space.isOnline
                ? EntityStatusEnum.active
                : EntityStatusEnum.inactive,
            currentMood: space.currentMood,
          ),
        );
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
              Text('Select Space',
                  style: GoogleFonts.poppins(
                      color: palette.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 4),
            Text('Switching space will update sensors, music and Hub status.',
                style:
                    GoogleFonts.inter(color: palette.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            Divider(color: palette.border, height: 1),
            if (spaces.isEmpty)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                      child: Text('No spaces available.',
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
