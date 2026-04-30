import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/enums/entity_status_enum.dart';
import '../../../../core/enums/playback_command_enum.dart';
import '../../../../core/enums/queue_end_behavior_enum.dart';
import '../../../../core/enums/space_type_enum.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/player/player_event.dart';
import '../../../../core/player/player_state.dart' as ps;
import '../../../../core/player/space_info.dart';
import '../../../../core/presentation/app_feedback.dart';
import '../../../../core/presentation/playback_mood_label.dart';
import '../../../../core/theme/cams_theme_tokens.dart';
import '../../../../core/widgets/app_feedback_presenter.dart';
import '../../../../core/widgets/cams_skeleton.dart';
import '../../../../features/cams/data/models/override_response_model.dart';
import '../../../../features/cams/domain/entities/space_playback_state.dart';
import '../../../../features/cams/presentation/bloc/cams_playback_bloc.dart';
import '../../../../features/cams/presentation/bloc/cams_playback_event.dart';
import '../../../../features/cams/presentation/bloc/cams_playback_state.dart';
import '../../../../features/moods/domain/entities/mood.dart';
import '../models/queue_sheet_view_data.dart';
import '../widgets/queue_management_sheets.dart';
import '../../../../features/space_control/domain/entities/space.dart';
import '../../../../features/space_control/presentation/bloc/space_monitoring_bloc.dart';
import '../../../../features/space_control/presentation/bloc/space_monitoring_event.dart';
import '../../../../features/space_control/presentation/bloc/space_monitoring_state.dart';
import '../../../../core/session/session_cubit.dart';

/// Redesigned "Now Playing" tab â€” Spotify-style full-screen player.
class NowPlayingTabPage extends StatefulWidget {
  const NowPlayingTabPage({
    super.key,
    this.embedInParentScaffold = false,
    this.showTopBar = true,
  });

  final bool embedInParentScaffold;
  final bool showTopBar;

  @override
  State<NowPlayingTabPage> createState() => _NowPlayingTabPageState();
}

