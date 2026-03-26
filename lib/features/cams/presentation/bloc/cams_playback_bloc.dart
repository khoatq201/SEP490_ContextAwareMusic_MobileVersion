import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/playback_command_enum.dart';
import '../../../../core/enums/queue_insert_mode_enum.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../moods/domain/usecases/get_moods.dart';
import '../../data/services/queue_first_playback_runtime.dart';
import '../../data/services/store_hub_service.dart';
import '../../domain/entities/space_playback_state.dart';
import '../../domain/services/cams_playback_capability_provider.dart';
import '../../domain/usecases/cancel_override.dart';
import '../../domain/usecases/override_space.dart';
import 'cams_playback_event.dart';
import 'cams_playback_state.dart';

/// Thin BLoC for queue-first CAMS playback.
///
/// All queue/playback orchestration lives in [QueueFirstPlaybackRuntime].
/// This bloc only:
/// - forwards UI intents to the runtime,
/// - exposes canonical playback snapshots to the UI,
/// - keeps legacy override/mood flows available outside the queue-first V2 path.
class CamsPlaybackBloc extends Bloc<CamsPlaybackEvent, CamsPlaybackState> {
  CamsPlaybackBloc({
    required this.overrideSpace,
    required this.cancelOverride,
    required this.getMoods,
    required this.storeHubService,
    required this.sessionCubit,
    required this.runtime,
    this.capabilityProvider = const StaticCamsPlaybackCapabilityProvider(),
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
    on<CamsPlayStreamReceived>(_onLegacyPlayStream);
    on<CamsPlaybackCommandReceived>(_onLegacyPlaybackCommand);
    on<CamsStateSyncReceived>(_onRuntimePlaybackStateUpdated);
    on<CamsStopPlaybackReceived>(_onLegacyStopPlayback);
    on<CamsHubConnectionChanged>(_onHubConnectionChanged);
    on<CamsRefreshState>(_onRefreshState);
    on<CamsReportPlaybackState>(_onReportPlaybackState);
  }

  final OverrideSpace overrideSpace;
  final CancelOverride cancelOverride;
  final GetMoods getMoods;
  final StoreHubService storeHubService;
  final SessionCubit sessionCubit;
  final QueueFirstPlaybackRuntime runtime;
  final CamsPlaybackCapabilityProvider capabilityProvider;

  StreamSubscription<SpacePlaybackState>? _runtimePlaybackStateSub;
  StreamSubscription<ConnectionStatus>? _runtimeConnectionSub;

  Future<void> _onInit(
    CamsInitPlayback event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    _debugLog(
      'initPlayback spaceId=${event.spaceId} '
      'playbackDevice=${sessionCubit.state.isPlaybackDevice}',
    );
    _subscribeToRuntime();

    emit(state.copyWith(
      status: CamsStatus.loading,
      spaceId: event.spaceId,
      clearError: true,
      clearPendingTrackJump: true,
      clearLastCommand: true,
    ));

    if (!sessionCubit.state.isPlaybackDevice) {
      final moodsResult = await getMoods();
      moodsResult.fold(
        (_) {},
        (moods) => emit(state.copyWith(moods: moods)),
      );
    }

    final bootstrapResult = await runtime.bootstrap(
      spaceId: event.spaceId,
      usePlaybackDeviceScope: sessionCubit.state.isPlaybackDevice,
      managerStoreId: sessionCubit.state.isPlaybackDevice
          ? null
          : sessionCubit.state.currentStore?.id,
    );

    bootstrapResult.fold(
      (failure) {
        _debugLog('bootstrap failed: ${failure.message}');
        emit(state.copyWith(
          status: CamsStatus.error,
          errorMessage: failure.message,
          isHubConnected: runtime.isConnected,
        ));
      },
      (playbackState) => _emitRuntimeState(
        emit,
        playbackState,
        isHubConnected: runtime.isConnected,
      ),
    );
  }

  Future<void> _onDispose(
    CamsDisposePlayback event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    await runtime.reset();
    emit(const CamsPlaybackState());
  }

  Future<void> _onOverrideMood(
    CamsOverrideMood event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    if (!_hasActiveSessionScope('overrideMood')) return;
    final spaceId = state.spaceId;
    if (spaceId == null || spaceId.isEmpty) return;

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
      (response) async {
        emit(state.copyWith(
          isOverriding: false,
          lastOverrideResponse: response,
          clearPendingTrackJump: true,
        ));
        await runtime.refreshState(silent: true);
      },
    );
  }

