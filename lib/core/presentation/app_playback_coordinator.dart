import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../audio/playback_notification_service.dart';
import '../enums/playback_command_enum.dart';
import '../player/playlist_queue_builder.dart';
import '../../features/playlists/data/datasources/playlist_remote_datasource.dart';
import '../../features/cams/presentation/bloc/cams_playback_bloc.dart';
import '../../features/cams/presentation/bloc/cams_playback_event.dart';
import '../../features/cams/presentation/bloc/cams_playback_state.dart';
import '../../features/cams/domain/entities/space_playback_state.dart';
import '../player/player_bloc.dart';
import '../player/player_event.dart';
import '../player/player_state.dart';
import '../session/session_cubit.dart';
import '../session/session_state.dart';
import '../../injection_container.dart';

/// Keeps Session, CAMS and the global PlayerBloc synchronized app-wide.
class AppPlaybackCoordinator extends StatefulWidget {
  const AppPlaybackCoordinator({super.key, required this.child});

  final Widget child;

  @override
  State<AppPlaybackCoordinator> createState() => _AppPlaybackCoordinatorState();
}

class _AppPlaybackCoordinatorState extends State<AppPlaybackCoordinator> {
  StreamSubscription<PlaybackNotificationCommand>? _notificationCommandSub;
  String? _hydratedPlaylistId;
  Timer? _managerProgressTicker;
  Timer? _expectedEndTimer;
  String? _expectedEndSignature;
  String? _managerWarmupSignature;
  DateTime? _managerWarmupUntilUtc;
  static const Duration _managerWarmupDuration = Duration(seconds: 4);
  static const double _managerWarmupCompensationSeconds = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notificationCommandSub =
          context.read<PlaybackNotificationService>().commands.listen(
                _handleNotificationCommand,
              );
      _syncSession(context.read<SessionCubit>().state);
      _syncNotification(
        session: context.read<SessionCubit>().state,
        playerState: context.read<PlayerBloc>().state,
      );
    });
  }

  void _syncSession(SessionState session) {
    final playerBloc = context.read<PlayerBloc>();
    final camsBloc = context.read<CamsPlaybackBloc>();
    final notificationService = context.read<PlaybackNotificationService>();
    final store = session.currentStore;
    final space = session.currentSpace;

    if (store == null || space == null) {
      _hydratedPlaylistId = null;
      _stopManagerProgressTicker();
      _resetManagerWarmup();
      _stopExpectedEndWatcher();
      playerBloc.add(const PlayerContextCleared());
      camsBloc.add(const CamsDisposePlayback());
      unawaited(notificationService.clear());
      return;
    }

    if (playerBloc.state.activeSpaceId != space.id) {
      _hydratedPlaylistId = null;
      _resetManagerWarmup();
      _stopExpectedEndWatcher();
    }

    playerBloc.add(PlayerContextUpdated(
      storeId: store.id,
      spaceId: space.id,
      spaceName: space.name,
    ));
    camsBloc.add(CamsInitPlayback(spaceId: space.id));
    _syncManagerProgressTicker(
      session: session,
      playbackState: camsBloc.state.playbackState,
    );
  }

  void _syncNotification({
    required SessionState session,
    required PlayerState playerState,
  }) {
    final shouldEnable = session.isPlaybackDevice &&
        session.currentStore != null &&
        session.currentSpace != null;

    context.read<PlaybackNotificationService>().syncPlayerState(
          playerState,
          enabled: shouldEnable,
        );
  }

  void _syncCamsState(CamsPlaybackState camsState) {
    final playbackState = camsState.playbackState;
    final playerBloc = context.read<PlayerBloc>();
    final session = context.read<SessionCubit>().state;

    _syncManagerProgressTicker(
      session: session,
      playbackState: playbackState,
    );
    _syncExpectedEndWatcher(
      session: session,
      playbackState: playbackState,
    );

    if (playbackState == null) {
      return;
    }

    if (!camsState.isStreaming ||
        playbackState.hlsUrl == null ||
        playbackState.hlsUrl!.isEmpty) {
      final shouldStopPlayer = !playbackState.hasPendingPlaylist &&
          (playbackState.currentPlaylistId == null ||
              playbackState.currentPlaylistId!.isEmpty);
      if (!shouldStopPlayer) {
        return;
      }
      _hydratedPlaylistId = null;
      playerBloc.add(const PlayerHlsStopped());
      return;
    }

    _hydrateQueueForPlayback(playbackState.currentPlaylistId);

    playerBloc.add(PlayerHlsStarted(
      hlsUrl: playbackState.hlsUrl!,
      playlistId: playbackState.currentPlaylistId,
      playlistName: playbackState.currentPlaylistName ?? playbackState.moodName,
      seekOffsetSeconds: playbackState.effectiveSeekOffset,
      isPaused: playbackState.isPaused,
      playLocally: session.isPlaybackDevice,
    ));

    if (!session.isPlaybackDevice) {
      _pushManagerPositionSnapshot(playbackState);
    }
  }

  Future<void> _hydrateQueueForPlayback(String? playlistId) async {
    if (!mounted || playlistId == null || playlistId.isEmpty) return;
    if (_hydratedPlaylistId == playlistId) return;

    try {
      final playlist =
          await sl<PlaylistRemoteDataSource>().getPlaylistById(playlistId);
      if (!mounted) return;

      final queue = buildPlaylistQueue(playlist);

      _hydratedPlaylistId = playlistId;
      final playerBloc = context.read<PlayerBloc>();
      playerBloc.add(PlayerQueueSeeded(
        tracks: queue,
        playlistName: playlist.name,
        playlistId: playlist.id,
        force: true,
      ));
      final playbackState =
          context.read<CamsPlaybackBloc>().state.playbackState;
      if (playbackState != null &&
          playbackState.currentPlaylistId == playlistId) {
        playerBloc.add(PlayerPositionUpdated(
          positionSeconds: _snapshotPositionSeconds(playbackState),
        ));
      }
    } catch (error) {
      debugPrint(
        '[AppPlaybackCoordinator] Failed to hydrate playlist $playlistId: $error',
      );
      // Keep the synthetic track fallback if playlist detail hydration fails.
    }
  }

  void _syncManagerProgressTicker({
    required SessionState session,
    required SpacePlaybackState? playbackState,
  }) {
    if (session.isPlaybackDevice ||
        playbackState == null ||
        !playbackState.isStreaming) {
      _stopManagerProgressTicker();
      _resetManagerWarmup();
      return;
    }

    _updateManagerWarmup(playbackState);
    _pushManagerPositionSnapshot(playbackState);

    if (playbackState.isPaused) {
      _stopManagerProgressTicker();
      _resetManagerWarmup();
      return;
    }

    _managerProgressTicker?.cancel();
    _managerProgressTicker =
        Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;

      final currentSession = context.read<SessionCubit>().state;
      final currentPlaybackState =
          context.read<CamsPlaybackBloc>().state.playbackState;
      if (currentSession.isPlaybackDevice ||
          currentPlaybackState == null ||
          !currentPlaybackState.isStreaming ||
          currentPlaybackState.isPaused) {
        _stopManagerProgressTicker();
        return;
      }

      _pushManagerPositionSnapshot(currentPlaybackState);
    });
  }

  void _pushManagerPositionSnapshot(SpacePlaybackState playbackState) {
    if (!mounted) return;

    context.read<PlayerBloc>().add(
          PlayerPositionUpdated(
            positionSeconds: _snapshotPositionSeconds(playbackState),
          ),
        );
  }

  int _snapshotPositionSeconds(SpacePlaybackState playbackState) {
    var effectiveSeekOffset = playbackState.effectiveSeekOffset;
    if (!playbackState.isPaused && _isManagerWarmupActive(playbackState)) {
      effectiveSeekOffset =
          (effectiveSeekOffset - _managerWarmupCompensationSeconds)
              .clamp(0.0, double.infinity);
    }
    return effectiveSeekOffset.floor();
  }

  void _stopManagerProgressTicker() {
    _managerProgressTicker?.cancel();
    _managerProgressTicker = null;
  }

  void _resetManagerWarmup() {
    _managerWarmupSignature = null;
    _managerWarmupUntilUtc = null;
  }

  String _streamWarmupSignature(SpacePlaybackState playbackState) {
    return [
      playbackState.spaceId.toLowerCase(),
      playbackState.currentPlaylistId ?? '',
      playbackState.hlsUrl ?? '',
      playbackState.startedAtUtc?.toUtc().toIso8601String() ?? '',
    ].join('|');
  }

  void _updateManagerWarmup(SpacePlaybackState playbackState) {
    if (playbackState.isPaused) {
      _managerWarmupUntilUtc = null;
      return;
    }

    final signature = _streamWarmupSignature(playbackState);
    if (_managerWarmupSignature != signature) {
      _managerWarmupSignature = signature;
      if (playbackState.effectiveSeekOffset <= 6) {
        _managerWarmupUntilUtc =
            DateTime.now().toUtc().add(_managerWarmupDuration);
      } else {
        _managerWarmupUntilUtc = null;
      }
    }
  }

  bool _isManagerWarmupActive(SpacePlaybackState playbackState) {
    final warmupUntilUtc = _managerWarmupUntilUtc;
    if (warmupUntilUtc == null) return false;
    if (_managerWarmupSignature != _streamWarmupSignature(playbackState)) {
      return false;
    }
    final isActive = DateTime.now().toUtc().isBefore(warmupUntilUtc);
    if (!isActive) {
      _managerWarmupUntilUtc = null;
    }
    return isActive;
  }

  void _syncExpectedEndWatcher({
    required SessionState session,
    required SpacePlaybackState? playbackState,
  }) {
    if (session.currentSpace == null ||
        playbackState == null ||
        !playbackState.isStreaming ||
        playbackState.isPaused ||
        playbackState.expectedEndAtUtc == null) {
      _stopExpectedEndWatcher();
      return;
    }

    final expectedEndUtc = playbackState.expectedEndAtUtc!.toUtc();
    final signature = [
      playbackState.spaceId.toLowerCase(),
      playbackState.currentPlaylistId ?? '',
      playbackState.hlsUrl ?? '',
      expectedEndUtc.toIso8601String(),
    ].join('|');

    if (_expectedEndSignature == signature && _expectedEndTimer != null) {
      return;
    }

    _expectedEndSignature = signature;
    _expectedEndTimer?.cancel();

    final delay = expectedEndUtc.difference(DateTime.now().toUtc());
    if (delay <= Duration.zero) {
      _handleExpectedEndReached(
        watchedSpaceId: playbackState.spaceId,
        watchedPlaylistId: playbackState.currentPlaylistId,
        watchedHlsUrl: playbackState.hlsUrl,
      );
      return;
    }

    _expectedEndTimer = Timer(delay, () {
      if (!mounted) return;
      _handleExpectedEndReached(
        watchedSpaceId: playbackState.spaceId,
        watchedPlaylistId: playbackState.currentPlaylistId,
        watchedHlsUrl: playbackState.hlsUrl,
      );
    });
  }

  void _handleExpectedEndReached({
    required String watchedSpaceId,
    required String? watchedPlaylistId,
    required String? watchedHlsUrl,
  }) {
    if (!mounted) return;

    final camsBloc = context.read<CamsPlaybackBloc>();
    final activePlayback = camsBloc.state.playbackState;
    if (activePlayback == null || !activePlayback.isStreaming) {
      _stopExpectedEndWatcher();
      return;
    }

    final activeSpaceId = activePlayback.spaceId.toLowerCase();
    if (activeSpaceId != watchedSpaceId.toLowerCase()) {
      _stopExpectedEndWatcher();
      return;
    }
    if ((activePlayback.currentPlaylistId ?? '') != (watchedPlaylistId ?? '')) {
      _stopExpectedEndWatcher();
      return;
    }
    if ((activePlayback.hlsUrl ?? '') != (watchedHlsUrl ?? '')) {
      _stopExpectedEndWatcher();
      return;
    }

    final expectedEndUtc = activePlayback.expectedEndAtUtc?.toUtc();
    if (expectedEndUtc == null ||
        DateTime.now().toUtc().isBefore(
              expectedEndUtc.subtract(const Duration(seconds: 1)),
            )) {
      _syncExpectedEndWatcher(
        session: context.read<SessionCubit>().state,
        playbackState: activePlayback,
      );
      return;
    }

    // Do not force-stop local player from the timer alone because backend
    // ExpectedEndAtUtc can drift around pause/resume. Reconcile from server state.
    camsBloc.add(const CamsRefreshState(silent: true));
    _stopExpectedEndWatcher();
  }

  void _stopExpectedEndWatcher() {
    _expectedEndTimer?.cancel();
    _expectedEndTimer = null;
    _expectedEndSignature = null;
  }

  void _handleNotificationCommand(PlaybackNotificationCommand command) {
    if (!mounted) return;

    final session = context.read<SessionCubit>().state;
    if (!session.isPlaybackDevice) return;

    final playerBloc = context.read<PlayerBloc>();
    final playerState = playerBloc.state;
    final camsBloc = context.read<CamsPlaybackBloc>();
    final canRouteToCams =
        playerState.isHlsMode && session.currentSpace != null;

    if (canRouteToCams) {
      switch (command) {
        case PlaybackNotificationCommand.play:
          if (!playerState.isPlaying) {
            playerBloc.add(const PlayerRemoteCommandApplied(
              command: PlaybackCommandEnum.resume,
              playLocally: true,
            ));
            camsBloc.add(const CamsSendCommand(
              command: PlaybackCommandEnum.resume,
            ));
          }
          return;
        case PlaybackNotificationCommand.pause:
          if (playerState.isPlaying) {
            playerBloc.add(const PlayerRemoteCommandApplied(
              command: PlaybackCommandEnum.pause,
              playLocally: true,
            ));
            camsBloc.add(const CamsSendCommand(
              command: PlaybackCommandEnum.pause,
            ));
          }
          return;
        case PlaybackNotificationCommand.skipNext:
          if (session.isPlaybackDevice && playerState.hasNext) {
            final nextTrackIndex = playerState.currentIndex + 1;
            playerBloc.add(PlayerRemoteCommandApplied(
              command: PlaybackCommandEnum.skipNext,
              positionSeconds:
                  playerState.offsetForIndex(nextTrackIndex).toDouble(),
              targetTrackId: playerState.queue[nextTrackIndex].id,
              playLocally: true,
            ));
          }
          camsBloc.add(const CamsSendCommand(
            command: PlaybackCommandEnum.skipNext,
          ));
          return;
      }
    }

    switch (command) {
      case PlaybackNotificationCommand.play:
        if (!playerState.isPlaying) {
          playerBloc.add(const PlayerPlayPauseToggled());
        }
        return;
      case PlaybackNotificationCommand.pause:
        if (playerState.isPlaying) {
          playerBloc.add(const PlayerPlayPauseToggled());
        }
        return;
      case PlaybackNotificationCommand.skipNext:
        playerBloc.add(const PlayerSkipRequested());
        return;
    }
  }

  @override
  void dispose() {
    _notificationCommandSub?.cancel();
    _stopManagerProgressTicker();
    _stopExpectedEndWatcher();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SessionCubit, SessionState>(
          listenWhen: (previous, current) =>
              previous.currentStore?.id != current.currentStore?.id ||
              previous.currentSpace?.id != current.currentSpace?.id ||
              previous.appMode != current.appMode ||
              previous.currentRole != current.currentRole,
          listener: (context, session) {
            _syncSession(session);
            _syncNotification(
              session: session,
              playerState: context.read<PlayerBloc>().state,
            );
          },
        ),
        BlocListener<CamsPlaybackBloc, CamsPlaybackState>(
          listenWhen: (previous, current) {
            final previousPlayback = previous.playbackState;
            final currentPlayback = current.playbackState;
            return previous.isStreaming != current.isStreaming ||
                previousPlayback?.hlsUrl != currentPlayback?.hlsUrl ||
                previousPlayback?.currentPlaylistId !=
                    currentPlayback?.currentPlaylistId ||
                previousPlayback?.currentPlaylistName !=
                    currentPlayback?.currentPlaylistName ||
                previousPlayback?.isPaused != currentPlayback?.isPaused ||
                previousPlayback?.pausePositionSeconds !=
                    currentPlayback?.pausePositionSeconds ||
                previousPlayback?.seekOffsetSeconds !=
                    currentPlayback?.seekOffsetSeconds ||
                previousPlayback?.startedAtUtc !=
                    currentPlayback?.startedAtUtc ||
                previousPlayback?.pendingPlaylistId !=
                    currentPlayback?.pendingPlaylistId ||
                previous.status != current.status;
          },
          listener: (context, camsState) => _syncCamsState(camsState),
        ),
        BlocListener<CamsPlaybackBloc, CamsPlaybackState>(
          listenWhen: (previous, current) =>
              previous.commandSequence != current.commandSequence &&
              current.lastPlaybackCommand != null,
          listener: (context, camsState) {
            final session = context.read<SessionCubit>().state;
            context.read<PlayerBloc>().add(PlayerRemoteCommandApplied(
                  command: camsState.lastPlaybackCommand!,
                  positionSeconds: camsState.lastSeekPositionSeconds,
                  targetTrackId: camsState.lastTargetTrackId,
                  playLocally: session.isPlaybackDevice,
                ));
          },
        ),
        BlocListener<PlayerBloc, PlayerState>(
          listenWhen: (previous, current) => previous != current,
          listener: (context, playerState) {
            _syncNotification(
              session: context.read<SessionCubit>().state,
              playerState: playerState,
            );
          },
        ),
      ],
      child: widget.child,
    );
  }
}
