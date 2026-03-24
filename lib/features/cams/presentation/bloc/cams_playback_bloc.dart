import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/playback_command_enum.dart';
import '../../../../core/enums/queue_insert_mode_enum.dart';
import '../../../../core/session/session_cubit.dart';
import '../../data/services/store_hub_service.dart';
import '../../domain/entities/space_playback_state.dart';
import '../../domain/entities/space_queue_state_item.dart';
import '../../domain/usecases/cancel_override.dart';
import '../../domain/usecases/get_space_state.dart';
import '../../domain/usecases/override_space.dart';
import '../../domain/usecases/queue_usecases.dart';
import '../../domain/usecases/send_playback_command.dart';
import '../../domain/usecases/update_audio_state.dart';
import '../../../moods/domain/usecases/get_moods.dart';
import 'cams_playback_event.dart';
import 'cams_playback_state.dart';

/// BLoC that manages CAMS playback state, SignalR integration,
/// and exposes queue-native playback controls for the UI.
class CamsPlaybackBloc extends Bloc<CamsPlaybackEvent, CamsPlaybackState> {
  final GetSpaceState getSpaceState;
  final OverrideSpace overrideSpace;
  final CancelOverride cancelOverride;
  final SendPlaybackCommand sendPlaybackCommand;
  final QueueTracks queueTracks;
  final QueuePlaylist queuePlaylist;
  final ReorderQueue reorderQueue;
  final RemoveQueueItems removeQueueItems;
  final ClearQueue clearQueue;
  final GetSpaceQueue getSpaceQueue;
  final UpdateAudioState updateAudioState;
  final GetMoods getMoods;
  final StoreHubService storeHubService;
  final SessionCubit sessionCubit;

  StreamSubscription? _playStreamSub;
  StreamSubscription? _playbackCommandSub;
  StreamSubscription? _stateSyncSub;
  StreamSubscription? _stopPlaybackSub;
  StreamSubscription? _connectionSub;
  int _silentEmptyStateStreak = 0;

  CamsPlaybackBloc({
    required this.getSpaceState,
    required this.overrideSpace,
    required this.cancelOverride,
    required this.sendPlaybackCommand,
    required this.queueTracks,
    required this.queuePlaylist,
    required this.reorderQueue,
    required this.removeQueueItems,
    required this.clearQueue,
    required this.getSpaceQueue,
    required this.updateAudioState,
    required this.getMoods,
    required this.storeHubService,
    required this.sessionCubit,
  }) : super(const CamsPlaybackState()) {
    on<CamsInitPlayback>(_onInit);
    on<CamsDisposePlayback>(_onDispose);
    on<CamsOverrideMood>(_onOverrideMood);
    on<CamsPlayPlaylist>(_onPlayPlaylist);
    on<CamsPlayTrack>(_onPlayTrack);
    on<CamsReorderQueue>(_onReorderQueue);
    on<CamsRemoveQueueItems>(_onRemoveQueueItems);
    on<CamsClearQueue>(_onClearQueue);
    on<CamsUpdateAudioState>(_onUpdateAudioState);
    on<CamsCancelOverride>(_onCancelOverride);
    on<CamsSendCommand>(_onSendCommand);
    on<CamsPlayStreamReceived>(_onPlayStream);
    on<CamsPlaybackCommandReceived>(_onPlaybackCommand);
    on<CamsStateSyncReceived>(_onStateSync);
    on<CamsStopPlaybackReceived>(_onStopPlayback);
    on<CamsRefreshState>(_onRefreshState);
    on<CamsReportPlaybackState>(_onReportPlaybackState);
  }

  Future<void> _onInit(
    CamsInitPlayback event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    final previousSpaceId = state.spaceId;
    if (previousSpaceId != null && previousSpaceId != event.spaceId) {
      try {
        await storeHubService.leaveSpace(previousSpaceId);
      } catch (_) {
        // Best effort before switching spaces.
      }
    }

    emit(state.copyWith(
      status: CamsStatus.loading,
      spaceId: event.spaceId,
      clearError: true,
      clearPendingTrackJump: true,
      clearLastCommand: true,
    ));

    // 1. Connect SignalR + join space
    try {
      await storeHubService.connect();
      await storeHubService.joinSpace(event.spaceId);
      final managerStoreId = sessionCubit.state.isPlaybackDevice
          ? null
          : sessionCubit.state.currentStore?.id;
      if (managerStoreId != null && managerStoreId.isNotEmpty) {
        await storeHubService.joinManagerRoom(managerStoreId);
      }
      emit(state.copyWith(isHubConnected: true));
    } catch (_) {
      // Non-fatal: continue without real-time updates.
    }

    // 2. Subscribe to SignalR events
    _subscribeToHub();

    // 3. Fetch initial state + moods in parallel.
    final stateFuture = getSpaceState(
      event.spaceId,
      usePlaybackDeviceScope: sessionCubit.state.isPlaybackDevice,
    );
    final moodsFuture = getMoods();
    final stateResult = await stateFuture;
    final moodsResult = await moodsFuture;

    moodsResult.fold(
      (_) {}, // Non-fatal
      (moods) => emit(state.copyWith(moods: moods)),
    );

    await stateResult.fold(
      (failure) async => emit(state.copyWith(
        status: CamsStatus.error,
        errorMessage: failure.message,
      )),
      (pbState) async {
        final normalizedState = _normalizePlaybackStateForClientClock(
          incoming: pbState,
          current: state.playbackState,
        );
        final hydratedState =
            await _hydrateQueueSnapshotIfNeeded(normalizedState);
        emit(state.copyWith(
          status:
              (hydratedState.isStreaming || hydratedState.hasPendingPlayback)
                  ? CamsStatus.active
                  : CamsStatus.idle,
          playbackState: hydratedState,
        ));
      },
    );
  }