  Future<void> _onPlayPlaylist(
    CamsPlayPlaylist event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    if (!_hasActiveSessionScope('playPlaylist')) return;
    final resolvedClearExistingQueue = _resolveClearExistingQueue(
      resolvedMode: event.requestedMode,
      requestedClearExistingQueue: event.clearExistingQueue,
    );
    final resolvedReason =
        event.reason ?? _playlistActionReason(event.requestedMode);
    _debugLog(
      'playPlaylist intent '
      'spaceId=${state.spaceId} playlistId=${event.playlistId} '
      'mode=${event.requestedMode.name} clear=$resolvedClearExistingQueue '
      'reason="$resolvedReason"',
    );
    emit(state.copyWith(isOverriding: true, clearError: true));

    final result = await runtime.playPlaylist(
      playlistId: event.playlistId,
      requestedMode: _resolveManualQueueMode(event.requestedMode),
      clearExistingQueue: resolvedClearExistingQueue,
      reason: resolvedReason,
    );

    result.fold(
      (failure) {
        _debugLog('playPlaylist failed: ${failure.message}');
        emit(state.copyWith(
          isOverriding: false,
          errorMessage: 'Play playlist failed: ${failure.message}',
        ));
      },
      (_) {
        _debugLog('playPlaylist ACK received from runtime');
        emit(state.copyWith(
          isOverriding: false,
          clearPendingTrackJump: true,
        ));
      },
    );
  }

  Future<void> _onPlayTrack(
    CamsPlayTrack event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    if (!_hasActiveSessionScope('playTrack')) return;
    final resolvedClearExistingQueue = _resolveClearExistingQueue(
      resolvedMode: event.requestedMode,
      requestedClearExistingQueue: event.clearExistingQueue,
    );
    final resolvedReason =
        event.reason ?? _trackActionReason(event.requestedMode);
    _debugLog(
      'playTrack intent '
      'spaceId=${state.spaceId} trackId=${event.trackId} '
      'mode=${event.requestedMode.name} clear=$resolvedClearExistingQueue '
      'reason="$resolvedReason"',
    );
    emit(state.copyWith(isOverriding: true, clearError: true));

    final result = await runtime.playTrack(
      trackId: event.trackId,
      requestedMode: _resolveManualQueueMode(event.requestedMode),
      clearExistingQueue: resolvedClearExistingQueue,
      reason: resolvedReason,
    );

    result.fold(
      (failure) {
        _debugLog('playTrack failed: ${failure.message}');
        emit(state.copyWith(
          isOverriding: false,
          errorMessage: 'Play track failed: ${failure.message}',
        ));
      },
      (_) {
        _debugLog('playTrack ACK received from runtime');
        emit(state.copyWith(
          isOverriding: false,
          clearPendingTrackJump: true,
        ));
      },
    );
  }

