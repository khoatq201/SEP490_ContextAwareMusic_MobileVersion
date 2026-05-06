import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failure_kind.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/enums/playback_command_enum.dart';
import '../../../../core/enums/queue_insert_mode_enum.dart';
import '../../../../core/enums/user_role.dart';
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
    on<CamsApplyOverride>(_onApplyOverride);
    on<CamsPlayPlaylist>(_onPlayPlaylist);
    on<CamsPlayTrack>(_onPlayTrack);
    on<CamsPlayTracks>(_onPlayTracks);
    on<CamsReorderQueue>(_onReorderQueue);
    on<CamsRemoveQueueItems>(_onRemoveQueueItems);
    on<CamsClearQueue>(_onClearQueue);
    on<CamsUpdateAudioState>(_onUpdateAudioState);
    on<CamsUpdateSchedulingState>(_onUpdateSchedulingState);
    on<CamsCancelOverride>(_onCancelOverride);
    on<CamsPreviousTapped>(_onPreviousTapped);
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
  DateTime? _lastPreviousTapAtUtc;
  String? _lastPreviousTapIdentity;
  static const double _minimumRemoteRestartSeekSeconds = 0.001;
  static const Duration _previousTapJumpThreshold = Duration(milliseconds: 900);

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
      clearPlaybackState: true,
      clearError: true,
      clearPendingTrackJump: true,
      clearLastCommand: true,
    ));

    final moodsResult = await getMoods();
    moodsResult.fold(
      (_) {},
      (moods) => emit(state.copyWith(moods: moods)),
    );

    final bootstrapResult = await runtime.bootstrap(
      spaceId: event.spaceId,
      usePlaybackDeviceScope: sessionCubit.state.isPlaybackDevice,
      managerStoreId: sessionCubit.state.isPlaybackDevice
          ? null
          : sessionCubit.state.currentStore?.id,
    );

    bootstrapResult.fold(
      (failure) {
        final displayMessage = ErrorMapper.displayMessageForFailure(failure);
        _debugLog('bootstrap failed: ${_describeFailure(failure)}');
        emit(state.copyWith(
          status: CamsStatus.error,
          errorMessage: displayMessage,
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
    await _submitOverride(
      emit,
      moodId: event.moodId,
      manualOverrideTtlSeconds: event.manualOverrideTtlSeconds,
      reason: event.reason,
    );
  }

  Future<void> _onApplyOverride(
    CamsApplyOverride event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    if (!event.hasValidSourceSelection) {
      emit(state.copyWith(
        errorMessage: 'Select at most one override source before applying.',
      ));
      return;
    }

    await _submitOverride(
      emit,
      trackIds: event.trackIds,
      playlistId: event.playlistId,
      moodId: event.moodId,
      isClearManagerSelectedQueues: event.isClearManagerSelectedQueues,
      isCutOver: event.isCutOver,
      manualOverrideTtlSeconds: event.manualOverrideTtlSeconds,
      reason: event.reason,
    );
  }

  Future<void> _submitOverride(
    Emitter<CamsPlaybackState> emit, {
    List<String>? trackIds,
    String? playlistId,
    String? moodId,
    bool? isClearManagerSelectedQueues,
    bool? isCutOver,
    int? manualOverrideTtlSeconds,
    String? reason,
  }) async {
    if (!_hasActiveSessionScope('overrideMood')) return;
    if (state.isBrandPlaybackBlocked) {
      emit(state.copyWith(errorMessage: state.playbackBlockedMessage));
      return;
    }
    final spaceId = state.spaceId;
    if (spaceId == null || spaceId.isEmpty) return;

    emit(state.copyWith(isOverriding: true, clearError: true));

    final result = await overrideSpace(
      spaceId: spaceId,
      trackIds: trackIds,
      playlistId: playlistId,
      moodId: moodId,
      isClearManagerSelectedQueues: isClearManagerSelectedQueues,
      isCutOver: isCutOver,
      manualOverrideTtlSeconds: manualOverrideTtlSeconds,
      reason: reason,
      usePlaybackDeviceScope: sessionCubit.state.isPlaybackDevice,
    );

    result.fold(
      (failure) => emit(_stateForPlaybackMutationFailure(
        failure,
        isOverriding: false,
        prefix: 'Override failed',
      )),
      (response) async {
        emit(state.copyWith(
          isOverriding: false,
          lastOverrideResponse: response,
          clearPlaybackBlock: true,
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
    if (state.isBrandPlaybackBlocked) {
      emit(state.copyWith(errorMessage: state.playbackBlockedMessage));
      return;
    }
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
        emit(_stateForPlaybackMutationFailure(
          failure,
          isOverriding: false,
          prefix: 'Play playlist failed',
        ));
      },
      (_) {
        _debugLog('playPlaylist ACK received from runtime');
        emit(state.copyWith(
          isOverriding: false,
          clearPlaybackBlock: true,
          clearPendingTrackJump: true,
        ));
      },
    );
  }

  Future<void> _onPlayTrack(
    CamsPlayTrack event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    await _submitTracks(
      emit,
      trackIds: [event.trackId],
      requestedMode: event.requestedMode,
      clearExistingQueue: event.clearExistingQueue,
      reason: event.reason,
    );
  }

  Future<void> _onPlayTracks(
    CamsPlayTracks event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    await _submitTracks(
      emit,
      trackIds: event.trackIds,
      requestedMode: event.requestedMode,
      clearExistingQueue: event.clearExistingQueue,
      reason: event.reason,
    );
  }

  Future<void> _submitTracks(
    Emitter<CamsPlaybackState> emit, {
    required List<String> trackIds,
    required QueueInsertModeEnum requestedMode,
    required bool clearExistingQueue,
    String? reason,
  }) async {
    if (!_hasActiveSessionScope('playTrack')) return;
    if (state.isBrandPlaybackBlocked) {
      emit(state.copyWith(errorMessage: state.playbackBlockedMessage));
      return;
    }
    final resolvedClearExistingQueue = _resolveClearExistingQueue(
      resolvedMode: requestedMode,
      requestedClearExistingQueue: clearExistingQueue,
    );
    final resolvedReason = reason ?? _trackActionReason(requestedMode);
    final normalizedTrackIds = trackIds
        .map((trackId) => trackId.trim())
        .where((trackId) => trackId.isNotEmpty)
        .toList(growable: false);
    if (normalizedTrackIds.isEmpty) return;
    _debugLog(
      'playTracks intent '
      'spaceId=${state.spaceId} trackIds=$normalizedTrackIds '
      'mode=${requestedMode.name} clear=$resolvedClearExistingQueue '
      'reason="$resolvedReason"',
    );
    emit(state.copyWith(isOverriding: true, clearError: true));

    final result = await runtime.playTracks(
      trackIds: normalizedTrackIds,
      requestedMode: _resolveManualQueueMode(requestedMode),
      clearExistingQueue: resolvedClearExistingQueue,
      reason: resolvedReason,
    );

    result.fold(
      (failure) {
        _debugLog('playTrack failed: ${failure.message}');
        emit(_stateForPlaybackMutationFailure(
          failure,
          isOverriding: false,
          prefix: 'Play track failed',
        ));
      },
      (_) {
        _debugLog('playTracks ACK received from runtime');
        emit(state.copyWith(
          isOverriding: false,
          clearPlaybackBlock: true,
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
        errorMessage:
            'Reorder queue failed: ${ErrorMapper.displayMessageForFailure(failure)}',
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
        errorMessage:
            'Remove queue item failed: ${ErrorMapper.displayMessageForFailure(failure)}',
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
        errorMessage:
            'Clear queue failed: ${ErrorMapper.displayMessageForFailure(failure)}',
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
      usePlaybackDeviceScope: sessionCubit.state.isPlaybackDevice,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage:
            'Update audio settings failed: ${ErrorMapper.displayMessageForFailure(failure)}',
      )),
      (_) {},
    );
  }

  Future<void> _onUpdateSchedulingState(
    CamsUpdateSchedulingState event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    if (!_hasActiveSessionScope('updateSchedulingState')) return;
    if (event.isScheduling && state.isBrandPlaybackBlocked) {
      emit(state.copyWith(errorMessage: state.playbackBlockedMessage));
      return;
    }

    emit(state.copyWith(isOverriding: true, clearError: true));
    final result = await runtime.patchSchedulingState(
      isScheduling: event.isScheduling,
      usePlaybackDeviceScope: sessionCubit.state.isPlaybackDevice,
    );

    result.fold(
      (failure) {
        final message = _resolveSchedulingUpdateErrorMessage(
          failure,
          attemptedEnable: event.isScheduling,
        );
        emit(_stateForPlaybackMutationFailure(
          failure,
          isOverriding: false,
          displayMessage: message,
          affectsPlaybackStart: event.isScheduling,
        ));
      },
      (_) => emit(state.copyWith(
        isOverriding: false,
        clearPlaybackBlock: event.isScheduling,
      )),
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
        errorMessage:
            'Cancel override failed: ${ErrorMapper.displayMessageForFailure(failure)}',
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
    if (state.isBrandPlaybackBlocked &&
        _isQuotaConsumingPlaybackCommand(event.command)) {
      emit(state.copyWith(errorMessage: state.playbackBlockedMessage));
      return;
    }
    if (_shouldRelayCommandOptimistically(
      command: event.command,
    )) {
      _emitPlaybackCommandRelay(
        emit,
        command: event.command,
        seekPositionSeconds: event.seekPositionSeconds,
        targetQueueItemId: event.targetQueueItemId,
        targetTrackId: event.targetTrackId,
      );
    }
    _traceLog(
      'API_COMMAND_SENT '
      'spaceId=${state.spaceId ?? '-'} '
      'command=${event.command.name} '
      'seek=${event.seekPositionSeconds?.toStringAsFixed(2) ?? '-'} '
      'targetQueueItemId=${event.targetQueueItemId ?? '-'} '
      'targetTrackId=${event.targetTrackId ?? '-'}',
    );
    final result = await runtime.sendCommand(
      command: event.command,
      seekPositionSeconds: event.seekPositionSeconds,
      targetQueueItemId: event.targetQueueItemId,
      targetTrackId: event.targetTrackId,
    );

    result.fold(
      (failure) {
        _traceLog(
          'API_COMMAND_FAIL '
          'spaceId=${state.spaceId ?? '-'} '
          'command=${event.command.name} '
          '${_describeFailure(failure)}',
        );
        final failedState = _stateForPlaybackMutationFailure(
          failure,
          prefix: 'Command failed',
          affectsPlaybackStart: _isQuotaConsumingPlaybackCommand(event.command),
        );
        emit(state.copyWith(
          errorMessage: failedState.errorMessage,
          playbackBlockedMessage: failedState.playbackBlockedMessage,
          playbackBlockedBrandId: failedState.playbackBlockedBrandId,
        ));
      },
      (_) {
        _traceLog(
          'API_COMMAND_ACK '
          'spaceId=${state.spaceId ?? '-'} '
          'command=${event.command.name}',
        );
        if (_isQuotaConsumingPlaybackCommand(event.command)) {
          emit(state.copyWith(clearPlaybackBlock: true));
        }
      },
    );
  }

  void _onPreviousTapped(
    CamsPreviousTapped event,
    Emitter<CamsPlaybackState> emit,
  ) {
    if (!_hasActiveSessionScope('previousTap')) return;

    final playbackState = state.playbackState;
    if (playbackState == null || !playbackState.hasPlayableHls) {
      return;
    }

    final nowUtc = DateTime.now().toUtc();
    final currentIdentity = _previousTapIdentity(playbackState);
    final previousQueueItem = playbackState.previousQueueItem;
    final shouldJumpToPrevious = previousQueueItem != null &&
        _lastPreviousTapAtUtc != null &&
        _lastPreviousTapIdentity == currentIdentity &&
        nowUtc.difference(_lastPreviousTapAtUtc!) <= _previousTapJumpThreshold;

    if (shouldJumpToPrevious) {
      _lastPreviousTapAtUtc = null;
      _lastPreviousTapIdentity = null;
      add(
        CamsSendCommand(
          command: PlaybackCommandEnum.skipToTrack,
          targetQueueItemId: previousQueueItem.queueItemId,
        ),
      );
      return;
    }

    _lastPreviousTapAtUtc = nowUtc;
    _lastPreviousTapIdentity = currentIdentity;
    add(
      const CamsSendCommand(
        command: PlaybackCommandEnum.seek,
        seekPositionSeconds: _minimumRemoteRestartSeekSeconds,
      ),
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
      overrideReason: currentPlayback?.overrideReason,
      manualOverrideActivatedAtUtc:
          currentPlayback?.manualOverrideActivatedAtUtc,
      manualOverrideExpiresAtUtc: currentPlayback?.manualOverrideExpiresAtUtc,
      manualOverrideTtlSeconds: currentPlayback?.manualOverrideTtlSeconds,
      manualOverrideRemainingSeconds:
          currentPlayback?.manualOverrideRemainingSeconds,
      isScheduling: currentPlayback?.isScheduling ?? false,
      schedulingSlotId: currentPlayback?.schedulingSlotId,
      schedulingSlotOrigin: currentPlayback?.schedulingSlotOrigin,
      schedulingEndsAtUtc: currentPlayback?.schedulingEndsAtUtc,
      schedulingRemainingSeconds: currentPlayback?.schedulingRemainingSeconds,
      startedAtUtc: event.startedAtUtc,
      expectedEndAtUtc: currentPlayback?.expectedEndAtUtc,
      isPaused: false,
      pausePositionSeconds: null,
      seekOffsetSeconds: currentPlayback?.seekOffsetSeconds,
      pendingQueueItemId: null,
      pendingPlaylistId: null,
      pendingOverrideReason: null,
      volumePercent: currentPlayback?.volumePercent ?? 100,
      isIotDeviceAssigned: currentPlayback?.isIotDeviceAssigned,
      isIotDeviceOffline: currentPlayback?.isIotDeviceOffline ?? false,
      isMuted: currentPlayback?.isMuted ?? false,
      queueEndBehavior: currentPlayback?.queueEndBehavior ?? 0,
      spaceQueueItems: currentPlayback?.spaceQueueItems ?? const [],
      explainability: currentPlayback?.explainability,
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

    if (!_shouldRelayCommandOptimistically(
      command: event.command,
    )) {
      return;
    }

    _emitPlaybackCommandRelay(
      emit,
      command: event.command,
      seekPositionSeconds: event.seekPositionSeconds,
      targetQueueItemId: event.targetQueueItemId,
      targetTrackId: event.targetTrackId,
    );
  }

  void _onRuntimePlaybackStateUpdated(
    CamsStateSyncReceived event,
    Emitter<CamsPlaybackState> emit,
  ) {
    final activeSpaceId = state.spaceId;
    if (activeSpaceId != null &&
        activeSpaceId.isNotEmpty &&
        event.playbackState.spaceId.toLowerCase() !=
            activeSpaceId.toLowerCase()) {
      _debugLog(
        'ignore runtime state for inactive space '
        'active=$activeSpaceId incoming=${event.playbackState.spaceId}',
      );
      return;
    }

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
      (failure) => emit(state.copyWith(
        errorMessage: ErrorMapper.displayMessageForFailure(failure),
      )),
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
    final activeSpaceId = state.spaceId;
    if (activeSpaceId != null &&
        activeSpaceId.isNotEmpty &&
        playbackState.spaceId.toLowerCase() != activeSpaceId.toLowerCase()) {
      _debugLog(
        'ignore runtime state for inactive space '
        'active=$activeSpaceId incoming=${playbackState.spaceId}',
      );
      return;
    }

    _debugLog('runtimeState ${_describePlaybackState(playbackState)}');
    final blockedBrandId = state.playbackBlockedBrandId;
    final incomingBrandId = playbackState.brandId;
    final shouldClearPlaybackBlock = blockedBrandId != null &&
        incomingBrandId != null &&
        blockedBrandId.toLowerCase() != incomingBrandId.toLowerCase();
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
      clearPlaybackBlock: shouldClearPlaybackBlock,
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

  bool _shouldRelayCommandOptimistically({
    required PlaybackCommandEnum command,
  }) {
    return _isLegacyOptimisticCommand(command);
  }

  String _previousTapIdentity(SpacePlaybackState playbackState) {
    return [
      playbackState.spaceId.toLowerCase(),
      playbackState.effectiveQueueItemId ?? '',
      playbackState.effectiveHlsUrl ?? '',
      playbackState.focusedQueueItem?.trackId ?? '',
    ].join('|');
  }

  void _emitPlaybackCommandRelay(
    Emitter<CamsPlaybackState> emit, {
    required PlaybackCommandEnum command,
    double? seekPositionSeconds,
    String? targetQueueItemId,
    String? targetTrackId,
  }) {
    emit(state.copyWith(
      lastPlaybackCommand: command,
      lastSeekPositionSeconds:
          _shouldPersistSeekPosition(command) ? seekPositionSeconds : null,
      clearLastSeekPosition: !_shouldPersistSeekPosition(command),
      lastTargetQueueItemId:
          _shouldPersistTargetTrackId(command) ? targetQueueItemId : null,
      clearLastTargetQueueItemId: !_shouldPersistTargetTrackId(command),
      lastTargetTrackId:
          _shouldPersistTargetTrackId(command) ? targetTrackId : null,
      clearLastTargetTrackId: !_shouldPersistTargetTrackId(command),
      commandSequence: state.commandSequence + 1,
    ));
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

  bool _isQuotaConsumingPlaybackCommand(PlaybackCommandEnum command) {
    return command == PlaybackCommandEnum.resume ||
        command == PlaybackCommandEnum.skipNext ||
        command == PlaybackCommandEnum.skipPrevious ||
        command == PlaybackCommandEnum.skipToTrack ||
        command == PlaybackCommandEnum.trackEnded;
  }

  CamsPlaybackState _stateForPlaybackMutationFailure(
    Failure failure, {
    bool? isOverriding,
    String? prefix,
    String? displayMessage,
    bool affectsPlaybackStart = true,
  }) {
    final resolvedDisplayMessage =
        displayMessage ?? ErrorMapper.displayMessageForFailure(failure);
    final errorMessage = prefix == null || prefix.isEmpty
        ? resolvedDisplayMessage
        : '$prefix: $resolvedDisplayMessage';

    if (affectsPlaybackStart && _isBrandWalletPlaybackBlock(failure)) {
      final blockedMessage = _brandPlaybackBlockMessage(failure);
      return state.copyWith(
        isOverriding: isOverriding,
        errorMessage: blockedMessage,
        playbackBlockedMessage: blockedMessage,
        playbackBlockedBrandId: state.playbackState?.brandId,
      );
    }

    return state.copyWith(
      isOverriding: isOverriding,
      errorMessage: errorMessage,
    );
  }

  bool _isBrandWalletPlaybackBlock(Failure failure) {
    final backendCode = failure.backendCode?.trim().toLowerCase();
    final message = failure.message.trim().toLowerCase();
    return failure.kind == FailureKind.business &&
        backendCode == 'businessruleviolation' &&
        (message.contains('wallet') ||
            message.contains('balance') ||
            message.contains('quota') ||
            message.contains('token') ||
            message.contains('top up') ||
            message.contains('negative'));
  }

  String _brandPlaybackBlockMessage(Failure failure) {
    final serverMessage = ErrorMapper.displayMessageForFailure(failure);
    final role = sessionCubit.state.currentRole;
    if (role == UserRole.brandManager) {
      return serverMessage;
    }
    return 'Playback is unavailable because the brand wallet needs attention. Contact your brand manager.';
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

  String _resolveSchedulingUpdateErrorMessage(
    Failure failure, {
    required bool attemptedEnable,
  }) {
    final displayMessage = ErrorMapper.displayMessageForFailure(failure);
    final normalizedBackendCode = failure.backendCode?.trim().toLowerCase();
    final normalizedMessage = failure.message.trim().toLowerCase();
    final isMissingActiveSlotViolation = attemptedEnable &&
        failure.statusCode == 422 &&
        (normalizedBackendCode == 'businessruleviolation' ||
            normalizedMessage.contains(
              'scheduling mode can only be activated when there is an active space scheduling slot',
            ));

    if (isMissingActiveSlotViolation) {
      return 'Runtime status cannot be turned on right now because this space has no active schedule slot for the current time.';
    }

    return 'Update scheduling failed: $displayMessage';
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

  String _describeFailure(Failure failure) {
    return [
      'kind=${failure.kind.name}',
      'status=${failure.statusCode?.toString() ?? '-'}',
      'backendCode=${failure.backendCode ?? '-'}',
      'retryable=${failure.isRetryable}',
      'message="${failure.message}"',
      if (failure.debugMessage != null && failure.debugMessage!.isNotEmpty)
        'debug="${failure.debugMessage}"',
    ].join(' ');
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
        'manual=${playbackState.isManualOverride} '
        'scheduling=${playbackState.isScheduling} '
        'queueCount=${playbackState.spaceQueueItems.length} '
        'queue=[$queuePreview]';
  }
}