class _NowPlayingTabPageState extends State<NowPlayingTabPage>
    with SingleTickerProviderStateMixin {
  static const int _defaultRemoteVolumePercent = 60;
  static const int _minimumRemoteVolumePercent = 30;

  double _volume = 0.6;
  bool _isShuffleOn = false;
  late final AnimationController _discRotationController;

  @override
  void initState() {
    super.initState();
    _discRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
  }

  @override
  void dispose() {
    _discRotationController.dispose();
    super.dispose();
  }

  void _syncDiscRotation(bool shouldSpin) {
    if (shouldSpin) {
      if (!_discRotationController.isAnimating) {
        _discRotationController.repeat();
      }
      return;
    }

    if (_discRotationController.isAnimating) {
      _discRotationController.stop(canceled: false);
    }
  }

  void _dispatchRemoteSkipBack(BuildContext context) {
    context.read<CamsPlaybackBloc>().add(const CamsPreviousTapped());
  }

  bool _isCamsPlaybackLoading(CamsPlaybackState camsState) {
    return camsState.status == CamsStatus.initial ||
        camsState.status == CamsStatus.loading;
  }

  bool _hasRemoteNext(
    CamsPlaybackState camsState,
    ps.PlayerState playerState,
  ) {
    final playback = camsState.playbackState;
    final queueItems = playback?.spaceQueueItems ?? const [];
    if (queueItems.isEmpty) return false;

    final sortedItems = [...queueItems]
      ..sort((a, b) => a.position.compareTo(b.position));

    var currentIndex = -1;
    final currentQueueItemId = playback?.currentQueueItemId;
    if (currentQueueItemId != null && currentQueueItemId.isNotEmpty) {
      currentIndex = sortedItems
          .indexWhere((item) => item.queueItemId == currentQueueItemId);
    }

    if (currentIndex < 0) {
      currentIndex = sortedItems.indexWhere((item) => item.queueStatus == 1);
    }

    if (currentIndex < 0 &&
        playerState.currentTrackId != null &&
        playerState.currentTrackId!.isNotEmpty) {
      currentIndex = sortedItems
          .indexWhere((item) => item.trackId == playerState.currentTrackId);
    }

    return currentIndex >= 0 && currentIndex < sortedItems.length - 1;
  }

  int _normalizeAudibleVolumePercent(int requestedVolumePercent) {
    final boundedVolume = requestedVolumePercent.clamp(0, 100).toInt();
    if (boundedVolume <= 0) return 0;
    if (boundedVolume < _minimumRemoteVolumePercent) {
      return _minimumRemoteVolumePercent;
    }
    return boundedVolume;
  }

  int _preferredAudibleVolumePercent(BuildContext context) {
    final playback = context.read<CamsPlaybackBloc>().state.playbackState;
    final playbackVolume = playback?.volumePercent;
    if (playbackVolume != null && playbackVolume > 0) {
      return _normalizeAudibleVolumePercent(playbackVolume);
    }

    final localVolume = (_volume * 100).round().clamp(0, 100).toInt();
    if (localVolume > 0) {
      return _normalizeAudibleVolumePercent(localVolume);
    }

    return _defaultRemoteVolumePercent;
  }

  void _previewLocalVolume(
    BuildContext context, {
    required int volumePercent,
    required bool isMuted,
  }) {
    context.read<PlayerBloc>().add(
          PlayerAudioSettingsApplied(
            volumePercent: volumePercent.clamp(0, 100).toInt(),
            isMuted: isMuted,
          ),
        );
  }

  void _dispatchAudioStatePatch(
    BuildContext context, {
    int? volumePercent,
    bool? isMuted,
    int? queueEndBehavior,
    int? localVolumePercent,
    bool? localIsMuted,
  }) {
    context.read<CamsPlaybackBloc>().add(
          CamsUpdateAudioState(
            volumePercent: volumePercent,
            isMuted: isMuted,
            queueEndBehavior: queueEndBehavior,
          ),
        );

    if (volumePercent != null || isMuted != null) {
      context.read<PlayerBloc>().add(
            PlayerAudioSettingsApplied(
              volumePercent: (localVolumePercent ?? volumePercent ?? 100)
                  .clamp(0, 100)
                  .toInt(),
              isMuted: localIsMuted ?? isMuted ?? false,
            ),
          );
    }
  }

  void _applyVolumeIntent(
    BuildContext context, {
    required int requestedVolumePercent,
  }) {
    final boundedVolume = requestedVolumePercent.clamp(0, 100).toInt();
    if (boundedVolume <= 0) {
      _applyMuteIntent(context, isMuted: true);
      return;
    }

    final normalizedVolume = _normalizeAudibleVolumePercent(boundedVolume);
    setState(() {
      _volume = normalizedVolume / 100.0;
    });
    _dispatchAudioStatePatch(
      context,
      volumePercent: normalizedVolume,
      isMuted: false,
      localVolumePercent: normalizedVolume,
      localIsMuted: false,
    );
  }

  void _applyMuteIntent(
    BuildContext context, {
    required bool isMuted,
  }) {
    if (isMuted) {
      setState(() {
        _volume = 0;
      });
      _dispatchAudioStatePatch(
        context,
        isMuted: true,
        localVolumePercent: 0,
        localIsMuted: true,
      );
      return;
    }

    final restoredVolume = _preferredAudibleVolumePercent(context);
    setState(() {
      _volume = restoredVolume / 100.0;
    });
    _dispatchAudioStatePatch(
      context,
      volumePercent: restoredVolume,
      isMuted: false,
      localVolumePercent: restoredVolume,
      localIsMuted: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _NPPalette.fromContext(context);
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
            if (!camsState.isStreaming && !playerState.isSyncedCamsPlayback) {
              return;
            }

            final spaceId = camsState.spaceId ?? playerState.activeSpaceId;
            final hlsUrl = playerState.hlsUrl ?? camsState.hlsUrl;
            if (spaceId == null || hlsUrl == null || hlsUrl.isEmpty) return;

            camsBloc.add(CamsReportPlaybackState(
              spaceId: spaceId,
              isPlaying: playerState.isPlaying,
              positionSeconds: playerState.currentPositionPrecise,
              currentHlsUrl: hlsUrl,
            ));
          },
        ),
        BlocListener<CamsPlaybackBloc, CamsPlaybackState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage &&
              current.errorMessage != null,
          listener: (context, camsState) {
            if (camsState.errorMessage != null) {
              AppFeedbackPresenter.show(
                context,
                AppFeedback.error(camsState.errorMessage!),
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
                    body: widget.embedInParentScaffold
                        ? _buildBody(
                            context,
                            playerState,
                            spaceState,
                            camsState,
                            palette,
                            isPlayback,
                          )
                        : SafeArea(
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
    final isManualOverride = camsState.playbackState?.isManualOverride == true;
    final fallbackTrackMood =
        (track?.moodTags != null && track!.moodTags.isNotEmpty)
            ? track.moodTags.first
            : null;
    final mood = buildPlaybackMoodLabel(
      isManualOverride: isManualOverride,
      primaryMoodName: camsState.currentMoodName,
      fallbackMoodNames: [
        fallbackTrackMood,
        spaceState.space?.currentMood,
      ],
    );
    final duration = playerState.duration;
    final displayPosition = playerState.displayPosition;
    final displayPositionPrecise = playerState.displayPositionPrecise;
    final isPlaying = playerState.isPlaying;
    final useRemoteControls =
        playerState.isSyncedCamsPlayback || camsState.isStreaming;
    final hasPlayableTrack = track != null;
    final isWaitingForRemoteState =
        useRemoteControls && _isCamsPlaybackLoading(camsState);
    final playbackActionsEnabled = hasPlayableTrack && !isWaitingForRemoteState;
    _syncDiscRotation(isPlaying && playbackActionsEnabled);
    final hasNextForControls = useRemoteControls
        ? playbackActionsEnabled &&
            (_hasRemoteNext(camsState, playerState) || playerState.hasNext)
        : playbackActionsEnabled && playerState.hasNext;
    final syncedVolumePercent =
        camsState.playbackState?.volumePercent.clamp(0, 100).toInt();
    final syncedIsMuted = camsState.playbackState?.isMuted;
    final resolvedVolumePercent =
        syncedVolumePercent ?? (_volume * 100).round().clamp(0, 100);
    final resolvedIsMuted = syncedIsMuted ?? resolvedVolumePercent == 0;
    final effectiveVolume =
        resolvedIsMuted ? 0.0 : (resolvedVolumePercent / 100.0);
    final showLocalPreviewBanner = isPlayback && playerState.isLocalPreview;
    final playbackState = camsState.playbackState;
    final showAiInsightButton =
        playbackState?.explainability?.hasAnyData == true ||
            playbackState?.isManualOverride == true;

    if (isPlayback && _isCamsPlaybackLoading(camsState) && !hasPlayableTrack) {
      return _NowPlayingSkeleton(
        palette: palette,
        showTopBar: widget.showTopBar,
      );
    }

    final spaceName =
        spaceState.space?.name ?? playerState.activeSpaceName ?? 'No Space';
    final effectiveSpaceId = playerState.activeSpaceId ??
        context.read<SessionCubit>().state.currentSpace?.id;
    // Show CAMS playback label (track-first), then fallback to mood.
    final playbackLabel = camsState.currentPlaybackName?.toUpperCase() ??
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
        // â”€â”€ Top bar: â†“  title  â‹® â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (widget.showTopBar)
          _TopBar(
            spaceName: spaceName,
            playlistName: playbackLabel,
            palette: palette,
            canSwap: !isPlayback && playerState.availableSpaces.length > 1,
            onMinimize: () {
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

        // â”€â”€ Scrollable content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // â”€â”€ Album art â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _SpinningAlbumDisc(
                      artUrl: track?.albumArt,
                      palette: palette,
                      rotation: _discRotationController,
                      placeholder: _artPlaceholder(palette),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 380.ms)
                    .scale(begin: const Offset(0.96, 0.96)),

                const SizedBox(height: 28),

                // â”€â”€ Song title + artist â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Text(
                  track?.title ?? 'No track playing',
                  maxLines: 2,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: palette.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (showAiInsightButton && playbackState != null) ...[
                  const SizedBox(height: 12),
                  _AiInsightButton(
                    palette: palette,
                    onTap: () => _showAiExplainabilitySheet(
                      context,
                      palette: palette,
                      playbackState: playbackState,
                      fallbackMoodName: mood,
                    ),
                  ),
                ],
                if (showLocalPreviewBanner) ...[
                  const SizedBox(height: 12),
                  _LocalPreviewBanner(palette: palette),
                ],
                if (camsState.playbackState?.iotStatusLabel != null) ...[
                  const SizedBox(height: 12),
                  _IotStatusNotice(
                    palette: palette,
                    playbackState: camsState.playbackState!,
                  ),
                ],

                const SizedBox(height: 24),

                // â”€â”€ Progress bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _ProgressBar(
                  duration: duration,
                  currentPosition: displayPositionPrecise,
                  remainingDuration: playerState.remainingDuration,
                  seekBaseOffsetSeconds: playerState.currentTrackStartOffset,
                  useAbsoluteSeek: playerState.isSyncedCamsPlayback,
                  useRemoteControls: useRemoteControls,
                  enabled: playbackActionsEnabled,
                  palette: palette,
                ),

                const SizedBox(height: 20),

                // â”€â”€ Controls row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _ControlsRow(
                  isPlaying: isPlaying,
                  isShuffleOn: _isShuffleOn,
                  volume: effectiveVolume,
                  palette: palette,
                  actionsEnabled: playbackActionsEnabled,
                  hasNext: hasNextForControls,
                  hasPrevious: playbackActionsEnabled &&
                      (useRemoteControls
                          ? playerState.hasTrack ||
                              (camsState.playbackState?.hasPlayableHls ?? false)
                          : playerState.hasPrevious || displayPosition > 3),
                  onShuffle: () => setState(() => _isShuffleOn = !_isShuffleOn),
                  onPlayPause: () {
                    if (useRemoteControls) {
                      context.read<CamsPlaybackBloc>().add(CamsSendCommand(
                            command: isPlaying
                                ? PlaybackCommandEnum.pause
                                : PlaybackCommandEnum.resume,
                          ));
                      return;
                    }
                    context
                        .read<PlayerBloc>()
                        .add(const PlayerPlayPauseToggled());
                  },
                  onSkipBack: () {
                    if (useRemoteControls) {
                      _dispatchRemoteSkipBack(context);
                      return;
                    }
                    context
                        .read<PlayerBloc>()
                        .add(const PlayerSkipBackRequested());
                  },
                  onSkip: () {
                    if (useRemoteControls) {
                      context
                          .read<CamsPlaybackBloc>()
                          .add(const CamsSendCommand(
                            command: PlaybackCommandEnum.skipNext,
                          ));
                      return;
                    }
                    context.read<PlayerBloc>().add(const PlayerSkipRequested());
                  },
                  onVolumeChanged: (v) {
                    final normalized = v.clamp(0.0, 1.0);
                    setState(() => _volume = normalized);

                    if (useRemoteControls) {
                      _applyVolumeIntent(
                        context,
                        requestedVolumePercent:
                            (normalized * 100).round().clamp(0, 100).toInt(),
                      );
                      return;
                    }

                    _previewLocalVolume(
                      context,
                      volumePercent:
                          (normalized * 100).round().clamp(0, 100).toInt(),
                      isMuted: normalized == 0,
                    );
                  },
                ),

                const SizedBox(height: 24),

                // â”€â”€ Override Mood CTA â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                if (effectiveSpaceId != null)
                  _OverrideMoodCTA(
                    spaceId: effectiveSpaceId,
                    currentMood: mood,
                    palette: palette,
                    moods: camsState.moods,
                    hasActiveOverride: camsState.hasActiveOverride,
                    isOverriding: camsState.isOverriding,
                    isPreparing: camsState.isPreparing,
                    lastOverrideResponse: camsState.lastOverrideResponse,
                    onOpenOverrideSheet: () => _showOverrideMusicSheet(
                      context,
                      palette,
                      camsState.moods,
                    ),
                  ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.12),

                if (effectiveSpaceId != null &&
                    (camsState.playbackState?.isManualOverride == true ||
                        camsState.playbackState?.isScheduling == true)) ...[
                  const SizedBox(height: 16),
                  _RuntimeStatusPanel(
                    playbackState: camsState.playbackState!,
                    palette: palette,
                    isBusy: camsState.isOverriding,
                    onSchedulingChanged: (enabled) =>
                        context.read<CamsPlaybackBloc>().add(
                              CamsUpdateSchedulingState(isScheduling: enabled),
                            ),
                  ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.12),
                ],

                const SizedBox(height: 100), // breathing space
              ],
            ),
          ),
        ),

        // â”€â”€ Bottom bar: "Playing fromâ€¦" + Queue â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        _BottomBar(
          deviceLabel: deviceLabel,
          isPlayback: isPlayback,
          palette: palette,
          onQueue: () => _showQueueSheet(context, palette),
        ),
      ],
    );
  }

  Widget _artPlaceholder(_NPPalette palette) {
    return Container(
      color: palette.card,
      child: Center(
        child: Icon(Icons.music_note, color: palette.textMuted, size: 64),
      ),
    );
  }

  // â”€â”€ Song Options Bottom Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showAiExplainabilitySheet(
    BuildContext context, {
    required _NPPalette palette,
    required SpacePlaybackState playbackState,
    required String? fallbackMoodName,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: palette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.42,
        maxChildSize: 0.9,
        builder: (_, controller) => _AiExplainabilitySheet(
          palette: palette,
          playbackState: playbackState,
          fallbackMoodName: fallbackMoodName,
          controller: controller,
        ),
      ),
    );
  }

  void _showSongOptionsSheet(
      BuildContext ctx, ps.PlayerState state, _NPPalette palette) {
    final track = state.currentTrack;
    showModalBottomSheet(
      context: ctx,
      useRootNavigator: true,
      backgroundColor: palette.card,
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
                  onTap: () {
                    Navigator.pop(ctx);
                    if (track?.id != null && track!.id.isNotEmpty) {
                      _showAddToQueueSheet(
                        ctx,
                        palette,
                        initialTrackId: track.id,
                      );
                    } else {
                      _showAddToQueueSheet(ctx, palette);
                    }
                  }),
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

  // â”€â”€ Queue Bottom Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showQueueSheet(BuildContext ctx, _NPPalette palette) {
    showModalBottomSheet(
      context: ctx,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: palette.card,
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
          onOpenAddToQueue: () => _showAddToQueueSheet(ctx, palette),
        ),
      ),
    );
  }

  void _showAddToQueueSheet(
    BuildContext ctx,
    _NPPalette palette, {
    String? initialTrackId,
  }) {
    showModalBottomSheet(
      context: ctx,
      useRootNavigator: true,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: palette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.88,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: NowPlayingAddToQueueSheet(
            initialTrackId: initialTrackId,
          ),
        ),
      ),
    );
  }

  void _showOverrideMusicSheet(
    BuildContext ctx,
    _NPPalette palette,
    List<Mood> moods,
  ) {
    showModalBottomSheet(
      context: ctx,
      useRootNavigator: true,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: palette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: NowPlayingOverrideMusicSheet(
            moods: moods,
          ),
        ),
      ),
    );
  }
}