  Future<void> _onReorderQueue(
    CamsReorderQueue event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    if (!_hasActiveSessionScope('reorderQueue')) return;
    if (event.queueItemIds.length < 2) return;

    final result = await runtime.reorderQueueItems(
      queueItemIds: event.queueItemIds,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: 'Reorder queue failed: ${failure.message}',
      )),
      (_) {},
    );
  }

  Future<void> _onRemoveQueueItems(
    CamsRemoveQueueItems event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    if (!_hasActiveSessionScope('removeQueueItems')) return;
    if (event.queueItemIds.isEmpty) return;

    final result = await runtime.removeQueueEntries(
      queueItemIds: event.queueItemIds,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: 'Remove queue item failed: ${failure.message}',
      )),
      (_) {},
    );
  }

  Future<void> _onClearQueue(
    CamsClearQueue event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    if (!_hasActiveSessionScope('clearQueue')) return;
    final result = await runtime.clearQueueItems();
    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: 'Clear queue failed: ${failure.message}',
      )),
      (_) {},
    );
  }

  Future<void> _onUpdateAudioState(
    CamsUpdateAudioState event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    if (!event.hasAnyUpdate) return;
    if (!_hasActiveSessionScope('updateAudioState')) return;

    final result = await runtime.patchAudioState(
      volumePercent: event.volumePercent,
      isMuted: event.isMuted,
      queueEndBehavior: event.queueEndBehavior,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: 'Update audio settings failed: ${failure.message}',
      )),
      (_) {},
    );
  }

  Future<void> _onCancelOverride(
    CamsCancelOverride event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    if (!_hasActiveSessionScope('cancelOverride')) return;
    final spaceId = state.spaceId;
    if (spaceId == null || spaceId.isEmpty) return;

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
      (_) async {
        emit(state.copyWith(
          isOverriding: false,
          clearOverrideResponse: true,
          clearPendingTrackJump: true,
        ));
        await runtime.refreshState(silent: true);
      },
    );
  }

  Future<void> _onSendCommand(
    CamsSendCommand event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    if (!_hasActiveSessionScope('sendCommand:${event.command.name}')) return;
    _traceLog(
      'API_COMMAND_SENT '
      'spaceId=${state.spaceId ?? '-'} '
      'command=${event.command.name} '
      'seek=${event.seekPositionSeconds?.toStringAsFixed(2) ?? '-'} '
      'targetTrackId=${event.targetTrackId ?? '-'}',
    );
    final result = await runtime.sendCommand(
      command: event.command,
      seekPositionSeconds: event.seekPositionSeconds,
      targetTrackId: event.targetTrackId,
    );

    result.fold(
      (failure) {
        _traceLog(
          'API_COMMAND_FAIL '
          'spaceId=${state.spaceId ?? '-'} '
          'command=${event.command.name} '
          'message=${failure.message}',
        );
        emit(state.copyWith(
          errorMessage: 'Command failed: ${failure.message}',
        ));
      },
      (_) {
        _traceLog(
          'API_COMMAND_ACK '
          'spaceId=${state.spaceId ?? '-'} '
          'command=${event.command.name}',
        );
      },
    );
  }

  void _onLegacyPlayStream(
    CamsPlayStreamReceived event,
    Emitter<CamsPlaybackState> emit,
  ) {
    final activeSpaceId = state.spaceId;
    if (activeSpaceId != null &&
        activeSpaceId.isNotEmpty &&
        activeSpaceId.toLowerCase() != event.spaceId.toLowerCase()) {
      return;
    }

    final currentPlayback = state.playbackState;
    final hintedState = SpacePlaybackState(
      spaceId: activeSpaceId ?? event.spaceId,
      storeId: currentPlayback?.storeId,
      brandId: currentPlayback?.brandId,
      currentQueueItemId: event.currentQueueItemId,
      currentTrackName: event.trackName ?? currentPlayback?.currentTrackName,
      currentPlaylistId: null,
      currentPlaylistName: null,
      hlsUrl: event.hlsUrl,
      moodName: currentPlayback?.moodName,
      isManualOverride: event.isManualOverride,
      overrideMode: currentPlayback?.overrideMode,
      startedAtUtc: event.startedAtUtc,
      expectedEndAtUtc: currentPlayback?.expectedEndAtUtc,
      isPaused: false,
      pausePositionSeconds: null,
      seekOffsetSeconds: currentPlayback?.seekOffsetSeconds,
      pendingQueueItemId: null,
      pendingPlaylistId: null,
      pendingOverrideReason: null,
      volumePercent: currentPlayback?.volumePercent ?? 100,
      isMuted: currentPlayback?.isMuted ?? false,
      queueEndBehavior: currentPlayback?.queueEndBehavior ?? 0,
      spaceQueueItems: currentPlayback?.spaceQueueItems ?? const [],
    );

    _emitRuntimeState(
      emit,
      hintedState,
      isHubConnected: state.isHubConnected,
    );
  }

  void _onLegacyPlaybackCommand(
    CamsPlaybackCommandReceived event,
    Emitter<CamsPlaybackState> emit,
  ) {
    final activeSpaceId = state.spaceId;
    if (activeSpaceId != null &&
        activeSpaceId.isNotEmpty &&
        activeSpaceId.toLowerCase() != event.spaceId.toLowerCase()) {
      return;
    }

    if (!_isLegacyOptimisticCommand(event.command)) {
      return;
    }

    emit(state.copyWith(
      lastPlaybackCommand: event.command,
      lastSeekPositionSeconds: _shouldPersistSeekPosition(event.command)
          ? event.seekPositionSeconds
          : null,
      clearLastSeekPosition: !_shouldPersistSeekPosition(event.command),
      lastTargetTrackId: _shouldPersistTargetTrackId(event.command)
          ? event.targetTrackId
          : null,
      clearLastTargetTrackId: !_shouldPersistTargetTrackId(event.command),
      commandSequence: state.commandSequence + 1,
    ));
  }

  void _onRuntimePlaybackStateUpdated(
    CamsStateSyncReceived event,
    Emitter<CamsPlaybackState> emit,
  ) {
    _emitRuntimeState(
      emit,
      event.playbackState,
      isHubConnected: state.isHubConnected,
    );
  }

  void _onHubConnectionChanged(
    CamsHubConnectionChanged event,
    Emitter<CamsPlaybackState> emit,
  ) {
    emit(state.copyWith(
        isHubConnected: event.status == ConnectionStatus.connected));
  }

  void _onLegacyStopPlayback(
    CamsStopPlaybackReceived event,
    Emitter<CamsPlaybackState> emit,
  ) {
    final activeSpaceId = state.spaceId;
    emit(state.copyWith(
      status: CamsStatus.idle,
      playbackState: activeSpaceId == null
          ? null
          : SpacePlaybackState(spaceId: activeSpaceId),
      clearOverrideResponse: true,
      clearPendingTrackJump: true,
      clearLastCommand: true,
    ));
  }

  Future<void> _onRefreshState(
    CamsRefreshState event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    final result = await runtime.refreshState(silent: event.silent);
    if (event.silent) return;

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (playbackState) => _emitRuntimeState(
        emit,
        playbackState,
        isHubConnected: runtime.isConnected,
      ),
    );
  }

  Future<void> _onReportPlaybackState(
    CamsReportPlaybackState event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    if (!state.isHubConnected) return;
    final activeSpaceId = state.spaceId;
    if (activeSpaceId == null ||
        activeSpaceId.toLowerCase() != event.spaceId.toLowerCase()) {
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
      // Best-effort reporting only.
    }
  }

  void _subscribeToRuntime() {
    _runtimePlaybackStateSub ??=
        runtime.playbackStateStream.listen((playbackState) {
      if (!isClosed) {
        add(CamsStateSyncReceived(playbackState: playbackState));
      }
    });

    _runtimeConnectionSub ??=
        runtime.connectionStatusStream.listen((connectionStatus) {
      if (!isClosed) {
        add(CamsHubConnectionChanged(status: connectionStatus));
      }
    });
  }

  void _emitRuntimeState(
    Emitter<CamsPlaybackState> emit,
    SpacePlaybackState playbackState, {
    required bool isHubConnected,
  }) {
    _debugLog('runtimeState ${_describePlaybackState(playbackState)}');
    emit(state.copyWith(
      status: (playbackState.isStreaming || playbackState.hasPendingPlayback)
          ? CamsStatus.active
          : CamsStatus.idle,
      spaceId: playbackState.spaceId.isNotEmpty
          ? playbackState.spaceId
          : state.spaceId,
      playbackState: playbackState,
      isHubConnected: isHubConnected,
      clearError: true,
      clearLastCommand: true,
    ));
  }

  QueueInsertModeEnum _resolveManualQueueMode(
    QueueInsertModeEnum requestedMode,
  ) {
    return requestedMode;
  }

  bool _resolveClearExistingQueue({
    required QueueInsertModeEnum resolvedMode,
    required bool requestedClearExistingQueue,
  }) {
    if (resolvedMode == QueueInsertModeEnum.addToQueue) {
      return false;
    }
    return requestedClearExistingQueue;
  }

  String _playlistActionReason(QueueInsertModeEnum requestedMode) {
    switch (requestedMode) {
      case QueueInsertModeEnum.playNow:
        return 'Manual playlist play-now request';
      case QueueInsertModeEnum.playNext:
        return 'Manual playlist play-next request';
      case QueueInsertModeEnum.addToQueue:
        return 'Manual playlist add-to-queue request';
    }
  }

  String _trackActionReason(QueueInsertModeEnum requestedMode) {
    switch (requestedMode) {
      case QueueInsertModeEnum.playNow:
        return 'Manual track play-now request';
      case QueueInsertModeEnum.playNext:
        return 'Manual track play-next request';
      case QueueInsertModeEnum.addToQueue:
        return 'Manual track add-to-queue request';
    }
  }

  bool _isLegacyOptimisticCommand(PlaybackCommandEnum command) {
    return command == PlaybackCommandEnum.pause ||
        command == PlaybackCommandEnum.resume ||
        command == PlaybackCommandEnum.seek ||
        command == PlaybackCommandEnum.seekForward ||
        command == PlaybackCommandEnum.seekBackward;
  }

  bool _shouldPersistSeekPosition(PlaybackCommandEnum command) {
    return command == PlaybackCommandEnum.seek ||
        command == PlaybackCommandEnum.seekForward ||
        command == PlaybackCommandEnum.seekBackward;
  }

  bool _shouldPersistTargetTrackId(PlaybackCommandEnum command) {
    return command == PlaybackCommandEnum.skipNext ||
        command == PlaybackCommandEnum.skipPrevious ||
        command == PlaybackCommandEnum.skipToTrack ||
        command == PlaybackCommandEnum.trackEnded;
  }

  bool _hasActiveSessionScope(String action) {
    final sessionSpaceId = sessionCubit.state.currentSpace?.id;
    final activeSpaceId = state.spaceId;
    final hasScope = sessionSpaceId != null &&
        sessionSpaceId.isNotEmpty &&
        activeSpaceId != null &&
        activeSpaceId.isNotEmpty &&
        sessionSpaceId.toLowerCase() == activeSpaceId.toLowerCase();
    if (!hasScope) {
      _debugLog(
        'ignore $action because active session scope is unavailable '
        '(sessionSpace=${sessionSpaceId ?? '-'} stateSpace=${activeSpaceId ?? '-'})',
      );
    }
    return hasScope;
  }

  @override
  Future<void> close() async {
    await _runtimePlaybackStateSub?.cancel();
    await _runtimeConnectionSub?.cancel();
    return super.close();
  }

  void _debugLog(String message) {
    debugPrint('[CamsPlaybackBlocV2] $message');
  }

  void _traceLog(String message) {
    debugPrint('[PlaybackTrace] $message');
  }

  String _describePlaybackState(SpacePlaybackState playbackState) {
    final queuePreview = playbackState.spaceQueueItems
        .take(3)
        .map(
          (item) =>
              '${item.position}:${item.trackName ?? item.trackId}:${item.queueStatus}',
        )
        .join(' | ');
    return 'space=${playbackState.spaceId} '
        'currentQueueItemId=${playbackState.currentQueueItemId ?? '-'} '
        'pendingQueueItemId=${playbackState.pendingQueueItemId ?? '-'} '
        'currentTrack=${playbackState.currentTrackName ?? '-'} '
        'hls=${playbackState.hlsUrl ?? '-'} '
        'queueCount=${playbackState.spaceQueueItems.length} '
        'queue=[$queuePreview]';
  }
}
