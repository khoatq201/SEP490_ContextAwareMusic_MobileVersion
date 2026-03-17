import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../audio/playback_notification_service.dart';
import '../enums/playback_command_enum.dart';
import '../../features/playlists/data/datasources/playlist_remote_datasource.dart';
import '../../features/cams/presentation/bloc/cams_playback_bloc.dart';
import '../../features/cams/presentation/bloc/cams_playback_event.dart';
import '../../features/cams/presentation/bloc/cams_playback_state.dart';
import '../../features/space_control/domain/entities/track.dart';
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
      playerBloc.add(const PlayerContextCleared());
      camsBloc.add(const CamsDisposePlayback());
      unawaited(notificationService.clear());
      return;
    }

    if (playerBloc.state.activeSpaceId != space.id) {
      _hydratedPlaylistId = null;
    }

    playerBloc.add(PlayerContextUpdated(
      storeId: store.id,
      spaceId: space.id,
      spaceName: space.name,
    ));
    camsBloc.add(CamsInitPlayback(spaceId: space.id));
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
  }

  Future<void> _hydrateQueueForPlayback(String? playlistId) async {
    if (!mounted || playlistId == null || playlistId.isEmpty) return;
    if (_hydratedPlaylistId == playlistId) return;

    try {
      final playlist =
          await sl<PlaylistRemoteDataSource>().getPlaylistById(playlistId);
      if (!mounted) return;

      final queue = (playlist.tracks ?? const [])
          .map((playlistTrack) => Track(
                id: playlistTrack.trackId,
                title: playlistTrack.title ?? 'Unknown Track',
                artist: playlistTrack.artist ?? 'Unknown Artist',
                fileUrl: '',
                moodTags: const [],
                duration: playlistTrack.effectiveDuration,
                albumArt: playlistTrack.coverImageUrl,
                seekOffsetSeconds: playlistTrack.seekOffsetSeconds,
              ))
          .toList();

      _hydratedPlaylistId = playlistId;
      context.read<PlayerBloc>().add(PlayerQueueSeeded(
            tracks: queue,
            playlistName: playlist.name,
            playlistId: playlist.id,
            force: true,
          ));
    } catch (_) {
      // Keep the synthetic track fallback if playlist detail hydration fails.
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
