import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/cams/presentation/bloc/cams_playback_bloc.dart';
import '../../features/cams/presentation/bloc/cams_playback_event.dart';
import '../../features/cams/presentation/bloc/cams_playback_state.dart';
import '../player/player_bloc.dart';
import '../player/player_event.dart';
import '../session/session_cubit.dart';
import '../session/session_state.dart';

/// Keeps Session, CAMS and the global PlayerBloc synchronized app-wide.
class AppPlaybackCoordinator extends StatefulWidget {
  const AppPlaybackCoordinator({super.key, required this.child});

  final Widget child;

  @override
  State<AppPlaybackCoordinator> createState() => _AppPlaybackCoordinatorState();
}

class _AppPlaybackCoordinatorState extends State<AppPlaybackCoordinator> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncSession(context.read<SessionCubit>().state);
    });
  }

  void _syncSession(SessionState session) {
    final playerBloc = context.read<PlayerBloc>();
    final camsBloc = context.read<CamsPlaybackBloc>();
    final store = session.currentStore;
    final space = session.currentSpace;

    if (store == null || space == null) {
      playerBloc.add(const PlayerContextCleared());
      camsBloc.add(const CamsDisposePlayback());
      return;
    }

    playerBloc.add(PlayerContextUpdated(
      storeId: store.id,
      spaceId: space.id,
      spaceName: space.name,
    ));
    camsBloc.add(CamsInitPlayback(spaceId: space.id));
  }

  void _syncCamsState(CamsPlaybackState camsState) {
    final playbackState = camsState.playbackState;
    final playerBloc = context.read<PlayerBloc>();
    final session = context.read<SessionCubit>().state;

    if (playbackState == null ||
        !camsState.isStreaming ||
        playbackState.hlsUrl == null ||
        playbackState.hlsUrl!.isEmpty) {
      playerBloc.add(const PlayerHlsStopped());
      return;
    }

    playerBloc.add(PlayerHlsStarted(
      hlsUrl: playbackState.hlsUrl!,
      playlistId: playbackState.currentPlaylistId,
      playlistName: playbackState.currentPlaylistName ?? playbackState.moodName,
      seekOffsetSeconds: playbackState.seekOffsetSeconds ?? 0,
      playLocally: session.isPlaybackDevice,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SessionCubit, SessionState>(
          listenWhen: (previous, current) =>
              previous.currentStore?.id != current.currentStore?.id ||
              previous.currentSpace?.id != current.currentSpace?.id ||
              previous.appMode != current.appMode,
          listener: (context, session) => _syncSession(session),
        ),
        BlocListener<CamsPlaybackBloc, CamsPlaybackState>(
          listenWhen: (previous, current) {
            final previousPlayback = previous.playbackState;
            final currentPlayback = current.playbackState;
            return previous.isStreaming != current.isStreaming ||
                previousPlayback?.hlsUrl != currentPlayback?.hlsUrl ||
                previousPlayback?.currentPlaylistId !=
                    currentPlayback?.currentPlaylistId ||
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
      ],
      child: widget.child,
    );
  }
}