class _NowPlayingSkeleton extends StatelessWidget {
  const _NowPlayingSkeleton({
    required this.palette,
    required this.showTopBar,
  });

  final _NPPalette palette;
  final bool showTopBar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showTopBar)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                CamsSkeletonCircle(size: 36),
                Spacer(),
                CamsSkeletonLine(width: 120, height: 14),
                Spacer(),
                CamsSkeletonCircle(size: 36),
              ],
            ),
          ),
        const Expanded(
          child: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(24, 8, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: CamsSkeletonCircle(size: 280)),
                SizedBox(height: 28),
                CamsSkeletonLine(width: 240, height: 24),
                SizedBox(height: 10),
                CamsSkeletonLine(width: 140, height: 14),
                SizedBox(height: 28),
                CamsSkeletonLine(height: 8),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CamsSkeletonCircle(size: 36),
                    CamsSkeletonCircle(size: 44),
                    CamsSkeletonCircle(size: 64),
                    CamsSkeletonCircle(size: 44),
                    CamsSkeletonCircle(size: 36),
                  ],
                ),
                SizedBox(height: 28),
                CamsSkeletonBox(height: 72, radius: 18),
                SizedBox(height: 16),
                CamsSkeletonList(
                  itemCount: 3,
                  padding: EdgeInsets.zero,
                  showTrailing: true,
                ),
              ],
            ),
          ),
        ),
        Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: palette.card,
            border: Border(top: BorderSide(color: palette.border)),
          ),
          child: const Row(
            children: [
              Expanded(child: CamsSkeletonLine(height: 14)),
              SizedBox(width: 16),
              CamsSkeletonCircle(size: 40),
            ],
          ),
        ),
      ],
    );
  }
}

class _QueueSheet extends StatefulWidget {
  static const int _defaultRemoteVolumePercent = 60;
  static const int _minimumRemoteVolumePercent = 30;

  const _QueueSheet({
    required this.palette,
    required this.controller,
    required this.onOpenAddToQueue,
  });

  final _NPPalette palette;
  final ScrollController controller;
  final VoidCallback onOpenAddToQueue;

  @override
  State<_QueueSheet> createState() => _QueueSheetState();
}

class _QueueSheetState extends State<_QueueSheet> {
  _NPPalette get palette => widget.palette;
  ScrollController get controller => widget.controller;
  VoidCallback get onOpenAddToQueue => widget.onOpenAddToQueue;

  int _normalizeAudibleVolumePercent(int requestedVolumePercent) {
    final boundedVolume = requestedVolumePercent.clamp(0, 100).toInt();
    if (boundedVolume <= 0) return 0;
    if (boundedVolume < _QueueSheet._minimumRemoteVolumePercent) {
      return _QueueSheet._minimumRemoteVolumePercent;
    }
    return boundedVolume;
  }

  int _preferredAudibleVolumePercent(BuildContext context) {
    final playback = context.read<CamsPlaybackBloc>().state.playbackState;
    final playbackVolume = playback?.volumePercent;
    if (playbackVolume != null && playbackVolume > 0) {
      return _normalizeAudibleVolumePercent(playbackVolume);
    }
    return _QueueSheet._defaultRemoteVolumePercent;
  }

  void _previewLocalVolume(
    BuildContext context, {
    required int volumePercent,
    required bool isMuted,
  }) {
    context.read<PlayerBloc>().add(
          PlayerAudioSettingsApplied(
            volumePercent: volumePercent.clamp(0, 100).toInt(),
            isMuted: isMuted,
          ),
        );
  }

  void _applyMuteIntent(
    BuildContext context, {
    required bool isMuted,
  }) {
    if (isMuted) {
      _dispatchAudioStatePatch(
        context,
        isMuted: true,
        localVolumePercent: 0,
        localIsMuted: true,
      );
      return;
    }

    final restoredVolume = _preferredAudibleVolumePercent(context);
    _dispatchAudioStatePatch(
      context,
      volumePercent: restoredVolume,
      isMuted: false,
      localVolumePercent: restoredVolume,
      localIsMuted: false,
    );
  }

  void _applyVolumeIntent(
    BuildContext context, {
    required int requestedVolumePercent,
  }) {
    final boundedVolume = requestedVolumePercent.clamp(0, 100).toInt();
    if (boundedVolume <= 0) {
      _applyMuteIntent(context, isMuted: true);
      return;
    }

    final normalizedVolume = _normalizeAudibleVolumePercent(boundedVolume);
    _dispatchAudioStatePatch(
      context,
      volumePercent: normalizedVolume,
      isMuted: false,
      localVolumePercent: normalizedVolume,
      localIsMuted: false,
    );
  }