  void _subscribeToHub() {
    _playStreamSub?.cancel();
    _playbackCommandSub?.cancel();
    _stateSyncSub?.cancel();
    _stopPlaybackSub?.cancel();
    _connectionSub?.cancel();

    _playStreamSub = storeHubService.onPlayStream.listen((event) {
      add(CamsPlayStreamReceived(
        spaceId: event.spaceId,
        hlsUrl: event.hlsUrl,
        playlistId: event.playlistId,
        currentQueueItemId: event.currentQueueItemId,
        trackId: event.trackId,
        trackName: event.trackName,
        isManualOverride: event.isManualOverride,
        startedAtUtc: event.startedAtUtc,
      ));
    });

    _playbackCommandSub = storeHubService.onPlaybackCommand.listen((event) {
      add(CamsPlaybackCommandReceived(
        spaceId: event.spaceId,
        command: event.command,
        seekPositionSeconds: event.seekPositionSeconds,
        targetTrackId: event.targetTrackId,
      ));
    });

    _stateSyncSub = storeHubService.onSpaceStateSync.listen((model) {
      add(CamsStateSyncReceived(playbackState: model));
    });

    _stopPlaybackSub = storeHubService.onStopPlayback.listen((_) {
      add(const CamsStopPlaybackReceived());
    });

    _connectionSub = storeHubService.onConnectionStatus.listen((status) {
      if (status == ConnectionStatus.connected && state.spaceId != null) {
        add(const CamsRefreshState(silent: true));
      }
    });
  }

  Future<void> _onDispose(
    CamsDisposePlayback event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    _cancelSubscriptions();
    final spaceId = state.spaceId;
    if (spaceId != null) {
      try {
        await storeHubService.leaveSpace(spaceId);
      } catch (_) {}
    }
    emit(const CamsPlaybackState());
  }

