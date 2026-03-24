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
  Timer? _playbackHealthTicker;
  String? _expectedEndSignature;
  String? _managerWarmupSignature;
  String? _playbackHealthSignature;
  DateTime? _managerWarmupUntilUtc;
  DateTime? _lastHealthyHlsAtUtc;
  DateTime? _hlsStallGraceUntilUtc;
  DateTime? _lastHlsRecoveryAttemptAtUtc;
  int? _lastHealthyHlsPositionSeconds;
  bool _hlsRefreshIssuedForCurrentStall = false;
  static const Duration _managerWarmupDuration = Duration(seconds: 4);
  static const double _managerWarmupCompensationSeconds = 2;
  static const Duration _playbackHealthTickInterval = Duration(seconds: 2);
  static const Duration _hlsStallThreshold = Duration(seconds: 8);
  static const Duration _hlsReloadThreshold = Duration(seconds: 16);
  static const Duration _hlsRecoveryCooldown = Duration(seconds: 10);
  static const Duration _hlsStartupGrace = Duration(seconds: 12);

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
      _stopPlaybackHealthTicker();
      playerBloc.add(const PlayerContextCleared());
      camsBloc.add(const CamsDisposePlayback());
      unawaited(notificationService.clear());
      return;
    }

    if (playerBloc.state.activeSpaceId != space.id) {
      _hydratedPlaylistId = null;
      _resetManagerWarmup();
      _stopExpectedEndWatcher();
      _resetPlaybackHealthTracking();
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
    _syncPlaybackHealthTicker(
      session: session,
      camsState: camsBloc.state,
      playerState: playerBloc.state,
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
    _syncPlaybackHealthTicker(
      session: session,
      camsState: camsState,
      playerState: playerBloc.state,
    );

    if (playbackState == null) {
      return;
    }

    if (!camsState.isStreaming ||
        playbackState.hlsUrl == null ||
        playbackState.hlsUrl!.isEmpty) {
      final hasQueueIdentity =
          (playbackState.currentQueueItemId?.isNotEmpty ?? false) ||
              ((_resolveCurrentTrackId(playbackState)?.isNotEmpty ?? false));
      final hasLegacyPlaylistIdentity = playbackState.spaceQueueItems.isEmpty &&
          (playbackState.currentPlaylistId?.isNotEmpty ?? false);
      final shouldStopPlayer = !playbackState.hasPendingPlayback &&
          !hasQueueIdentity &&
          !hasLegacyPlaylistIdentity;
      if (!shouldStopPlayer) {
        return;
      }
      _hydratedPlaylistId = null;
      _stopPlaybackHealthTicker();
      playerBloc.add(const PlayerHlsStopped());
      return;
    }

    unawaited(_hydrateQueueForPlayback(playbackState));

    final legacyPlaylistId = playbackState.spaceQueueItems.isEmpty
        ? playbackState.currentPlaylistId
        : null;

    playerBloc.add(PlayerHlsStarted(
      hlsUrl: playbackState.hlsUrl!,
      playlistId: legacyPlaylistId,
      playlistName: playbackState.currentDisplayName,
      queueItemId: playbackState.currentQueueItemId,
      trackId: _resolveCurrentTrackId(playbackState),
      trackName: playbackState.currentTrackName,
      seekOffsetSeconds: playbackState.effectiveSeekOffset,
      isPaused: playbackState.isPaused,
      playLocally: session.isPlaybackDevice,
    ));

    playerBloc.add(PlayerAudioSettingsApplied(
      volumePercent: playbackState.volumePercent,
      isMuted: playbackState.isMuted,
    ));

    if (!session.isPlaybackDevice) {
      _pushManagerPositionSnapshot(playbackState);
    }
  }

  String? _resolveCurrentTrackId(SpacePlaybackState playbackState) {
    final queueItemId = playbackState.currentQueueItemId;
    if (queueItemId != null && queueItemId.isNotEmpty) {
      for (final queueItem in playbackState.spaceQueueItems) {
        if (queueItem.queueItemId == queueItemId) {
          return queueItem.trackId;
        }
      }
    }

    for (final queueItem in playbackState.spaceQueueItems) {
      if (queueItem.queueStatus == 1) {
        return queueItem.trackId;
      }
    }

    return null;
  }

  Future<void> _hydrateQueueForPlayback(
      SpacePlaybackState playbackState) async {
    if (!mounted) return;

    final queueItems = playbackState.spaceQueueItems;
    if (queueItems.isNotEmpty) {
      final signature = [
        playbackState.spaceId,
        playbackState.currentQueueItemId ?? '',
        ...queueItems.map((item) => item.queueItemId),
      ].join('|');

      if (_hydratedPlaylistId != signature) {
        _hydratedPlaylistId = signature;
        final playerBloc = context.read<PlayerBloc>();
        final queue = buildSpaceQueue(queueItems);
        playerBloc.add(PlayerQueueSeeded(
          tracks: queue,
          playlistName: playbackState.currentDisplayName,
          playlistId: null,
          force: true,
        ));
      }

      final currentTrackId = _resolveCurrentTrackId(playbackState);
      if (currentTrackId != null) {
        context.read<PlayerBloc>().add(PlayerRemoteCommandApplied(
              command: PlaybackCommandEnum.skipToTrack,
              targetTrackId: currentTrackId,
              playLocally: false,
            ));
      }

      return;
    }

    final playlistId = playbackState.currentPlaylistId;
    if (playlistId == null || playlistId.isEmpty) return;
    final legacySignature = 'playlist:$playlistId';
    if (_hydratedPlaylistId == legacySignature) return;

    try {
      final playlist =
          await sl<PlaylistRemoteDataSource>().getPlaylistById(playlistId);
      if (!mounted) return;

      final queue = buildPlaylistQueue(playlist);

      _hydratedPlaylistId = legacySignature;
      final playerBloc = context.read<PlayerBloc>();
      playerBloc.add(PlayerQueueSeeded(
        tracks: queue,
        playlistName: playlist.name,
        playlistId: playlist.id,
        force: true,
      ));
      final currentPlaybackState =
          context.read<CamsPlaybackBloc>().state.playbackState;
      if (currentPlaybackState != null &&
          currentPlaybackState.currentPlaylistId == playlistId) {
        playerBloc.add(PlayerPositionUpdated(
          positionSeconds: _snapshotPositionSeconds(currentPlaybackState),
        ));
      }
    } catch (error) {
      debugPrint(
        '[AppPlaybackCoordinator] Failed to hydrate playlist $playlistId: $error',
      );
      // Keep synthetic fallback if hydration fails.
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
      playbackState.currentIdentityId ?? '',
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
      playbackState.currentIdentityId ?? '',
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
        watchedIdentityId: playbackState.currentIdentityId,
        watchedHlsUrl: playbackState.hlsUrl,
      );
      return;
    }

    _expectedEndTimer = Timer(delay, () {
      if (!mounted) return;
      _handleExpectedEndReached(
        watchedSpaceId: playbackState.spaceId,
        watchedIdentityId: playbackState.currentIdentityId,
        watchedHlsUrl: playbackState.hlsUrl,
      );
    });
  }

  void _handleExpectedEndReached({
    required String watchedSpaceId,
    required String? watchedIdentityId,
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
    if ((activePlayback.currentIdentityId ?? '') != (watchedIdentityId ?? '')) {
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

  String _playbackHealthSignatureFor(SpacePlaybackState playbackState) {
    return [
      playbackState.spaceId.toLowerCase(),
      playbackState.currentIdentityId ?? '',
      playbackState.hlsUrl ?? '',
      playbackState.startedAtUtc?.toUtc().toIso8601String() ?? '',
    ].join('|');
  }

  void _resetPlaybackHealthTracking() {
    _playbackHealthSignature = null;
    _lastHealthyHlsAtUtc = null;
    _hlsStallGraceUntilUtc = null;
    _lastHlsRecoveryAttemptAtUtc = null;
    _lastHealthyHlsPositionSeconds = null;
    _hlsRefreshIssuedForCurrentStall = false;
  }

  void _stopPlaybackHealthTicker() {
    _playbackHealthTicker?.cancel();
    _playbackHealthTicker = null;
    _resetPlaybackHealthTracking();
  }

  void _syncPlaybackHealthTicker({
    required SessionState session,
    required CamsPlaybackState camsState,
    required PlayerState playerState,
  }) {
    final playbackState = camsState.playbackState;
    final shouldMonitor = session.isPlaybackDevice &&
        session.currentSpace != null &&
        playbackState != null &&
        playbackState.isStreaming &&
        !playbackState.isPaused &&
        (playbackState.hlsUrl?.isNotEmpty ?? false);

    if (!shouldMonitor) {
      _stopPlaybackHealthTicker();
      return;
    }

    final nowUtc = DateTime.now().toUtc();
    final signature = _playbackHealthSignatureFor(playbackState);
    if (_playbackHealthSignature != signature) {
      _playbackHealthSignature = signature;
      _lastHealthyHlsPositionSeconds = playerState.currentPosition;
      _lastHealthyHlsAtUtc = nowUtc;
      _hlsStallGraceUntilUtc = nowUtc.add(_hlsStartupGrace);
      _hlsRefreshIssuedForCurrentStall = false;
      _lastHlsRecoveryAttemptAtUtc = null;
    }

    _playbackHealthTicker ??= Timer.periodic(
      _playbackHealthTickInterval,
      (_) => _checkPlaybackHealthTick(),
    );
  }

  void _checkPlaybackHealthTick() {
    if (!mounted) return;

    final session = context.read<SessionCubit>().state;
    final camsBloc = context.read<CamsPlaybackBloc>();
    final playerBloc = context.read<PlayerBloc>();
    final camsState = camsBloc.state;
    final playbackState = camsState.playbackState;
    final playerState = playerBloc.state;

    if (!session.isPlaybackDevice ||
        session.currentSpace == null ||
        playbackState == null ||
        !playbackState.isStreaming ||
        playbackState.isPaused ||
        playbackState.hlsUrl == null ||
        playbackState.hlsUrl!.isEmpty) {
      _stopPlaybackHealthTicker();
      return;
    }

    final signature = _playbackHealthSignatureFor(playbackState);
    if (_playbackHealthSignature != signature) {
      _syncPlaybackHealthTicker(
        session: session,
        camsState: camsState,
        playerState: playerState,
      );
      return;
    }

    final nowUtc = DateTime.now().toUtc();
    final graceUntilUtc = _hlsStallGraceUntilUtc;
    if (graceUntilUtc != null && nowUtc.isBefore(graceUntilUtc)) {
      _lastHealthyHlsPositionSeconds = playerState.currentPosition;
      _lastHealthyHlsAtUtc = nowUtc;
      return;
    }

    // Skip health checks until local player has finished syncing this stream.
    if (!playerState.isSyncedCamsPlayback ||
        playerState.hlsUrl != playbackState.hlsUrl) {
      return;
    }

    final currentPosition = playerState.currentPosition;
    final previousPosition = _lastHealthyHlsPositionSeconds;
    if (previousPosition == null || currentPosition > previousPosition) {
      _lastHealthyHlsPositionSeconds = currentPosition;
      _lastHealthyHlsAtUtc = nowUtc;
      _hlsRefreshIssuedForCurrentStall = false;
      return;
    }

    final lastHealthyAtUtc = _lastHealthyHlsAtUtc ?? nowUtc;
    final stallDuration = nowUtc.difference(lastHealthyAtUtc);
    final canAttemptRecovery = _lastHlsRecoveryAttemptAtUtc == null ||
        nowUtc.difference(_lastHlsRecoveryAttemptAtUtc!) >=
            _hlsRecoveryCooldown;

    if (stallDuration >= _hlsReloadThreshold &&
        _hlsRefreshIssuedForCurrentStall &&
        canAttemptRecovery) {
      _lastHlsRecoveryAttemptAtUtc = nowUtc;
      _hlsRefreshIssuedForCurrentStall = false;
      final legacyPlaylistId = playbackState.spaceQueueItems.isEmpty
          ? playbackState.currentPlaylistId
          : null;
      playerBloc.add(PlayerHlsStarted(
        hlsUrl: playbackState.hlsUrl!,
        playlistId: legacyPlaylistId,
        playlistName: playbackState.currentDisplayName,
        queueItemId: playbackState.currentQueueItemId,
        trackId: _resolveCurrentTrackId(playbackState),
        trackName: playbackState.currentTrackName,
        seekOffsetSeconds: playbackState.effectiveSeekOffset,
        isPaused: playbackState.isPaused,
        playLocally: true,
        forceReload: true,
      ));
      camsBloc.add(const CamsRefreshState(silent: true));
      return;
    }

    if (stallDuration >= _hlsStallThreshold &&
        !_hlsRefreshIssuedForCurrentStall &&
        canAttemptRecovery) {
      _lastHlsRecoveryAttemptAtUtc = nowUtc;
      _hlsRefreshIssuedForCurrentStall = true;
      camsBloc.add(const CamsRefreshState(silent: true));
    }
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
    _stopPlaybackHealthTicker();
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
            _syncPlaybackHealthTicker(
              session: session,
              camsState: context.read<CamsPlaybackBloc>().state,
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
                previousPlayback?.currentQueueItemId !=
                    currentPlayback?.currentQueueItemId ||
                previousPlayback?.currentTrackName !=
                    currentPlayback?.currentTrackName ||
                previousPlayback?.isPaused != currentPlayback?.isPaused ||
                previousPlayback?.pausePositionSeconds !=
                    currentPlayback?.pausePositionSeconds ||
                previousPlayback?.seekOffsetSeconds !=
                    currentPlayback?.seekOffsetSeconds ||
                previousPlayback?.startedAtUtc !=
                    currentPlayback?.startedAtUtc ||
                previousPlayback?.pendingQueueItemId !=
                    currentPlayback?.pendingQueueItemId ||
                previousPlayback?.volumePercent !=
                    currentPlayback?.volumePercent ||
                previousPlayback?.isMuted != currentPlayback?.isMuted ||
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
          listenWhen: (previous, current) =>
              previous.hlsCompletionSequence != current.hlsCompletionSequence,
          listener: (context, playerState) {
            final session = context.read<SessionCubit>().state;
            final camsState = context.read<CamsPlaybackBloc>().state;
            if (!session.isPlaybackDevice ||
                !playerState.isSyncedCamsPlayback ||
                !camsState.isStreaming) {
              return;
            }
            context.read<CamsPlaybackBloc>().add(
                  const CamsSendCommand(
                    command: PlaybackCommandEnum.trackEnded,
                  ),
                );
          },
        ),
        BlocListener<PlayerBloc, PlayerState>(
          listenWhen: (previous, current) => previous != current,
          listener: (context, playerState) {
            _syncNotification(
              session: context.read<SessionCubit>().state,
              playerState: playerState,
            );
            _syncPlaybackHealthTicker(
              session: context.read<SessionCubit>().state,
              camsState: context.read<CamsPlaybackBloc>().state,
              playerState: playerState,
            );
          },
        ),
      ],
      child: widget.child,
    );
  }
}