  void _dispatchQueueReorderIds(
    BuildContext context,
    List<String> queueItemIds,
  ) {
    if (queueItemIds.length < 2) return;
    if (queueItemIds.any((id) => id.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot reorder pending queue because some queue ids are missing.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<CamsPlaybackBloc>().add(
          CamsReorderQueue(queueItemIds: queueItemIds),
        );
  }

  void _dispatchPlayQueueItem(BuildContext context, QueueSheetItem item) {
    if (item.isCurrent) return;
    final queueItemId = item.queueItemId;
    if (queueItemId == null || queueItemId.isEmpty) return;

    context.read<CamsPlaybackBloc>().add(
          CamsSendCommand(
            command: PlaybackCommandEnum.skipToTrack,
            targetQueueItemId: queueItemId,
            targetTrackId: item.trackId,
          ),
        );
  }

  void _dispatchRemoveQueueItem(BuildContext context, QueueSheetItem item) {
    final queueItemId = item.queueItemId;
    if (queueItemId == null || queueItemId.isEmpty) return;

    context.read<CamsPlaybackBloc>().add(
          CamsRemoveQueueItems(queueItemIds: [queueItemId]),
        );
  }

  Future<void> _confirmAndClearQueue(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear Queue'),
          content: const Text(
            'Remove all queued tracks and stop queued playback for this space?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    context.read<CamsPlaybackBloc>().add(const CamsClearQueue());
  }

  void _dispatchAudioStatePatch(
    BuildContext context, {
    int? volumePercent,
    bool? isMuted,
    int? queueEndBehavior,
    int? localVolumePercent,
    bool? localIsMuted,
  }) {
    context.read<CamsPlaybackBloc>().add(
          CamsUpdateAudioState(
            volumePercent: volumePercent,
            isMuted: isMuted,
            queueEndBehavior: queueEndBehavior,
          ),
        );

    if (volumePercent != null || isMuted != null) {
      context.read<PlayerBloc>().add(
            PlayerAudioSettingsApplied(
              volumePercent: (localVolumePercent ?? volumePercent ?? 100)
                  .clamp(0, 100)
                  .toInt(),
              isMuted: localIsMuted ?? isMuted ?? false,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, ps.PlayerState>(
      builder: (context, playerState) {
        return BlocBuilder<CamsPlaybackBloc, CamsPlaybackState>(
          builder: (context, camsState) {
            final queueData = QueueSheetViewData.resolve(
              playerState: playerState,
              camsState: camsState,
            );
            final playback = camsState.playbackState;
            final currentTrack = queueData.currentItem;

            return SafeArea(
              child: CustomScrollView(
                controller: controller,
                slivers: [
                  SliverToBoxAdapter(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text('Queue',
                                        style: GoogleFonts.poppins(
                                          color: palette.textPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        )),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop(),
                                    child: Text('Close',
                                        style: GoogleFonts.inter(
                                          color: palette.textMuted,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ),
                                ],
                              ),
                              if (queueData.isFromCams) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () {
                                          Navigator.of(
                                            context,
                                            rootNavigator: true,
                                          ).pop();
                                          Future.microtask(onOpenAddToQueue);
                                        },
                                        icon: const Icon(
                                          Icons.queue_music,
                                          size: 16,
                                        ),
                                        label: const Text('Add'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: palette.textMuted,
                                          textStyle: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (queueData.items.isNotEmpty)
                                        TextButton.icon(
                                          onPressed: () =>
                                              _confirmAndClearQueue(context),
                                          icon: const Icon(
                                            Icons.clear_all,
                                            size: 16,
                                          ),
                                          label: const Text('Clear'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: palette.textMuted,
                                            textStyle: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: Text(
                            queueData.summaryLabel,
                            style: GoogleFonts.inter(
                              color: palette.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (queueData.isFromCams && playback != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                            child: _QueueAudioControls(
                              palette: palette,
                              volumePercent: playback.volumePercent,
                              isMuted: playback.isMuted,
                              queueEndBehavior: playback.queueEndBehavior,
                              onToggleMute: (nextMuted) {
                                _applyMuteIntent(
                                  context,
                                  isMuted: nextMuted,
                                );
                              },
                              onVolumePreviewChanged: (volumePercent) {
                                final bounded =
                                    volumePercent.clamp(0, 100).toInt();
                                final previewMuted = bounded == 0;
                                _previewLocalVolume(
                                  context,
                                  volumePercent: previewMuted
                                      ? 0
                                      : _normalizeAudibleVolumePercent(
                                          bounded,
                                        ),
                                  isMuted: previewMuted,
                                );
                              },
                              onVolumeChanged: (volumePercent) {
                                _applyVolumeIntent(
                                  context,
                                  requestedVolumePercent: volumePercent,
                                );
                              },
                              onQueueEndBehaviorChanged: (behavior) {
                                _dispatchAudioStatePatch(
                                  context,
                                  queueEndBehavior: behavior.value,
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!queueData.hasVisibleItems)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            queueData.emptyMessage,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: palette.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    )
                  else ...[
                    if (queueData.played.isNotEmpty)
                      ..._buildSectionSlivers(
                        context,
                        title: 'Played',
                        items: queueData.played,
                        queueData: queueData,
                      ),
                    if (currentTrack != null)
                      ..._buildSectionSlivers(
                        context,
                        title: 'Now playing',
                        items: [currentTrack],
                        queueData: queueData,
                        isCurrentSection: true,
                      ),
                    if (queueData.pendingNotInQueueLabel != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: palette.overlay,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: palette.border),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: palette.accent,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    queueData.pendingNotInQueueLabel!,
                                    style: GoogleFonts.inter(
                                      color: palette.textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ..._buildSectionSlivers(
                      context,
                      title: 'Up next',
                      items: queueData.upNext,
                      queueData: queueData,
                      emptyMessage: queueData.upNextEmptyMessage,
                    ),
                  ],
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 12),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildSectionSlivers(
    BuildContext context, {
    required String title,
    required List<QueueSheetItem> items,
    required QueueSheetViewData queueData,
    bool isCurrentSection = false,
    String? emptyMessage,
  }) {
    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            title,
            style: isCurrentSection
                ? GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )
                : GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
          ),
        ),
      ),
    ];

    if (items.isEmpty) {
      if (emptyMessage != null && emptyMessage.isNotEmpty) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.overlay,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  emptyMessage,
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }
      return slivers;
    }

    if (queueData.isFromCams &&
        items.any((item) => item.isUpNext) &&
        queueData.reorderablePendingItems.length > 1) {
      slivers.add(
        _QueueReorderableTrackSliver(
          items: items,
          palette: palette,
          onPlay: (item) => _dispatchPlayQueueItem(context, item),
          onRemove: (item) => _dispatchRemoveQueueItem(context, item),
          onReorderPendingIds: (queueItemIds) =>
              _dispatchQueueReorderIds(context, queueItemIds),
        ),
      );
      return slivers;
    }

    slivers.add(
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, index) {
              final queuedTrack = items[index];
              final canManageQueue = queueData.isFromCams &&
                  queuedTrack.queueItemId != null &&
                  queuedTrack.queueItemId!.isNotEmpty;

              return _QueueTrackTile(
                title: queuedTrack.title,
                artist: queuedTrack.artist,
                artUrl: queuedTrack.artUrl,
                isPlaying: queuedTrack.isCurrent,
                isPending: queuedTrack.isPending,
                meta: queuedTrack.metaLabel,
                sourceLabel: queuedTrack.sourceLabel,
                palette: palette,
                onTap: canManageQueue && !queuedTrack.isCurrent
                    ? () => _dispatchPlayQueueItem(context, queuedTrack)
                    : null,
                trailing: canManageQueue && !queuedTrack.isCurrent
                    ? _QueueTrackActions(
                        palette: palette,
                        onPlay: () =>
                            _dispatchPlayQueueItem(context, queuedTrack),
                        onRemove: () =>
                            _dispatchRemoveQueueItem(context, queuedTrack),
                      )
                    : null,
              );
            },
            childCount: items.length,
          ),
        ),
      ),
    );

    return slivers;
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// Sub-widgets
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

// â”€â”€ Top Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _QueueAudioControls extends StatefulWidget {
  const _QueueAudioControls({
    required this.palette,
    required this.volumePercent,
    required this.isMuted,
    required this.queueEndBehavior,
    required this.onToggleMute,
    required this.onVolumePreviewChanged,
    required this.onVolumeChanged,
    required this.onQueueEndBehaviorChanged,
  });

  final _NPPalette palette;
  final int volumePercent;
  final bool isMuted;
  final int queueEndBehavior;
  final ValueChanged<bool> onToggleMute;
  final ValueChanged<int> onVolumePreviewChanged;
  final ValueChanged<int> onVolumeChanged;
  final ValueChanged<QueueEndBehaviorEnum> onQueueEndBehaviorChanged;

  @override
  State<_QueueAudioControls> createState() => _QueueAudioControlsState();
}

class _QueueAudioControlsState extends State<_QueueAudioControls> {
  double? _draftVolumePercent;
  bool _isDragging = false;

  int get _effectiveVolumePercent =>
      widget.isMuted ? 0 : widget.volumePercent.clamp(0, 100).toInt();

  @override
  void didUpdateWidget(covariant _QueueAudioControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isDragging || _draftVolumePercent == null) return;

    final drift = (_effectiveVolumePercent - _draftVolumePercent!).abs();
    if (drift <= 1) {
      setState(() {
        _draftVolumePercent = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedVolumePercent =
        (_draftVolumePercent ?? _effectiveVolumePercent.toDouble())
            .clamp(0.0, 100.0)
            .toDouble();
    final selectedBehavior =
        QueueEndBehaviorEnum.fromValue(widget.queueEndBehavior);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: widget.palette.overlay,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Audio settings',
                style: GoogleFonts.inter(
                  color: widget.palette.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${displayedVolumePercent.round()}%',
                style: GoogleFonts.inter(
                  color: widget.palette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                constraints:
                    const BoxConstraints.tightFor(width: 28, height: 28),
                padding: EdgeInsets.zero,
                tooltip: widget.isMuted ? 'Unmute' : 'Mute',
                onPressed: () {
                  setState(() {
                    _draftVolumePercent = widget.isMuted
                        ? widget.volumePercent.clamp(0, 100).toDouble()
                        : 0;
                    _isDragging = false;
                  });
                  widget.onToggleMute(!widget.isMuted);
                },
                icon: Icon(
                  widget.isMuted ? LucideIcons.volumeX : LucideIcons.volume2,
                  size: 16,
                  color: widget.palette.textMuted,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: widget.palette.textPrimary,
              inactiveTrackColor:
                  widget.palette.textMuted.withValues(alpha: 0.25),
              thumbColor: widget.palette.textPrimary,
              overlayColor: widget.palette.textPrimary.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: displayedVolumePercent,
              min: 0,
              max: 100,
              divisions: 20,
              onChangeStart: (value) {
                setState(() {
                  _isDragging = true;
                  _draftVolumePercent = value.clamp(0.0, 100.0).toDouble();
                });
              },
              onChanged: (value) {
                final nextValue = value.clamp(0.0, 100.0).toDouble();
                setState(() {
                  _draftVolumePercent = nextValue;
                });
                widget.onVolumePreviewChanged(nextValue.round());
              },
              onChangeEnd: (value) {
                final roundedVolume =
                    value.clamp(0.0, 100.0).round().clamp(0, 100).toInt();
                setState(() {
                  _isDragging = false;
                  _draftVolumePercent = roundedVolume.toDouble();
                });
                widget.onVolumeChanged(roundedVolume);
              },
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: QueueEndBehaviorEnum.values.map((behavior) {
              final selected = behavior == selectedBehavior;
              return ChoiceChip(
                label: Text(
                  behavior.label,
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
                backgroundColor: widget.palette.card,
                side: BorderSide(
                  color:
                      selected ? widget.palette.accent : widget.palette.border,
                ),
                onSelected: (_) => widget.onQueueEndBehaviorChanged(behavior),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SpinningAlbumDisc extends StatelessWidget {
  const _SpinningAlbumDisc({
    required this.artUrl,
    required this.palette,
    required this.rotation,
    required this.placeholder,
  });

  final String? artUrl;
  final _NPPalette palette;
  final Animation<double> rotation;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.22),
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: RotationTransition(
          turns: rotation,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.card,
                    border: Border.all(
                      color: palette.border.withValues(alpha: 0.75),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ClipOval(
                      child: artUrl != null
                          ? Image.network(
                              artUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => placeholder,
                            )
                          : placeholder,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.18),
                        ],
                        stops: const [0.0, 0.62, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.bg,
                  border: Border.all(
                    color: palette.border.withValues(alpha: 0.9),
                    width: 8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.textMuted.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

class _IotStatusNotice extends StatelessWidget {
  const _IotStatusNotice({
    required this.palette,
    required this.playbackState,
  });

  final _NPPalette palette;
  final SpacePlaybackState playbackState;

  @override
  Widget build(BuildContext context) {
    final label = playbackState.iotStatusLabel ?? 'IoT status';
    final isWarning = playbackState.hasIotWarning;
    final icon = playbackState.isIotDeviceAssigned == false
        ? LucideIcons.radioReceiver
        : playbackState.isIotDeviceOffline
            ? LucideIcons.wifiOff
            : LucideIcons.wifi;
    final color = isWarning ? palette.warning : palette.success;
    final message = playbackState.isIotDeviceAssigned == false
        ? 'No IoT device is assigned to this space. Schedule and AI telemetry may be limited.'
        : playbackState.isIotDeviceOffline
            ? 'IoT device is offline. Manual override remains available while CAMS waits for fresh telemetry.'
            : 'IoT telemetry is online.';

    return Container(
      padding: EdgeInsets.all(isWarning ? 14 : 10),
      decoration: BoxDecoration(
        color: palette.overlay,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWarning ? color.withValues(alpha: 0.42) : palette.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: palette.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (isWarning) ...[
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      color: palette.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
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
          // Minimize button â€” compact to give more room to title
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
          // Menu button â€” compact
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

// â”€â”€ Progress Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ProgressBar extends StatefulWidget {
  const _ProgressBar(
      {required this.duration,
      required this.currentPosition,
      required this.remainingDuration,
      required this.seekBaseOffsetSeconds,
      required this.useAbsoluteSeek,
      required this.useRemoteControls,
      required this.enabled,
      required this.palette});
  final int duration;
  final double currentPosition;
  final int remainingDuration;
  final int seekBaseOffsetSeconds;
  final bool useAbsoluteSeek;
  final bool useRemoteControls;
  final bool enabled;
  final _NPPalette palette;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  static const Duration _remoteSeekDebounce = Duration(milliseconds: 180);

  Timer? _remoteSeekTimer;
  double? _dragPositionSeconds;
  bool _isDragging = false;

  String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void didUpdateWidget(covariant _ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isDragging || _dragPositionSeconds == null) return;

    final drift = (widget.currentPosition - _dragPositionSeconds!).abs();
    if (drift <= 1) {
      setState(() {
        _dragPositionSeconds = null;
      });
    }
  }

  @override
  void dispose() {
    _remoteSeekTimer?.cancel();
    super.dispose();
  }

  double _clampSliderPosition(double value) {
    if (widget.duration <= 0) return 0;
    return value.clamp(0.0, widget.duration.toDouble()).toDouble();
  }

  int _resolveAbsoluteTargetSeconds(double sliderPositionSeconds) {
    final seekSeconds = sliderPositionSeconds.round();
    return widget.useAbsoluteSeek
        ? widget.seekBaseOffsetSeconds + seekSeconds
        : seekSeconds;
  }

  void _dispatchSeekCommit(double sliderPositionSeconds) {
    if (!widget.enabled) return;
    final localTargetSeconds =
        _resolveAbsoluteTargetSeconds(sliderPositionSeconds);
    final remoteTargetSeconds = sliderPositionSeconds.round();
    context.read<PlayerBloc>().add(
          PlayerSeekRequested(positionSeconds: localTargetSeconds),
        );

    if (!widget.useRemoteControls) return;

    _remoteSeekTimer?.cancel();
    _remoteSeekTimer = Timer(_remoteSeekDebounce, () {
      if (!mounted) return;
      // CAMS seek payload targets the current HLS stream position, not the
      // cumulative queue offset shown in local PlayerState.
      context.read<CamsPlaybackBloc>().add(
            CamsSendCommand(
              command: PlaybackCommandEnum.seek,
              seekPositionSeconds: remoteTargetSeconds.toDouble(),
            ),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayedPosition = _dragPositionSeconds ?? widget.currentPosition;
    final clampedPosition = widget.duration > 0
        ? displayedPosition.clamp(0.0, widget.duration.toDouble()).toDouble()
        : 0.0;
    final displayedRemaining = widget.duration > 0
        ? (widget.duration - clampedPosition.floor())
            .clamp(0, widget.duration)
            .toInt()
        : 0;
    final canSeek = widget.enabled && widget.duration > 0;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: widget.palette.textPrimary,
            inactiveTrackColor:
                widget.palette.textMuted.withValues(alpha: 0.25),
            thumbColor: widget.palette.textPrimary,
            overlayColor: widget.palette.textPrimary.withValues(alpha: 0.15),
          ),
          child: Slider(
            value: widget.duration > 0 ? clampedPosition : 0,
            min: 0,
            max: widget.duration > 0 ? widget.duration.toDouble() : 1,
            onChangeStart: canSeek
                ? (value) {
                    _remoteSeekTimer?.cancel();
                    setState(() {
                      _isDragging = true;
                      _dragPositionSeconds = _clampSliderPosition(value);
                    });
                  }
                : null,
            onChanged: canSeek
                ? (value) {
                    setState(() {
                      _dragPositionSeconds = _clampSliderPosition(value);
                    });
                  }
                : null,
            onChangeEnd: canSeek
                ? (value) {
                    final clampedValue = _clampSliderPosition(value);
                    setState(() {
                      _isDragging = false;
                      _dragPositionSeconds = clampedValue;
                    });
                    _dispatchSeekCommit(clampedValue);
                  }
                : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(clampedPosition.floor()),
                  style: GoogleFonts.inter(
                      color: widget.palette.textMuted, fontSize: 12)),
              Text(
                  widget.duration > 0
                      ? '-${_fmt(displayedRemaining)}'
                      : '--:--',
                  style: GoogleFonts.inter(
                      color: widget.palette.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

// â”€â”€ Controls Row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ControlsRow extends StatelessWidget {
  const _ControlsRow({
    required this.isPlaying,
    required this.isShuffleOn,
    required this.volume,
    required this.palette,
    required this.actionsEnabled,
    required this.hasNext,
    required this.hasPrevious,
    required this.onShuffle,
    required this.onPlayPause,
    required this.onSkipBack,
    required this.onSkip,
    required this.onVolumeChanged,
  });
  final bool isPlaying, isShuffleOn;
  final bool actionsEnabled;
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
          color: actionsEnabled
              ? (isShuffleOn ? palette.accent : palette.textMuted)
              : palette.textMuted.withValues(alpha: 0.4),
          size: 22,
          onTap: actionsEnabled ? onShuffle : null,
        ),
        const SizedBox(width: 20),
        // Skip Previous
        _ControlButton(
          icon: LucideIcons.skipBack,
          color: hasPrevious
              ? palette.textPrimary
              : palette.textMuted.withValues(alpha: 0.4),
          size: 26,
          onTap: hasPrevious ? onSkipBack : null,
        ),
        const SizedBox(width: 16),
        // Play/Pause (large center button)
        GestureDetector(
          onTap: actionsEnabled ? onPlayPause : null,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: actionsEnabled
                  ? palette.textPrimary
                  : palette.textMuted.withValues(alpha: 0.35),
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
              : palette.textMuted.withValues(alpha: 0.4),
          size: 26,
          onTap: hasNext ? onSkip : null,
        ),
        const SizedBox(width: 20),
        // Volume
        _ControlButton(
          icon: volume > 0 ? LucideIcons.volume2 : LucideIcons.volumeX,
          color: actionsEnabled
              ? palette.textMuted
              : palette.textMuted.withValues(alpha: 0.4),
          size: 22,
          onTap: actionsEnabled
              ? () => onVolumeChanged(volume > 0 ? 0 : 0.6)
              : null,
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
  final VoidCallback? onTap;

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

// â”€â”€ Bottom Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€ Sheet Option â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€ Queue Track Tile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _QueueTrackTile extends StatelessWidget {
  const _QueueTrackTile({
    required this.title,
    required this.artist,
    this.artUrl,
    required this.isPlaying,
    this.isPending = false,
    this.meta,
    this.sourceLabel,
    this.onTap,
    this.leading,
    this.trailing,
    required this.palette,
  });
  final String title, artist;
  final String? artUrl;
  final bool isPlaying;
  final bool isPending;
  final String? meta;
  final String? sourceLabel;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;
  final _NPPalette palette;

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
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 8),
          ],
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
                  maxLines: 2,
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
                if (meta != null && meta!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        meta!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: isPending ? palette.accent : palette.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (sourceLabel != null && sourceLabel!.isNotEmpty)
                        _QueueSourceBadge(
                          label: sourceLabel!,
                          palette: palette,
                        ),
                    ],
                  ),
                ] else if (sourceLabel != null && sourceLabel!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _QueueSourceBadge(
                    label: sourceLabel!,
                    palette: palette,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (isPending)
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: child,
    );
  }
}

class _QueueDragHandle extends StatelessWidget {
  const _QueueDragHandle({
    required this.palette,
  });

  final _NPPalette palette;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Drag to reorder',
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.overlay,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.border),
        ),
        child: Icon(
          LucideIcons.gripVertical,
          size: 17,
          color: palette.textMuted,
        ),
      ),
    );
  }
}

class _QueueTrackActions extends StatelessWidget {
  const _QueueTrackActions({
    required this.palette,
    this.onPlay,
    required this.onRemove,
  });

  final _NPPalette palette;
  final VoidCallback? onPlay;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onPlay != null)
          IconButton(
            tooltip: 'Play this track',
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            padding: EdgeInsets.zero,
            onPressed: onPlay,
            icon: Icon(
              LucideIcons.playCircle,
              size: 16,
              color: palette.textMuted,
            ),
          ),
        IconButton(
          tooltip: 'Remove',
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          padding: EdgeInsets.zero,
          onPressed: onRemove,
          icon: Icon(
            LucideIcons.trash2,
            size: 16,
            color: palette.textMuted,
          ),
        ),
      ],
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _QueueSourceBadge extends StatelessWidget {
  const _QueueSourceBadge({
    required this.label,
    required this.palette,
  });

  final String label;
  final _NPPalette palette;

  Color get _color {
    switch (label.toLowerCase()) {
      case 'ai':
        return palette.moodDefault;
      case 'schedule':
        return palette.success;
      case 'manager':
        return palette.accentAlt;
      default:
        return palette.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QueueReorderableTrackSliver extends StatefulWidget {
  const _QueueReorderableTrackSliver({
    required this.items,
    required this.palette,
    required this.onPlay,
    required this.onRemove,
    required this.onReorderPendingIds,
  });

  final List<QueueSheetItem> items;
  final _NPPalette palette;
  final ValueChanged<QueueSheetItem> onPlay;
  final ValueChanged<QueueSheetItem> onRemove;
  final ValueChanged<List<String>> onReorderPendingIds;

  @override
  State<_QueueReorderableTrackSliver> createState() =>
      _QueueReorderableTrackSliverState();
}

class _QueueReorderableTrackSliverState
    extends State<_QueueReorderableTrackSliver> {
  late List<QueueSheetItem> _items;
  bool _isReordering = false;
  List<QueueSheetItem>? _deferredItems;

  @override
  void initState() {
    super.initState();
    _items = List<QueueSheetItem>.of(widget.items);
  }

  @override
  void didUpdateWidget(covariant _QueueReorderableTrackSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_signature(oldWidget.items) != _signature(widget.items)) {
      final nextItems = List<QueueSheetItem>.of(widget.items);
      if (_isReordering) {
        _deferredItems = nextItems;
      } else {
        _items = nextItems;
      }
    }
  }

  String _signature(List<QueueSheetItem> items) {
    return items
        .map(
          (item) => '${item.queueItemId ?? item.trackId}:'
              '${item.queueStatus}:${item.queuePosition}:${item.source}',
        )
        .join('|');
  }

  bool _isPending(QueueSheetItem item) {
    return item.queueStatus == SpacePlaybackState.queueStatusPending &&
        item.queueItemId != null &&
        item.queueItemId!.isNotEmpty;
  }

  void _handleReorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _items.length) return;
    final movedItem = _items[oldIndex];
    if (!_isPending(movedItem)) return;

    var targetIndex = newIndex;
    if (targetIndex > oldIndex) targetIndex -= 1;
    if (targetIndex < 0 || targetIndex >= _items.length) return;

    setState(() {
      final reordered = List<QueueSheetItem>.of(_items);
      final item = reordered.removeAt(oldIndex);
      reordered.insert(targetIndex, item);
      _items = reordered;
    });

    final pendingOrderedIds = _items
        .where(_isPending)
        .map((item) => item.queueItemId!)
        .toList(growable: false);
    widget.onReorderPendingIds(pendingOrderedIds);
  }

  void _handleReorderStart(int index) {
    _isReordering = true;
    _deferredItems = null;
  }

  void _handleReorderEnd(int index) {
    _isReordering = false;
    final deferredItems = _deferredItems;
    _deferredItems = null;
    if (deferredItems == null || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isReordering) return;
      setState(() {
        _items = deferredItems;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverReorderableList(
        itemCount: _items.length,
        onReorder: _handleReorder,
        onReorderStart: _handleReorderStart,
        onReorderEnd: _handleReorderEnd,
        proxyDecorator: (child, index, animation) {
          return Material(
            color: Colors.transparent,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1, end: 1.02).animate(animation),
              child: child,
            ),
          );
        },
        itemBuilder: (context, index) {
          final item = _items[index];
          final canDrag = _isPending(item);
          final key = ValueKey(item.queueItemId ?? '${item.trackId}-$index');
          final tile = _QueueTrackTile(
            title: item.title,
            artist: item.artist,
            artUrl: item.artUrl,
            isPlaying: item.isCurrent,
            isPending: item.isPending,
            meta: item.metaLabel,
            sourceLabel: item.sourceLabel,
            palette: widget.palette,
            onTap: item.isCurrent ? null : () => widget.onPlay(item),
            leading: canDrag
                ? ReorderableDragStartListener(
                    index: index,
                    child: _QueueDragHandle(palette: widget.palette),
                  )
                : null,
            trailing: _QueueTrackActions(
              palette: widget.palette,
              onPlay: item.isCurrent ? null : () => widget.onPlay(item),
              onRemove: () => widget.onRemove(item),
            ),
          );

          return KeyedSubtree(
            key: key,
            child: canDrag
                ? ReorderableDelayedDragStartListener(
                    index: index,
                    child: tile,
                  )
                : tile,
          );
        },
      ),
    );
  }
}

// ============================================================================
// Manual / Auto Override panel (same behavior as Home)
// ============================================================================
class _RuntimeStatusPanel extends StatefulWidget {
  const _RuntimeStatusPanel({
    required this.playbackState,
    required this.palette,
    required this.isBusy,
    required this.onSchedulingChanged,
  });

  final SpacePlaybackState playbackState;
  final _NPPalette palette;
  final bool isBusy;
  final ValueChanged<bool> onSchedulingChanged;

  @override
  State<_RuntimeStatusPanel> createState() => _RuntimeStatusPanelState();
}

class _RuntimeStatusPanelState extends State<_RuntimeStatusPanel> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  int? _remainingSecondsUntil(DateTime? utcDeadline) {
    if (utcDeadline == null) return null;
    final remaining = utcDeadline.toUtc().difference(DateTime.now().toUtc());
    return remaining.inSeconds < 0 ? 0 : remaining.inSeconds;
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = widget.playbackState;
    final palette = widget.palette;
    final manualRemainingSeconds =
        _remainingSecondsUntil(playbackState.manualOverrideExpiresAtUtc) ??
            playbackState.manualOverrideRemainingSeconds;
    final schedulingRemainingSeconds =
        _remainingSecondsUntil(playbackState.schedulingEndsAtUtc) ??
            playbackState.schedulingRemainingSeconds;
    final manualRows = <MapEntry<String, String>>[
      if (playbackState.overrideReason?.trim().isNotEmpty == true)
        MapEntry('Reason', playbackState.overrideReason!.trim()),
      if (manualRemainingSeconds != null)
        MapEntry(
          'Remaining',
          _formatRuntimeSeconds(manualRemainingSeconds),
        ),
      if (playbackState.manualOverrideActivatedAtUtc != null)
        MapEntry(
          'Activated',
          _formatRuntimeDateTime(playbackState.manualOverrideActivatedAtUtc!),
        ),
      if (playbackState.manualOverrideExpiresAtUtc != null)
        MapEntry(
          'Expires',
          _formatRuntimeDateTime(playbackState.manualOverrideExpiresAtUtc!),
        ),
    ];
    final schedulingRows = <MapEntry<String, String>>[
      if (playbackState.schedulingOriginLabel != null)
        MapEntry('Origin', playbackState.schedulingOriginLabel!),
      if (playbackState.schedulingSlotId?.trim().isNotEmpty == true)
        MapEntry('Slot', playbackState.schedulingSlotId!.trim()),
      if (schedulingRemainingSeconds != null)
        MapEntry(
          'Remaining',
          _formatRuntimeSeconds(schedulingRemainingSeconds),
        ),
      if (playbackState.schedulingEndsAtUtc != null)
        MapEntry(
          'Ends',
          _formatRuntimeDateTime(playbackState.schedulingEndsAtUtc!),
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
              Icon(Icons.schedule_rounded, color: palette.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Runtime status',
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Switch.adaptive(
                value: playbackState.isScheduling,
                activeThumbColor: palette.accent,
                onChanged: widget.isBusy ? null : widget.onSchedulingChanged,
              ),
            ],
          ),
          if (playbackState.isManualOverride) ...[
            const SizedBox(height: 12),
            _RuntimeStatusSection(
              title: 'Manual override',
              rows: manualRows,
              palette: palette,
            ),
          ],
          if (playbackState.isScheduling) ...[
            const SizedBox(height: 12),
            _RuntimeStatusSection(
              title: 'Scheduling runtime',
              rows: schedulingRows,
              palette: palette,
            ),
          ],
        ],
      ),
    );
  }
}

class _RuntimeStatusSection extends StatelessWidget {
  const _RuntimeStatusSection({
    required this.title,
    required this.rows,
    required this.palette,
  });

  final String title;
  final List<MapEntry<String, String>> rows;
  final _NPPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: palette.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: rows.isEmpty
              ? [
                  _RuntimePill(
                    label: 'Active',
                    value: 'Waiting for details',
                    palette: palette,
                  ),
                ]
              : rows
                  .map(
                    (entry) => _RuntimePill(
                      label: entry.key,
                      value: entry.value,
                      palette: palette,
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}

class _RuntimePill extends StatelessWidget {
  const _RuntimePill({
    required this.label,
    required this.value,
    required this.palette,
  });

  final String label;
  final String value;
  final _NPPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.overlay,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              color: palette.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiInsightButton extends StatelessWidget {
  const _AiInsightButton({
    required this.palette,
    required this.onTap,
  });

  final _NPPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: palette.accent.withValues(alpha: 0.28)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: palette.accent,
                  size: 16,
                ),
                const SizedBox(width: 7),
                Text(
                  'AI insight',
                  style: GoogleFonts.inter(
                    color: palette.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _AiExplainabilitySheet extends StatelessWidget {
  const _AiExplainabilitySheet({
    required this.palette,
    required this.playbackState,
    required this.fallbackMoodName,
    required this.controller,
  });

  final _NPPalette palette;
  final SpacePlaybackState playbackState;
  final String? fallbackMoodName;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final data = playbackState.explainability;
    final moodName =
        _firstText(data?.moodName, playbackState.moodName, fallbackMoodName);
    final confidencePercent = _toPercent(data?.confidence);
    final scoreBreakdown = data?.scoreBreakdown;
    final signalRows = data?.signalContributions ?? const [];
    final bpmBandLabel = data?.bpmBandLabel;
    final bpmTargetLabel = data?.bpmTargetLabel;
    final ruleName = data?.triggeredRule?.trim();
    final reason = data?.reason?.trim();
    final summary = <_AiSummaryChipData>[
      if (moodName != null)
        _AiSummaryChipData(
          label: 'Current Mood',
          value: moodName,
          icon: Icons.visibility_rounded,
        ),
      if (bpmBandLabel != null)
        _AiSummaryChipData(
          label: 'BPM Range',
          value: bpmBandLabel,
          icon: Icons.speed_rounded,
        ),
      if (bpmTargetLabel != null)
        _AiSummaryChipData(
          label: 'Target',
          value: bpmTargetLabel,
          icon: Icons.flag_rounded,
        ),
      if (ruleName != null && ruleName.isNotEmpty)
        _AiSummaryChipData(
          label: 'Context Rule',
          value: _formatRuleName(ruleName),
          icon: Icons.rule_rounded,
        ),
    ];

    return SafeArea(
      child: ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
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
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: palette.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI Music Selection',
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close_rounded, color: palette.textMuted),
                tooltip: 'Close',
              ),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: summary
                  .map((item) => _AiSummaryChip(item: item, palette: palette))
                  .toList(),
            ),
          ],
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 18),
            _AiInfoNotice(
              palette: palette,
              icon: Icons.info_outline_rounded,
              title: 'Reason',
              message: reason,
            ),
          ],
          if (confidencePercent != null) ...[
            const SizedBox(height: 22),
            _AiSectionTitle('Confidence', palette: palette),
            const SizedBox(height: 10),
            _AiProgressRow(
              label: 'Selection confidence',
              valuePercent: confidencePercent,
              palette: palette,
            ),
          ],
          if (scoreBreakdown != null && scoreBreakdown.hasAnyData) ...[
            const SizedBox(height: 24),
            _AiSectionTitle('Mood score breakdown', palette: palette),
            const SizedBox(height: 10),
            if (scoreBreakdown.chillScore != null)
              _AiProgressRow(
                label: 'Chill',
                valuePercent: _scoreToPercent(scoreBreakdown.chillScore),
                palette: palette,
              ),
            if (scoreBreakdown.focusScore != null)
              _AiProgressRow(
                label: 'Focus',
                valuePercent: _scoreToPercent(scoreBreakdown.focusScore),
                palette: palette,
              ),
            if (scoreBreakdown.energeticScore != null)
              _AiProgressRow(
                label: 'Energetic',
                valuePercent: _scoreToPercent(scoreBreakdown.energeticScore),
                palette: palette,
              ),
          ],
          if (signalRows.isNotEmpty) ...[
            const SizedBox(height: 24),
            _AiSectionTitle('Signal contributions', palette: palette),
            const SizedBox(height: 10),
            ...signalRows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AiSignalContributionTile(
                  contribution: row,
                  palette: palette,
                ),
              ),
            ),
          ],
          if (data?.usedMoodOnlyFallback == true) ...[
            const SizedBox(height: 14),
            _AiInfoNotice(
              palette: palette,
              icon: Icons.manage_search_rounded,
              title: 'Using mood-only selection',
              message:
                  'Not enough tracks with BPM metadata matched the selected range.',
            ),
          ],
          if (playbackState.isManualOverride) ...[
            const SizedBox(height: 14),
            _AiInfoNotice(
              palette: palette,
              icon: Icons.pan_tool_alt_rounded,
              title: 'Manual Override Active',
              message:
                  'Manager-selected music is playing. AI recommendations are paused.',
              isWarning: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _AiSummaryChipData {
  const _AiSummaryChipData({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _AiSummaryChip extends StatelessWidget {
  const _AiSummaryChip({
    required this.item,
    required this.palette,
  });

  final _AiSummaryChipData item;
  final _NPPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: palette.overlay,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 14, color: palette.accent),
          const SizedBox(width: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: palette.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiSectionTitle extends StatelessWidget {
  const _AiSectionTitle(this.title, {required this.palette});

  final String title;
  final _NPPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: palette.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _AiProgressRow extends StatelessWidget {
  const _AiProgressRow({
    required this.label,
    required this.valuePercent,
    required this.palette,
  });

  final String label;
  final int valuePercent;
  final _NPPalette palette;

  @override
  Widget build(BuildContext context) {
    final bounded = valuePercent.clamp(0, 100).toInt();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$bounded%',
                style: GoogleFonts.inter(
                  color: palette.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: bounded / 100,
              minHeight: 7,
              backgroundColor: palette.overlay,
              valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiSignalContributionTile extends StatelessWidget {
  const _AiSignalContributionTile({
    required this.contribution,
    required this.palette,
  });

  final FuzzySignalContribution contribution;
  final _NPPalette palette;

  @override
  Widget build(BuildContext context) {
    final parsed = _parseSignal(contribution.signal);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.overlay,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _prettifySignalName(parsed.key),
            style: GoogleFonts.inter(
              color: palette.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (parsed.value != null) ...[
            const SizedBox(height: 4),
            Text(
              parsed.value!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (contribution.hasAnyDelta) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (contribution.chillDelta != null)
                  _AiImpactChip(
                    label: 'Chill',
                    value: contribution.chillDelta!,
                    color: palette.moodChill,
                  ),
                if (contribution.focusDelta != null)
                  _AiImpactChip(
                    label: 'Focus',
                    value: contribution.focusDelta!,
                    color: palette.moodFocus,
                  ),
                if (contribution.energeticDelta != null)
                  _AiImpactChip(
                    label: 'Energetic',
                    value: contribution.energeticDelta!,
                    color: palette.moodEnergetic,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AiImpactChip extends StatelessWidget {
  const _AiImpactChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final formatted = '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $formatted',
        style: GoogleFonts.inter(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AiInfoNotice extends StatelessWidget {
  const _AiInfoNotice({
    required this.palette,
    required this.icon,
    required this.title,
    required this.message,
    this.isWarning = false,
  });

  final _NPPalette palette;
  final IconData icon;
  final String title;
  final String message;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? palette.warning : palette.accent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: palette.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParsedSignal {
  const _ParsedSignal(this.key, this.value);

  final String key;
  final String? value;
}

String? _firstText(String? first, String? second, String? third) {
  for (final value in [first, second, third]) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

int? _toPercent(double? value) {
  if (value == null || value.isNaN) return null;
  final normalized = value <= 1 ? value * 100 : value;
  return normalized.round().clamp(0, 100).toInt();
}

int _scoreToPercent(double? value) => _toPercent(value) ?? 0;

String _formatRuleName(String raw) {
  final cleaned = raw.trim().replaceFirst(RegExp(r'^RULE_\d+_'), '');
  if (cleaned.isEmpty) return raw.trim();
  return cleaned
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) =>
          '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}

_ParsedSignal _parseSignal(String raw) {
  final trimmed = raw.trim();
  final matched = RegExp(r'^([^(]+)\((.*)\)$').firstMatch(trimmed);
  if (matched == null) return _ParsedSignal(trimmed, null);
  return _ParsedSignal(
    matched.group(1)?.trim() ?? trimmed,
    matched.group(2)?.trim(),
  );
}

String _prettifySignalName(String raw) {
  const mapped = {
    'crowdPressure': 'Crowd pressure',
    'ambientNoise': 'Ambient noise',
    'timeOfDay': 'Time of day',
    'dayOfWeek': 'Day of week',
    'businessPhase': 'Business phase',
  };
  return mapped[raw] ?? raw;
}

class _OverrideMoodCTA extends StatelessWidget {
  const _OverrideMoodCTA({
    required this.spaceId,
    required this.currentMood,
    required this.palette,
    required this.moods,
    required this.hasActiveOverride,
    required this.isOverriding,
    required this.isPreparing,
    this.lastOverrideResponse,
    required this.onOpenOverrideSheet,
  });

  final String spaceId;
  final String? currentMood;
  final _NPPalette palette;
  final List<Mood> moods;
  final bool hasActiveOverride;
  final bool isOverriding;
  final bool isPreparing;
  final OverrideResponse? lastOverrideResponse;
  final VoidCallback onOpenOverrideSheet;

  @override
  Widget build(BuildContext context) {
    final statusLabel = hasActiveOverride ? 'Manual Override' : 'Auto Mode';
    final subtitle = hasActiveOverride
        ? 'Tracks, playlist, or mood are currently overriding CAMS playback.'
        : 'CAMS is auto-adjusting playback. You can take over with tracks, a playlist, or a mood.';
    final ctaLabel = hasActiveOverride ? 'Change override' : 'Open override';
    final overrideSummary = lastOverrideResponse == null
        ? null
        : (lastOverrideResponse!.moodName?.trim().isNotEmpty == true)
            ? 'Latest override mood: ${lastOverrideResponse!.moodName!.trim()}'
            : (lastOverrideResponse!.playlistName?.trim().isNotEmpty == true)
                ? 'Latest override playlist: ${lastOverrideResponse!.playlistName!.trim()}'
                : lastOverrideResponse!.isAckOnly
                    ? 'Manual override acknowledged by CAMS.'
                    : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabel,
                      style: GoogleFonts.poppins(
                        color: palette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: palette.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: isOverriding ? null : onOpenOverrideSheet,
                icon: const Icon(Icons.tune, size: 16),
                label: Text(ctaLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.textOnAccent,
                  textStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (currentMood != null) ...[
            const SizedBox(height: 10),
            Text(
              'Mood state: ${currentMood!.toUpperCase()}',
              style: GoogleFonts.inter(
                color: palette.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (overrideSummary != null) ...[
            const SizedBox(height: 10),
            Text(
              overrideSummary,
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (isOverriding || isPreparing) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (isOverriding)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    LucideIcons.loader,
                    size: 14,
                    color: palette.textMuted,
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOverriding
                        ? 'Applying override...'
                        : 'Preparing next stream. Playback will continue automatically.',
                    style: GoogleFonts.inter(
                      color: palette.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: palette.overlay,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  '${moods.length} moods available',
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hasActiveOverride)
                TextButton.icon(
                  onPressed: isOverriding
                      ? null
                      : () => context
                          .read<CamsPlaybackBloc>()
                          .add(const CamsCancelOverride()),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Cancel override'),
                  style: TextButton.styleFrom(
                    foregroundColor: palette.textMuted,
                    textStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (hasActiveOverride && currentMood != null) ...[
            const SizedBox(height: 10),
            Text(
              'Tap "$ctaLabel" to switch source or replace the current manual selection.',
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// Space Swap Sheet (kept from original)
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
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
    context.read<CamsPlaybackBloc>().add(CamsInitPlayback(spaceId: space.id));
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
            Text('Switching space will update music and Hub status.',
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
                            ? palette.accent.withValues(alpha: 0.15)
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
                                  ? palette.success
                                  : palette.warning)),
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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// Palette (kept from original)
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
String _formatRuntimeSeconds(int seconds) {
  final safeSeconds = seconds < 0 ? 0 : seconds;
  final hours = safeSeconds ~/ 3600;
  final minutes = (safeSeconds % 3600) ~/ 60;
  if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
  if (hours > 0) return '${hours}h';
  if (minutes > 0) return '${minutes}m';
  return '${safeSeconds}s';
}

String _formatRuntimeDateTime(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}

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
    required this.success,
    required this.warning,
    required this.moodChill,
    required this.moodFocus,
    required this.moodEnergetic,
    required this.moodDefault,
  });

  factory _NPPalette.fromContext(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.camsTokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _NPPalette(
      isDark: isDark,
      bg: tokens.bgBase,
      card: tokens.bgContainer,
      overlay: tokens.bgElevated,
      border: tokens.borderSecondary,
      textPrimary: tokens.textPrimary,
      textMuted: tokens.textSecondary,
      accent: colorScheme.primary,
      accentAlt: tokens.techAccent,
      textOnAccent: colorScheme.onPrimary,
      shadow: tokens.shadow,
      success: tokens.success,
      warning: tokens.warning,
      moodChill: tokens.moodChill,
      moodFocus: tokens.moodFocus,
      moodEnergetic: tokens.moodEnergetic,
      moodDefault: tokens.moodDefault,
    );
  }

  final bool isDark;
  final Color bg, card, overlay, border, textPrimary, textMuted;
  final Color accent, accentAlt, textOnAccent, shadow, success, warning;
  final Color moodChill, moodFocus, moodEnergetic, moodDefault;
}