  Future<void> _onOverrideMood(
    CamsOverrideMood event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    final spaceId = state.spaceId;
    if (spaceId == null) return;

    emit(state.copyWith(isOverriding: true, clearError: true));

    final result = await overrideSpace(
      spaceId: spaceId,
      moodId: event.moodId,
      reason: event.reason,
      usePlaybackDeviceScope: sessionCubit.state.isPlaybackDevice,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isOverriding: false,
        errorMessage: 'Override failed: ${failure.message}',
      )),
      (response) {
        emit(state.copyWith(
          isOverriding: false,
          lastOverrideResponse: response,
          clearPendingTrackJump: true,
        ));
        add(const CamsRefreshState(silent: true));
      },
    );
  }

  Future<void> _onPlayPlaylist(
    CamsPlayPlaylist event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    final spaceId = state.spaceId;
    if (spaceId == null) return;

    emit(state.copyWith(isOverriding: true, clearError: true));

    final result = await queuePlaylist(
      QueuePlaylistParams(
        spaceId: spaceId,
        playlistId: event.playlistId,
        mode: QueueInsertModeEnum.playNow,
        isClearExistingQueue: event.clearExistingQueue,
        reason: event.reason ?? 'Play playlist now',
        usePlaybackDeviceScope: sessionCubit.state.isPlaybackDevice,
      ),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isOverriding: false,
        errorMessage: 'Play playlist failed: ${failure.message}',
      )),
      (_) {
        emit(state.copyWith(
          isOverriding: false,
          clearPendingTrackJump: true,
        ));
        add(const CamsRefreshState(silent: true));
      },
    );
  }

  Future<void> _onPlayTrack(
    CamsPlayTrack event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    final spaceId = state.spaceId;
    if (spaceId == null) return;

    emit(state.copyWith(isOverriding: true, clearError: true));

    final result = await queueTracks(
      QueueTracksParams(
        spaceId: spaceId,
        trackIds: [event.trackId],
        mode: QueueInsertModeEnum.playNow,
        isClearExistingQueue: event.clearExistingQueue,
        reason: event.reason ?? 'Play track now',
        usePlaybackDeviceScope: sessionCubit.state.isPlaybackDevice,
      ),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isOverriding: false,
        errorMessage: 'Play track failed: ${failure.message}',
      )),
      (_) {
        emit(state.copyWith(
          isOverriding: false,
          clearPendingTrackJump: true,
        ));
        add(const CamsRefreshState(silent: true));
      },
    );
  }

  Future<void> _onReorderQueue(
    CamsReorderQueue event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    final spaceId = state.spaceId;
    if (spaceId == null || event.queueItemIds.length < 2) return;

    final currentPlayback = state.playbackState;
    if (currentPlayback != null && currentPlayback.spaceQueueItems.isNotEmpty) {
      final reorderedQueue = _reorderQueueItemsLocally(
        currentPlayback.spaceQueueItems,
        event.queueItemIds,
      );
      final optimisticState = _copyPlaybackStateWithQueue(
        source: currentPlayback,
        queueItems: reorderedQueue,
      );
      emit(state.copyWith(
        status:
            (optimisticState.isStreaming || optimisticState.hasPendingPlayback)
                ? CamsStatus.active
                : CamsStatus.idle,
        playbackState: optimisticState,
        clearError: true,
      ));
    }

    final result = await reorderQueue(
      ReorderQueueParams(
        spaceId: spaceId,
        queueItemIds: event.queueItemIds,
        usePlaybackDeviceScope: sessionCubit.state.isPlaybackDevice,
      ),
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          errorMessage: 'Reorder queue failed: ${failure.message}',
        ));
        add(const CamsRefreshState(silent: true));
      },
      (_) => add(const CamsRefreshState(silent: true)),
    );
  }

  Future<void> _onRemoveQueueItems(
    CamsRemoveQueueItems event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    final spaceId = state.spaceId;
    if (spaceId == null || event.queueItemIds.isEmpty) return;

    final currentPlayback = state.playbackState;
    if (currentPlayback != null && currentPlayback.spaceQueueItems.isNotEmpty) {
      final removedIds = event.queueItemIds.toSet();
      final remainingQueue = currentPlayback.spaceQueueItems
          .where((item) => !removedIds.contains(item.queueItemId))
          .toList(growable: false);
      final shouldClearPendingQueueItem =
          currentPlayback.pendingQueueItemId != null &&
              removedIds.contains(currentPlayback.pendingQueueItemId);

      final optimisticState = _copyPlaybackStateWithQueue(
        source: currentPlayback,
        queueItems: _reindexQueueItems(remainingQueue),
        clearPendingQueueItemId: shouldClearPendingQueueItem,
      );
      emit(state.copyWith(
        status:
            (optimisticState.isStreaming || optimisticState.hasPendingPlayback)
                ? CamsStatus.active
                : CamsStatus.idle,
        playbackState: optimisticState,
        clearError: true,
      ));
    }

    final result = await removeQueueItems(
      RemoveQueueItemsParams(
        spaceId: spaceId,
        queueItemIds: event.queueItemIds,
        usePlaybackDeviceScope: sessionCubit.state.isPlaybackDevice,
      ),
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          errorMessage: 'Remove queue item failed: ${failure.message}',
        ));
        add(const CamsRefreshState(silent: true));
      },
      (_) => add(const CamsRefreshState(silent: true)),
    );
  }

  Future<void> _onClearQueue(
    CamsClearQueue event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    final spaceId = state.spaceId;
    if (spaceId == null) return;

    final currentPlayback = state.playbackState;
    if (currentPlayback != null && currentPlayback.spaceQueueItems.isNotEmpty) {
      final optimisticState = _copyPlaybackStateWithQueue(
        source: currentPlayback,
        queueItems: const [],
        clearPendingQueueItemId: true,
      );
      emit(state.copyWith(
        status:
            (optimisticState.isStreaming || optimisticState.hasPendingPlayback)
                ? CamsStatus.active
                : CamsStatus.idle,
        playbackState: optimisticState,
        clearError: true,
      ));
    }

    final result = await clearQueue(
      QueueScopeParams(
        spaceId: spaceId,
        usePlaybackDeviceScope: sessionCubit.state.isPlaybackDevice,
      ),
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          errorMessage: 'Clear queue failed: ${failure.message}',
        ));
        add(const CamsRefreshState(silent: true));
      },
      (_) => add(const CamsRefreshState(silent: true)),
    );
  }

  Future<void> _onUpdateAudioState(
    CamsUpdateAudioState event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    final spaceId = state.spaceId;
    if (spaceId == null || !event.hasAnyUpdate) return;

    final currentPlayback = state.playbackState;
    if (currentPlayback != null) {
      final boundedVolume =
          (event.volumePercent ?? currentPlayback.volumePercent)
              .clamp(0, 100)
              .toInt();
      final nextIsMuted = event.isMuted ?? currentPlayback.isMuted;
      final nextQueueEndBehavior =
          (event.queueEndBehavior ?? currentPlayback.queueEndBehavior)
              .clamp(0, 2)
              .toInt();
      final optimisticState = _copyPlaybackStateWithAudio(
        source: currentPlayback,
        volumePercent: boundedVolume,
        isMuted: nextIsMuted,
        queueEndBehavior: nextQueueEndBehavior,
      );

      emit(state.copyWith(
        status:
            (optimisticState.isStreaming || optimisticState.hasPendingPlayback)
                ? CamsStatus.active
                : CamsStatus.idle,
        playbackState: optimisticState,
        clearError: true,
      ));
    }

    final result = await updateAudioState(
      UpdateAudioStateParams(
        spaceId: spaceId,
        volumePercent: event.volumePercent,
        isMuted: event.isMuted,
        queueEndBehavior: event.queueEndBehavior,
        usePlaybackDeviceScope: sessionCubit.state.isPlaybackDevice,
      ),
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          errorMessage: 'Update audio settings failed: ${failure.message}',
        ));
        add(const CamsRefreshState(silent: true));
      },
      (_) {},
    );
  }

  Future<void> _onCancelOverride(
    CamsCancelOverride event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    final spaceId = state.spaceId;
    if (spaceId == null) return;

    emit(state.copyWith(isOverriding: true, clearError: true));

    final result = await cancelOverride(
      spaceId,
      usePlaybackDeviceScope: sessionCubit.state.isPlaybackDevice,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isOverriding: false,
        errorMessage: 'Cancel override failed: ${failure.message}',
      )),
      (_) {
        emit(state.copyWith(
          isOverriding: false,
          clearOverrideResponse: true,
          clearPendingTrackJump: true,
        ));
        add(const CamsRefreshState(silent: true));
      },
    );
  }

  Future<void> _onSendCommand(
    CamsSendCommand event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    final spaceId = state.spaceId;
    if (spaceId == null) return;

    final result = await sendPlaybackCommand(
      spaceId: spaceId,
      command: event.command,
      seekPositionSeconds: event.seekPositionSeconds,
      targetTrackId: event.targetTrackId,
      usePlaybackDeviceScope: sessionCubit.state.isPlaybackDevice,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: 'Command failed: ${failure.message}',
      )),
      (_) {
        // Commands are reconciled via SignalR state sync.
      },
    );
  }

  void _onPlayStream(
    CamsPlayStreamReceived event,
    Emitter<CamsPlaybackState> emit,
  ) {
    if (!_isSameSpace(event.spaceId, state.spaceId)) return;

    final current = state.playbackState;
    final spaceId = state.spaceId ?? event.spaceId;
    final startedAt = event.startedAtUtc ?? DateTime.now().toUtc();

    final hintedState = SpacePlaybackState(
      spaceId: spaceId,
      storeId: current?.storeId,
      brandId: current?.brandId,
      currentQueueItemId:
          event.currentQueueItemId ?? current?.currentQueueItemId,
      currentTrackName: event.trackName ?? current?.currentTrackName,
      currentPlaylistId: event.playlistId ?? current?.currentPlaylistId,
      currentPlaylistName: current?.currentPlaylistName,
      hlsUrl: event.hlsUrl,
      moodName: current?.moodName,
      isManualOverride: event.isManualOverride,
      overrideMode: current?.overrideMode,
      startedAtUtc: startedAt,
      expectedEndAtUtc: current?.expectedEndAtUtc,
      isPaused: false,
      pausePositionSeconds: null,
      seekOffsetSeconds: null,
      pendingQueueItemId: null,
      pendingPlaylistId: null,
      pendingOverrideReason: null,
      volumePercent: current?.volumePercent ?? 100,
      isMuted: current?.isMuted ?? false,
      queueEndBehavior: current?.queueEndBehavior ?? 0,
      spaceQueueItems: current?.spaceQueueItems ?? const [],
    );

    emit(state.copyWith(
      status: CamsStatus.active,
      playbackState: hintedState,
    ));
    _silentEmptyStateStreak = 0;

    // PlayStream is transition hint only; reconcile with authoritative state.
    add(const CamsRefreshState(silent: true));
  }

  void _onPlaybackCommand(
    CamsPlaybackCommandReceived event,
    Emitter<CamsPlaybackState> emit,
  ) {
    if (!_isSameSpace(event.spaceId, state.spaceId)) return;

    final shouldApplyLocally = _isOptimisticCommand(event.command);
    if (!shouldApplyLocally) {
      // Skip/TrackEnded identity should be finalized from SpaceStateSync.
      return;
    }

    final syncedPlaybackState = _applyPlaybackCommandToState(
      current: state.playbackState,
      command: event.command,
      seekPositionSeconds: event.seekPositionSeconds,
    );
    final nextPlaybackState = syncedPlaybackState ?? state.playbackState;
    final nextStatus = nextPlaybackState == null
        ? state.status
        : (nextPlaybackState.isStreaming ||
                nextPlaybackState.hasPendingPlayback)
            ? CamsStatus.active
            : CamsStatus.idle;

    emit(state.copyWith(
      status: nextStatus,
      playbackState: nextPlaybackState,
      lastPlaybackCommand: event.command,
      lastSeekPositionSeconds: event.seekPositionSeconds,
      lastTargetTrackId: event.targetTrackId,
      commandSequence: state.commandSequence + 1,
    ));
    if (nextPlaybackState?.isStreaming ?? false) {
      _silentEmptyStateStreak = 0;
    }
  }

  Future<void> _onStateSync(
    CamsStateSyncReceived event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    final incomingState = event.playbackState;
    if (!_isSameSpace(incomingState.spaceId, state.spaceId)) return;
    final mergedState = _mergePlaybackState(
      current: state.playbackState,
      incoming: incomingState,
    );
    final hydratedState = await _hydrateQueueSnapshotIfNeeded(mergedState);

    emit(state.copyWith(
      status: (hydratedState.isStreaming || hydratedState.hasPendingPlayback)
          ? CamsStatus.active
          : CamsStatus.idle,
      playbackState: hydratedState,
      clearError: true,
      clearOverrideResponse: true,
      clearLastCommand: true,
    ));
    if (hydratedState.isStreaming || hydratedState.hasPendingPlayback) {
      _silentEmptyStateStreak = 0;
    }
  }

  void _onStopPlayback(
    CamsStopPlaybackReceived event,
    Emitter<CamsPlaybackState> emit,
  ) {
    final spaceId = state.spaceId ?? '';
    emit(state.copyWith(
      status: CamsStatus.idle,
      playbackState: SpacePlaybackState(spaceId: spaceId),
      clearOverrideResponse: true,
      clearPendingTrackJump: true,
      clearLastCommand: true,
    ));
  }

  Future<void> _onRefreshState(
    CamsRefreshState event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    final spaceId = state.spaceId;
    if (spaceId == null) return;

    final result = await getSpaceState(
      spaceId,
      usePlaybackDeviceScope: sessionCubit.state.isPlaybackDevice,
    );
    await result.fold(
      (failure) async {
        if (event.silent) return;
        emit(state.copyWith(
          errorMessage: failure.message,
        ));
      },
      (playbackState) async {
        final normalizedState = _normalizePlaybackStateForClientClock(
          incoming: playbackState,
          current: state.playbackState,
        );
        final hydratedState =
            await _hydrateQueueSnapshotIfNeeded(normalizedState);
        final hasIncomingStream =
            hydratedState.isStreaming || hydratedState.hasPendingPlayback;
        final hadCurrentStream = (state.playbackState?.isStreaming ?? false) ||
            (state.playbackState?.hasPendingPlayback ?? false);
        final isSilentTransientEmpty =
            event.silent && !hasIncomingStream && hadCurrentStream;
        if (isSilentTransientEmpty) {
          _silentEmptyStateStreak += 1;
          if (_silentEmptyStateStreak < 3) {
            Future<void>.delayed(const Duration(milliseconds: 700), () {
              if (!isClosed) {
                add(const CamsRefreshState(silent: true));
              }
            });
            return;
          }
        } else {
          _silentEmptyStateStreak = 0;
        }

        emit(state.copyWith(
          status: hasIncomingStream ? CamsStatus.active : CamsStatus.idle,
          playbackState: hydratedState,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onReportPlaybackState(
    CamsReportPlaybackState event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    if (!state.isHubConnected) return;
    final activeSpaceId = state.spaceId;
    if (activeSpaceId == null || !_isSameSpace(activeSpaceId, event.spaceId)) {
      return;
    }

    try {
      await storeHubService.reportPlaybackState(
        spaceId: event.spaceId,
        isPlaying: event.isPlaying,
        positionSeconds: event.positionSeconds,
        currentHlsUrl: event.currentHlsUrl,
      );
    } catch (_) {
      // Best-effort reporting for analytics/health; ignore failures.
    }
  }

  void _cancelSubscriptions() {
    _playStreamSub?.cancel();
    _playbackCommandSub?.cancel();
    _stateSyncSub?.cancel();
    _stopPlaybackSub?.cancel();
    _connectionSub?.cancel();
  }

  bool _isSameSpace(String? left, String? right) {
    if (left == null || right == null) return false;
    return left.toLowerCase() == right.toLowerCase();
  }

  bool _isOptimisticCommand(PlaybackCommandEnum command) {
    return command == PlaybackCommandEnum.pause ||
        command == PlaybackCommandEnum.resume ||
        command == PlaybackCommandEnum.seek ||
        command == PlaybackCommandEnum.seekForward ||
        command == PlaybackCommandEnum.seekBackward;
  }

  SpacePlaybackState? _applyPlaybackCommandToState({
    required SpacePlaybackState? current,
    required PlaybackCommandEnum command,
    required double? seekPositionSeconds,
  }) {
    if (current == null) return null;

    final nowUtc = DateTime.now().toUtc();
    final resolvedSeek = seekPositionSeconds == null
        ? null
        : (seekPositionSeconds < 0 ? 0.0 : seekPositionSeconds);
    final fallbackCurrentPosition = current.effectiveSeekOffset;

    switch (command) {
      case PlaybackCommandEnum.pause:
        final pausePosition = (resolvedSeek ?? fallbackCurrentPosition)
            .round()
            .clamp(0, 1 << 31)
            .toInt();
        return _copyPlaybackStateWithTiming(
          source: current,
          isPaused: true,
          pausePositionSeconds: pausePosition,
          seekOffsetSeconds: resolvedSeek ?? current.seekOffsetSeconds,
        );
      case PlaybackCommandEnum.resume:
        final resumePosition = resolvedSeek ??
            current.pausePositionSeconds?.toDouble() ??
            fallbackCurrentPosition;
        return _copyPlaybackStateWithTiming(
          source: current,
          isPaused: false,
          pausePositionSeconds: null,
          seekOffsetSeconds: resumePosition,
          startedAtUtc: _startedAtForOffset(nowUtc, resumePosition),
        );
      case PlaybackCommandEnum.seek:
      case PlaybackCommandEnum.seekForward:
      case PlaybackCommandEnum.seekBackward:
      case PlaybackCommandEnum.skipNext:
      case PlaybackCommandEnum.skipPrevious:
      case PlaybackCommandEnum.skipToTrack:
      case PlaybackCommandEnum.trackEnded:
        if (resolvedSeek == null) {
          return current;
        }
        if (current.isPaused) {
          return _copyPlaybackStateWithTiming(
            source: current,
            isPaused: true,
            pausePositionSeconds:
                resolvedSeek.round().clamp(0, 1 << 31).toInt(),
            seekOffsetSeconds: resolvedSeek,
          );
        }
        return _copyPlaybackStateWithTiming(
          source: current,
          isPaused: false,
          pausePositionSeconds: null,
          seekOffsetSeconds: resolvedSeek,
          startedAtUtc: _startedAtForOffset(nowUtc, resolvedSeek),
        );
    }
  }

  DateTime _startedAtForOffset(DateTime nowUtc, double offsetSeconds) {
    final safeOffsetSeconds = offsetSeconds < 0 ? 0.0 : offsetSeconds;
    final offsetMilliseconds = (safeOffsetSeconds * 1000).round();
    return nowUtc.subtract(Duration(milliseconds: offsetMilliseconds));
  }

  SpacePlaybackState _copyPlaybackStateWithTiming({
    required SpacePlaybackState source,
    required bool isPaused,
    required int? pausePositionSeconds,
    required double? seekOffsetSeconds,
    DateTime? startedAtUtc,
  }) {
    return SpacePlaybackState(
      spaceId: source.spaceId,
      storeId: source.storeId,
      brandId: source.brandId,
      currentQueueItemId: source.currentQueueItemId,
      currentTrackName: source.currentTrackName,
      currentPlaylistId: source.currentPlaylistId,
      currentPlaylistName: source.currentPlaylistName,
      hlsUrl: source.hlsUrl,
      moodName: source.moodName,
      isManualOverride: source.isManualOverride,
      overrideMode: source.overrideMode,
      startedAtUtc: startedAtUtc ?? source.startedAtUtc,
      expectedEndAtUtc: source.expectedEndAtUtc,
      isPaused: isPaused,
      pausePositionSeconds: pausePositionSeconds,
      seekOffsetSeconds: seekOffsetSeconds,
      pendingQueueItemId: source.pendingQueueItemId,
      pendingPlaylistId: source.pendingPlaylistId,
      pendingOverrideReason: source.pendingOverrideReason,
      volumePercent: source.volumePercent,
      isMuted: source.isMuted,
      queueEndBehavior: source.queueEndBehavior,
      spaceQueueItems: source.spaceQueueItems,
    );
  }

  SpacePlaybackState _copyPlaybackStateWithQueue({
    required SpacePlaybackState source,
    required List<SpaceQueueStateItem> queueItems,
    bool clearPendingQueueItemId = false,
  }) {
    return SpacePlaybackState(
      spaceId: source.spaceId,
      storeId: source.storeId,
      brandId: source.brandId,
      currentQueueItemId: source.currentQueueItemId,
      currentTrackName: source.currentTrackName,
      currentPlaylistId: source.currentPlaylistId,
      currentPlaylistName: source.currentPlaylistName,
      hlsUrl: source.hlsUrl,
      moodName: source.moodName,
      isManualOverride: source.isManualOverride,
      overrideMode: source.overrideMode,
      startedAtUtc: source.startedAtUtc,
      expectedEndAtUtc: source.expectedEndAtUtc,
      isPaused: source.isPaused,
      pausePositionSeconds: source.pausePositionSeconds,
      seekOffsetSeconds: source.seekOffsetSeconds,
      pendingQueueItemId:
          clearPendingQueueItemId ? null : source.pendingQueueItemId,
      pendingPlaylistId: source.pendingPlaylistId,
      pendingOverrideReason: source.pendingOverrideReason,
      volumePercent: source.volumePercent,
      isMuted: source.isMuted,
      queueEndBehavior: source.queueEndBehavior,
      spaceQueueItems: queueItems,
    );
  }

  SpacePlaybackState _copyPlaybackStateWithAudio({
    required SpacePlaybackState source,
    required int volumePercent,
    required bool isMuted,
    required int queueEndBehavior,
  }) {
    return SpacePlaybackState(
      spaceId: source.spaceId,
      storeId: source.storeId,
      brandId: source.brandId,
      currentQueueItemId: source.currentQueueItemId,
      currentTrackName: source.currentTrackName,
      currentPlaylistId: source.currentPlaylistId,
      currentPlaylistName: source.currentPlaylistName,
      hlsUrl: source.hlsUrl,
      moodName: source.moodName,
      isManualOverride: source.isManualOverride,
      overrideMode: source.overrideMode,
      startedAtUtc: source.startedAtUtc,
      expectedEndAtUtc: source.expectedEndAtUtc,
      isPaused: source.isPaused,
      pausePositionSeconds: source.pausePositionSeconds,
      seekOffsetSeconds: source.seekOffsetSeconds,
      pendingQueueItemId: source.pendingQueueItemId,
      pendingPlaylistId: source.pendingPlaylistId,
      pendingOverrideReason: source.pendingOverrideReason,
      volumePercent: volumePercent,
      isMuted: isMuted,
      queueEndBehavior: queueEndBehavior,
      spaceQueueItems: source.spaceQueueItems,
    );
  }

  List<SpaceQueueStateItem> _reorderQueueItemsLocally(
    List<SpaceQueueStateItem> currentItems,
    List<String> queueItemOrder,
  ) {
    if (currentItems.isEmpty || queueItemOrder.isEmpty) return currentItems;

    final byId = <String, SpaceQueueStateItem>{
      for (final item in currentItems) item.queueItemId: item,
    };
    final reordered = <SpaceQueueStateItem>[];
    for (final queueItemId in queueItemOrder) {
      final item = byId.remove(queueItemId);
      if (item != null) reordered.add(item);
    }
    reordered.addAll(byId.values);
    return _reindexQueueItems(reordered);
  }

  List<SpaceQueueStateItem> _reindexQueueItems(
    List<SpaceQueueStateItem> items,
  ) {
    if (items.isEmpty) return const [];

    return List<SpaceQueueStateItem>.generate(items.length, (index) {
      final original = items[index];
      return SpaceQueueStateItem(
        queueItemId: original.queueItemId,
        trackId: original.trackId,
        trackName: original.trackName,
        position: index + 1,
        queueStatus: original.queueStatus,
        source: original.source,
        hlsUrl: original.hlsUrl,
        isReadyToStream: original.isReadyToStream,
      );
    }, growable: false);
  }

  bool _shouldHydrateQueueSnapshot(SpacePlaybackState state) {
    if (state.spaceQueueItems.isNotEmpty) return false;

    final hasQueueIdentity = (state.currentQueueItemId?.isNotEmpty ?? false) ||
        (state.pendingQueueItemId?.isNotEmpty ?? false);
    if (hasQueueIdentity) return true;

    final hasHls = state.hlsUrl != null && state.hlsUrl!.isNotEmpty;
    return hasHls && !_hasLegacyPlaylistIdentity(state);
  }

  Future<SpacePlaybackState> _hydrateQueueSnapshotIfNeeded(
    SpacePlaybackState state,
  ) async {
    if (!_shouldHydrateQueueSnapshot(state)) return state;

    final queueResult = await getSpaceQueue(
      QueueScopeParams(
        spaceId: state.spaceId,
        usePlaybackDeviceScope: sessionCubit.state.isPlaybackDevice,
      ),
    );

    return queueResult.fold(
      (_) => state,
      (queueItems) {
        if (queueItems.isEmpty) return state;
        return _copyPlaybackStateWithQueue(
          source: state,
          queueItems: _reindexQueueItems(queueItems),
        );
      },
    );
  }

  bool _hasStreamIdentity(SpacePlaybackState state) {
    final hasHls = state.hlsUrl != null && state.hlsUrl!.isNotEmpty;
    if (!hasHls) return false;

    final hasQueueIdentity = (state.currentQueueItemId?.isNotEmpty ?? false) ||
        ((_resolveTrackIdFromQueueSnapshot(state)?.isNotEmpty ?? false));
    return hasQueueIdentity || _hasLegacyPlaylistIdentity(state);
  }

  bool _hasLegacyPlaylistIdentity(SpacePlaybackState state) {
    return state.spaceQueueItems.isEmpty &&
        (state.currentPlaylistId?.isNotEmpty ?? false);
  }

  String? _resolveTrackIdFromQueueSnapshot(
    SpacePlaybackState state, {
    String? queueItemIdOverride,
  }) {
    final queueItemId = queueItemIdOverride ?? state.currentQueueItemId;
    if (queueItemId != null && queueItemId.isNotEmpty) {
      for (final queueItem in state.spaceQueueItems) {
        if (queueItem.queueItemId == queueItemId) {
          return queueItem.trackId;
        }
      }
    }

    for (final queueItem in state.spaceQueueItems) {
      if (queueItem.queueStatus == 1) {
        return queueItem.trackId;
      }
    }

    return null;
  }

  String _streamIdentityKey(SpacePlaybackState state) {
    final queueItemId = state.currentQueueItemId ?? '';
    final trackId = _resolveTrackIdFromQueueSnapshot(state) ?? '';
    final legacyPlaylistId = _hasLegacyPlaylistIdentity(state)
        ? (state.currentPlaylistId ?? '')
        : '';
    final hlsUrl = state.hlsUrl ?? '';
    return [queueItemId, trackId, legacyPlaylistId, hlsUrl].join('|');
  }

  SpacePlaybackState _mergePlaybackState({
    required SpacePlaybackState? current,
    required SpacePlaybackState incoming,
  }) {
    if (current == null) return incoming;

    final incomingHasIdentity = _hasStreamIdentity(incoming);
    final currentHasIdentity = _hasStreamIdentity(current);
    final incomingCarriesPlaybackSignals = incoming.startedAtUtc != null ||
        incoming.isPaused ||
        incoming.pausePositionSeconds != null ||
        incoming.seekOffsetSeconds != null;
    final shouldPreserveIdentity = !incomingHasIdentity &&
        currentHasIdentity &&
        incomingCarriesPlaybackSignals;

    final resolvedQueueItemId = incoming.currentQueueItemId != null &&
            incoming.currentQueueItemId!.isNotEmpty
        ? incoming.currentQueueItemId
        : shouldPreserveIdentity
            ? current.currentQueueItemId
            : null;

    final incomingLegacyPlaylistId = incoming.currentPlaylistId != null &&
            incoming.currentPlaylistId!.isNotEmpty &&
            incoming.spaceQueueItems.isEmpty
        ? incoming.currentPlaylistId
        : null;
    final currentLegacyPlaylistId =
        _hasLegacyPlaylistIdentity(current) ? current.currentPlaylistId : null;
    final resolvedPlaylistId = incomingLegacyPlaylistId ??
        (shouldPreserveIdentity ? currentLegacyPlaylistId : null);

    final resolvedHlsUrl =
        incoming.hlsUrl != null && incoming.hlsUrl!.isNotEmpty
            ? incoming.hlsUrl
            : shouldPreserveIdentity
                ? current.hlsUrl
                : null;

    final currentResolvedTrackId = _resolveTrackIdFromQueueSnapshot(current);
    final incomingResolvedTrackId = _resolveTrackIdFromQueueSnapshot(
      incoming,
      queueItemIdOverride: resolvedQueueItemId,
    );
    final resolvedTrackId = incomingResolvedTrackId ??
        (shouldPreserveIdentity ? currentResolvedTrackId : null);

    final streamIdentityChanged =
        resolvedQueueItemId != current.currentQueueItemId ||
            resolvedTrackId != currentResolvedTrackId ||
            resolvedPlaylistId != currentLegacyPlaylistId ||
            resolvedHlsUrl != current.hlsUrl;

    final mergedState = SpacePlaybackState(
      spaceId: incoming.spaceId.isNotEmpty ? incoming.spaceId : current.spaceId,
      storeId: incoming.storeId ?? current.storeId,
      brandId: incoming.brandId ?? current.brandId,
      currentQueueItemId: resolvedQueueItemId,
      currentTrackName: incoming.currentTrackName ??
          ((resolvedQueueItemId == current.currentQueueItemId ||
                  resolvedTrackId == currentResolvedTrackId)
              ? current.currentTrackName
              : null),
      currentPlaylistId: resolvedPlaylistId,
      currentPlaylistName: incoming.currentPlaylistName ??
          ((resolvedPlaylistId == currentLegacyPlaylistId)
              ? current.currentPlaylistName
              : null),
      hlsUrl: resolvedHlsUrl,
      moodName: incoming.moodName ?? current.moodName,
      isManualOverride: incoming.isManualOverride,
      overrideMode: incoming.overrideMode ?? current.overrideMode,
      startedAtUtc: incoming.startedAtUtc ??
          (streamIdentityChanged ? null : current.startedAtUtc),
      expectedEndAtUtc: incoming.expectedEndAtUtc ?? current.expectedEndAtUtc,
      isPaused: incoming.isPaused,
      pausePositionSeconds: incoming.pausePositionSeconds,
      seekOffsetSeconds: incoming.seekOffsetSeconds,
      pendingQueueItemId: incoming.pendingQueueItemId,
      pendingPlaylistId: incoming.pendingPlaylistId,
      pendingOverrideReason: incoming.pendingOverrideReason,
      volumePercent: incoming.volumePercent,
      isMuted: incoming.isMuted,
      queueEndBehavior: incoming.queueEndBehavior,
      spaceQueueItems: incoming.spaceQueueItems,
    );

    return _normalizePlaybackStateForClientClock(
      incoming: mergedState,
      current: current,
    );
  }

  bool _hasSameStreamIdentity(
    SpacePlaybackState left,
    SpacePlaybackState right,
  ) {
    return _streamIdentityKey(left) == _streamIdentityKey(right);
  }

  SpacePlaybackState _normalizePlaybackStateForClientClock({
    required SpacePlaybackState incoming,
    SpacePlaybackState? current,
  }) {
    if (incoming.isPaused) return incoming;

    final nowUtc = DateTime.now().toUtc();
    if (incoming.seekOffsetSeconds != null) {
      return _copyPlaybackStateWithTiming(
        source: incoming,
        isPaused: incoming.isPaused,
        pausePositionSeconds: incoming.pausePositionSeconds,
        seekOffsetSeconds: incoming.seekOffsetSeconds,
        startedAtUtc: _startedAtForOffset(nowUtc, incoming.seekOffsetSeconds!),
      );
    }

    if (current != null &&
        _hasSameStreamIdentity(current, incoming) &&
        current.startedAtUtc != null) {
      return _copyPlaybackStateWithTiming(
        source: incoming,
        isPaused: incoming.isPaused,
        pausePositionSeconds: incoming.pausePositionSeconds,
        seekOffsetSeconds: incoming.seekOffsetSeconds,
        startedAtUtc: current.startedAtUtc,
      );
    }

    return incoming;
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}
