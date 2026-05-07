import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../enums/queue_insert_mode_enum.dart';
import '../session/session_cubit.dart';
import '../widgets/queue_mode_picker_bottom_sheet.dart';
import '../../features/cams/presentation/bloc/cams_playback_bloc.dart';
import '../../features/cams/presentation/bloc/cams_playback_event.dart';

String buildQueueActionReason({
  required String source,
  required String itemType,
  required QueueInsertModeEnum mode,
}) {
  final actionLabel = switch (mode) {
    QueueInsertModeEnum.playNow => 'play-now',
    QueueInsertModeEnum.playNext => 'play-next',
    QueueInsertModeEnum.addToQueue => 'add-to-queue',
  };
  return '$source $itemType $actionLabel request';
}

bool ensureQueueTargetSelected(
  BuildContext context, {
  String message = 'Select a space first to send music to the live queue.',
}) {
  final spaceId = context.read<SessionCubit>().state.currentSpace?.id;
  if (spaceId != null && spaceId.isNotEmpty) {
    return true;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
  return false;
}

bool ensurePlaybackQueueIsAvailable(BuildContext context) {
  final camsState = context.read<CamsPlaybackBloc>().state;
  if (!camsState.isBrandPlaybackBlocked &&
      !camsState.isPlaybackMutationBlocked) {
    return true;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        camsState.playbackMutationBlockedMessage ??
            camsState.playbackBlockedMessage ??
            'Playback is unavailable because the brand wallet needs attention.',
      ),
    ),
  );
  return false;
}

void queueTrackToCurrentSpace(
  BuildContext context, {
  required String trackId,
  String? playlistId,
  required QueueInsertModeEnum mode,
  required String reason,
}) {
  if (!ensureQueueTargetSelected(context)) return;
  if (!ensurePlaybackQueueIsAvailable(context)) return;

  final session = context.read<SessionCubit>().state;
  final spaceId = session.currentSpace!.id;
  final camsBloc = context.read<CamsPlaybackBloc>();
  if (camsBloc.state.spaceId != spaceId) {
    camsBloc.add(CamsInitPlayback(spaceId: spaceId));
  }
  camsBloc.add(CamsPlayTrack(
    trackId: trackId,
    playlistId: playlistId,
    reason: reason,
    clearExistingQueue: mode == QueueInsertModeEnum.playNow,
    requestedMode: mode,
  ));
}

Future<void> showTrackQueueModePickerAndQueue(
  BuildContext context, {
  required String trackId,
  String? playlistId,
  required String title,
  required String source,
}) async {
  if (!ensureQueueTargetSelected(context)) return;
  if (!ensurePlaybackQueueIsAvailable(context)) return;

  final mode = await showQueueModePickerBottomSheet(
    context,
    title: 'Add track to queue',
    subtitle: title,
  );
  if (!context.mounted || mode == null) return;

  queueTrackToCurrentSpace(
    context,
    trackId: trackId,
    playlistId: playlistId,
    mode: mode,
    reason: buildQueueActionReason(
      source: source,
      itemType: 'track',
      mode: mode,
    ),
  );
}

void queuePlaylistToCurrentSpace(
  BuildContext context, {
  required String playlistId,
  required QueueInsertModeEnum mode,
  required String reason,
}) {
  if (!ensureQueueTargetSelected(context)) return;
  if (!ensurePlaybackQueueIsAvailable(context)) return;

  final session = context.read<SessionCubit>().state;
  final spaceId = session.currentSpace!.id;
  final camsBloc = context.read<CamsPlaybackBloc>();
  if (camsBloc.state.spaceId != spaceId) {
    camsBloc.add(CamsInitPlayback(spaceId: spaceId));
  }
  camsBloc.add(CamsPlayPlaylist(
    playlistId: playlistId,
    reason: reason,
    clearExistingQueue: mode == QueueInsertModeEnum.playNow,
    requestedMode: mode,
  ));
}
