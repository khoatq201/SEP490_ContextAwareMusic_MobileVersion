import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/enums/playback_command_enum.dart';
import '../../../../core/enums/queue_insert_mode_enum.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/space_playback_state.dart';
import '../../domain/entities/space_queue_state_item.dart';
import '../../domain/usecases/get_space_state.dart';
import '../../domain/usecases/queue_usecases.dart';
import '../../domain/usecases/send_playback_command.dart';
import '../../domain/usecases/update_audio_state.dart';
import '../../domain/usecases/update_scheduling_state.dart';
import 'store_hub_service.dart';

/// Queue-first orchestration layer for CAMS playback.
///
/// This runtime is the only place that merges:
/// - HTTP state snapshots from `GET /api/cams/spaces/state`
/// - SignalR events from StoreHub
/// - queue/playback mutations followed by reconcile polling
///
/// UI state should always be derived from [playbackStateStream] rather than
/// local optimistic queue mutations.
class QueueFirstPlaybackRuntime {
  static const Duration _pendingTrackJumpHoldDuration = Duration(seconds: 5);
  static const Duration _pendingCommandEchoHoldDuration = Duration(seconds: 5);
  static const Duration _queueHydrationReuseWindow =
      Duration(milliseconds: 750);

  QueueFirstPlaybackRuntime({
    required this.getSpaceState,
    required this.queueTracks,
    required this.queuePlaylist,
    required this.reorderQueue,
    required this.removeQueueItems,
    required this.clearQueue,
    required this.getSpaceQueue,
    required this.sendPlaybackCommand,
    required this.updateAudioState,
    required this.updateSchedulingState,
    required this.storeHubService,
  });

  final GetSpaceState getSpaceState;
  final QueueTracks queueTracks;
  final QueuePlaylist queuePlaylist;
  final ReorderQueue reorderQueue;
  final RemoveQueueItems removeQueueItems;
  final ClearQueue clearQueue;
  final GetSpaceQueue getSpaceQueue;
  final SendPlaybackCommand sendPlaybackCommand;
  final UpdateAudioState updateAudioState;
  final UpdateSchedulingState updateSchedulingState;
  final StoreHubService storeHubService;

  final StreamController<SpacePlaybackState> _playbackStateController =
      StreamController<SpacePlaybackState>.broadcast();
  final StreamController<ConnectionStatus> _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();

  StreamSubscription<PlayStreamEvent>? _playStreamSub;
  StreamSubscription<PlaybackCommandEvent>? _playbackCommandSub;
  StreamSubscription<SpacePlaybackState>? _stateSyncSub;
  StreamSubscription<void>? _stopPlaybackSub;
  StreamSubscription<ConnectionStatus>? _connectionSub;

  String? _activeSpaceId;
  String? _activeManagerStoreId;
  bool _usePlaybackDeviceScope = false;
  SpacePlaybackState? _currentState;
  String? _lastFingerprint;
  bool _isBootstrapping = false;
  PlaybackCommandEnum? _pendingTraceCommand;
  double? _pendingTraceSeekPositionSeconds;
  String? _pendingTraceTargetQueueItemId;
  String? _pendingTraceTargetTrackId;
  DateTime? _pendingTraceIssuedAtUtc;
  String? _pendingTrackJumpQueueItemId;
  DateTime? _pendingTrackJumpIssuedAtUtc;
  final Map<String, int> _pendingCommandEchoCounts = <String, int>{};
  final Map<String, DateTime> _pendingCommandEchoIssuedAtUtc =
      <String, DateTime>{};
  String? _queueHydrationInFlightKey;
  Future<Either<Failure, List<SpaceQueueStateItem>>>? _queueHydrationInFlight;
  String? _lastQueueHydrationKey;
  DateTime? _lastQueueHydrationAtUtc;
  List<SpaceQueueStateItem>? _lastQueueHydrationItems;
  int _queueHydrationCacheEpoch = 0;

  Stream<SpacePlaybackState> get playbackStateStream =>
      _playbackStateController.stream;

  Stream<ConnectionStatus> get connectionStatusStream =>
      _connectionStatusController.stream;

  SpacePlaybackState? get currentState => _currentState;

  bool get isConnected => storeHubService.isConnected;

  Future<Either<Failure, SpacePlaybackState>> bootstrap({
    required String spaceId,
    required bool usePlaybackDeviceScope,
    String? managerStoreId,
  }) async {
    _debugLog(
      'bootstrap spaceId=$spaceId playbackDevice=$usePlaybackDeviceScope '
      'managerStoreId=${managerStoreId ?? '-'}',
    );
    _ensureHubSubscriptions();

    final isSpaceChanged = _activeSpaceId != null &&
        _activeSpaceId!.toLowerCase() != spaceId.toLowerCase();
    final isManagerRoomChanged = _activeManagerStoreId != managerStoreId;

    if (isSpaceChanged && _activeSpaceId != null) {
      try {
        await storeHubService.leaveSpace(_activeSpaceId!);
      } catch (_) {
        // Best effort when switching spaces.
      }
    }

    if (isManagerRoomChanged && _activeManagerStoreId != null) {
      try {
        await storeHubService.leaveManagerRoom(_activeManagerStoreId!);
      } catch (_) {
        // Best effort when switching rooms.
      }
    }

    if (isSpaceChanged || isManagerRoomChanged) {
      _currentState = null;
      _lastFingerprint = null;
      _clearPendingTraceCommand();
      _clearPendingTrackJump();
      _clearPendingCommandEchoes();
      _clearQueueHydrationCache();
    }

    _activeSpaceId = spaceId;
    _activeManagerStoreId = managerStoreId;
    _usePlaybackDeviceScope = usePlaybackDeviceScope;
    _isBootstrapping = true;

    try {
      await storeHubService.connect();
      await storeHubService.joinSpace(spaceId);
      if (managerStoreId != null && managerStoreId.isNotEmpty) {
        await storeHubService.joinManagerRoom(managerStoreId);
      }
      return await refreshState();
    } catch (e) {
      return Left(ServerFailure('Failed to connect StoreHub: $e'));
    } finally {
      _isBootstrapping = false;
    }
  }

  Future<void> reset() async {
    final activeSpaceId = _activeSpaceId;
    final activeManagerStoreId = _activeManagerStoreId;

    _activeSpaceId = null;
    _activeManagerStoreId = null;
    _currentState = null;
    _lastFingerprint = null;
    _clearPendingTrackJump();
    _clearPendingCommandEchoes();
    _clearQueueHydrationCache();

    if (activeSpaceId != null) {
      try {
        await storeHubService.leaveSpace(activeSpaceId);
      } catch (_) {
        // Best effort.
      }
    }

    if (activeManagerStoreId != null) {
      try {
        await storeHubService.leaveManagerRoom(activeManagerStoreId);
      } catch (_) {
        // Best effort.
      }
    }
  }

  Future<Either<Failure, SpacePlaybackState>> refreshState({
    bool silent = false,
  }) async {
    final activeSpaceId = _activeSpaceId;
    if (activeSpaceId == null || activeSpaceId.isEmpty) {
      return const Left(
          ServerFailure('No active space is attached to runtime.'));
    }

    final result = await getSpaceState(
      activeSpaceId,
      usePlaybackDeviceScope: _usePlaybackDeviceScope,
    );

    return await result.fold(
      (failure) async {
        _debugLog('refreshState failed: ${_describeFailure(failure)}');
        return Left(failure);
      },
      (playbackState) async {
        final normalizedState = await _normalizeIncomingState(playbackState);
        final guardedState = _applyPendingTrackJumpGuard(normalizedState);
        _maybeTraceStateSync(
          source: 'http-refresh',
          playbackState: guardedState,
        );
        if (!silent) {
          _debugLog('refreshState -> ${_describePlaybackState(guardedState)}');
        }
        _emitState(guardedState);
        return Right(guardedState);
      },
    );
  }

  Future<Either<Failure, void>> playTrack({
    required String trackId,
    required QueueInsertModeEnum requestedMode,
    required bool clearExistingQueue,
    String? reason,
  }) async {
    final activeSpaceId = _activeSpaceId;
    if (activeSpaceId == null || activeSpaceId.isEmpty) {
      return const Left(
          ServerFailure('No active space is attached to runtime.'));
    }

    _debugLog(
      'playTrack request spaceId=$activeSpaceId trackId=$trackId '
      'mode=${requestedMode.name} clear=$clearExistingQueue '
      'reason="${reason ?? '-'}"',
    );
    final baselineFingerprint = _lastFingerprint;
    _clearQueueHydrationCache();
    final result = await queueTracks(
      QueueTracksParams(
        spaceId: activeSpaceId,
        trackIds: [trackId],
        mode: requestedMode,
        isClearExistingQueue: clearExistingQueue,
        reason: reason,
        usePlaybackDeviceScope: _usePlaybackDeviceScope,
      ),
    );

    return result.fold(
      Left.new,
      (_) async {
        _debugLog('playTrack ACK received');
        unawaited(
            _refreshAfterMutation(baselineFingerprint: baselineFingerprint));
        return const Right(null);
      },
    );
  }

  Future<Either<Failure, void>> playPlaylist({
    required String playlistId,
    required QueueInsertModeEnum requestedMode,
    required bool clearExistingQueue,
    String? reason,
  }) async {
    final activeSpaceId = _activeSpaceId;
    if (activeSpaceId == null || activeSpaceId.isEmpty) {
      return const Left(
          ServerFailure('No active space is attached to runtime.'));
    }

    _debugLog(
      'playPlaylist request spaceId=$activeSpaceId playlistId=$playlistId '
      'mode=${requestedMode.name} clear=$clearExistingQueue '
      'reason="${reason ?? '-'}"',
    );
    final baselineFingerprint = _lastFingerprint;
    _clearQueueHydrationCache();
    final result = await queuePlaylist(
      QueuePlaylistParams(
        spaceId: activeSpaceId,
        playlistId: playlistId,
        mode: requestedMode,
        isClearExistingQueue: clearExistingQueue,
        reason: reason,
        usePlaybackDeviceScope: _usePlaybackDeviceScope,
      ),
    );

    return result.fold(
      Left.new,
      (_) async {
        _debugLog('playPlaylist ACK received');
        unawaited(
            _refreshAfterMutation(baselineFingerprint: baselineFingerprint));
        return const Right(null);
      },
    );
  }

  Future<Either<Failure, void>> reorderQueueItems({
    required List<String> queueItemIds,
  }) async {
    final activeSpaceId = _activeSpaceId;
    if (activeSpaceId == null || activeSpaceId.isEmpty) {
      return const Left(
          ServerFailure('No active space is attached to runtime.'));
    }

    final baselineFingerprint = _lastFingerprint;
    _clearQueueHydrationCache();
    final result = await reorderQueue(
      ReorderQueueParams(
        spaceId: activeSpaceId,
        queueItemIds: queueItemIds,
        usePlaybackDeviceScope: _usePlaybackDeviceScope,
      ),
    );

    return result.fold(
      Left.new,
      (_) async {
        unawaited(
            _refreshAfterMutation(baselineFingerprint: baselineFingerprint));
        return const Right(null);
      },
    );
  }

  Future<Either<Failure, void>> removeQueueEntries({
    required List<String> queueItemIds,
  }) async {
    final activeSpaceId = _activeSpaceId;
    if (activeSpaceId == null || activeSpaceId.isEmpty) {
      return const Left(
          ServerFailure('No active space is attached to runtime.'));
    }

    final baselineFingerprint = _lastFingerprint;
    _clearQueueHydrationCache();
    final result = await removeQueueItems(
      RemoveQueueItemsParams(
        spaceId: activeSpaceId,
        queueItemIds: queueItemIds,
        usePlaybackDeviceScope: _usePlaybackDeviceScope,
      ),
    );

    return result.fold(
      Left.new,
      (_) async {
        unawaited(
            _refreshAfterMutation(baselineFingerprint: baselineFingerprint));
        return const Right(null);
      },
    );
  }

  Future<Either<Failure, void>> clearQueueItems() async {
    final activeSpaceId = _activeSpaceId;
    if (activeSpaceId == null || activeSpaceId.isEmpty) {
      return const Left(
          ServerFailure('No active space is attached to runtime.'));
    }

    final baselineFingerprint = _lastFingerprint;
    _clearQueueHydrationCache();
    final result = await clearQueue(
      QueueScopeParams(
        spaceId: activeSpaceId,
        usePlaybackDeviceScope: _usePlaybackDeviceScope,
      ),
    );

    return result.fold(
      Left.new,
      (_) async {
        _emitState(_buildClearedQueueState(activeSpaceId));
        unawaited(
            _refreshAfterMutation(baselineFingerprint: baselineFingerprint));
        return const Right(null);
      },
    );
  }

  Future<Either<Failure, void>> sendCommand({
    required PlaybackCommandEnum command,
    double? seekPositionSeconds,
    String? targetQueueItemId,
    String? targetTrackId,
  }) async {
    final activeSpaceId = _activeSpaceId;
    if (activeSpaceId == null || activeSpaceId.isEmpty) {
      return const Left(
          ServerFailure('No active space is attached to runtime.'));
    }

    final baselineFingerprint = _lastFingerprint;
    _traceLog(
      'API_COMMAND_PIPELINE '
      'spaceId=$activeSpaceId '
      'scope=${_usePlaybackDeviceScope ? 'playback_device' : 'manager'} '
      'command=${command.name} '
      'seek=${seekPositionSeconds?.toStringAsFixed(2) ?? '-'} '
      'targetQueueItemId=${targetQueueItemId ?? '-'} '
      'targetTrackId=${targetTrackId ?? '-'}',
    );
    if (_isTrackJumpCommand(command)) {
      _rememberPendingCommandEcho(
        command: command,
        seekPositionSeconds: seekPositionSeconds,
        targetQueueItemId: targetQueueItemId,
        targetTrackId: targetTrackId,
      );
    }
    final result = await sendPlaybackCommand(
      spaceId: activeSpaceId,
      command: command,
      seekPositionSeconds: seekPositionSeconds,
      targetQueueItemId: targetQueueItemId,
      targetTrackId: targetTrackId,
      usePlaybackDeviceScope: _usePlaybackDeviceScope,
    );

    return result.fold(
      (failure) {
        if (_isTrackJumpCommand(command)) {
          _forgetPendingCommandEcho(
            command: command,
            seekPositionSeconds: seekPositionSeconds,
            targetQueueItemId: targetQueueItemId,
            targetTrackId: targetTrackId,
          );
        }
        _traceLog(
          'API_COMMAND_HTTP_FAIL '
          'spaceId=$activeSpaceId '
          'command=${command.name} '
          'message=${failure.message}',
        );
        return Left(failure);
      },
      (_) async {
        _traceLog(
          'API_COMMAND_HTTP_OK '
          'spaceId=$activeSpaceId '
          'command=${command.name}',
        );
        _rememberPendingTraceCommand(
          command: command,
          seekPositionSeconds: seekPositionSeconds,
          targetQueueItemId: targetQueueItemId,
          targetTrackId: targetTrackId,
        );
        if (_isLocallyPatchableCommand(command) &&
            !_isTrackJumpCommand(command)) {
          final patchedState = _applyPlaybackCommandPatch(
            current: _currentState,
            command: command,
            seekPositionSeconds: seekPositionSeconds,
            targetQueueItemId: targetQueueItemId,
            targetTrackId: targetTrackId,
          );
          if (patchedState != null) {
            _rememberPendingCommandEcho(
              command: command,
              seekPositionSeconds: seekPositionSeconds,
              targetQueueItemId: targetQueueItemId,
              targetTrackId: targetTrackId,
            );
            _emitState(patchedState);
          }
        }
        unawaited(
            _refreshAfterMutation(baselineFingerprint: baselineFingerprint));
        return const Right(null);
      },
    );
  }

  Future<Either<Failure, void>> patchAudioState({
    int? volumePercent,
    bool? isMuted,
    int? queueEndBehavior,
    bool? usePlaybackDeviceScope,
  }) async {
    final activeSpaceId = _activeSpaceId;
    if (activeSpaceId == null || activeSpaceId.isEmpty) {
      return const Left(
          ServerFailure('No active space is attached to runtime.'));
    }

    final baselineFingerprint = _lastFingerprint;
    final result = await updateAudioState(
      UpdateAudioStateParams(
        spaceId: activeSpaceId,
        volumePercent: volumePercent,
        isMuted: isMuted,
        queueEndBehavior: queueEndBehavior,
        usePlaybackDeviceScope:
            usePlaybackDeviceScope ?? _usePlaybackDeviceScope,
      ),
    );

    return result.fold(
      Left.new,
      (_) async {
        final patchedState = _applyAudioStatePatch(
          current: _currentState,
          volumePercent: volumePercent,
          isMuted: isMuted,
          queueEndBehavior: queueEndBehavior,
        );
        if (patchedState != null) {
          _emitState(patchedState);
        }
        unawaited(
            _refreshAfterMutation(baselineFingerprint: baselineFingerprint));
        return const Right(null);
      },
    );
  }

  Future<Either<Failure, void>> patchSchedulingState({
    required bool isScheduling,
    bool? usePlaybackDeviceScope,
  }) async {
    final activeSpaceId = _activeSpaceId;
    if (activeSpaceId == null || activeSpaceId.isEmpty) {
      return const Left(
          ServerFailure('No active space is attached to runtime.'));
    }

    final baselineFingerprint = _lastFingerprint;
    final result = await updateSchedulingState(
      UpdateSchedulingStateParams(
        spaceId: activeSpaceId,
        isScheduling: isScheduling,
        usePlaybackDeviceScope:
            usePlaybackDeviceScope ?? _usePlaybackDeviceScope,
      ),
    );

    return result.fold(
      Left.new,
      (_) async {
        final current = _currentState;
        if (current != null) {
          _emitState(current.copyWith(isScheduling: isScheduling));
        }
        unawaited(
            _refreshAfterMutation(baselineFingerprint: baselineFingerprint));
        return const Right(null);
      },
    );
  }

  Future<void> dispose() async {
    await reset();
    await _playStreamSub?.cancel();
    await _playbackCommandSub?.cancel();
    await _stateSyncSub?.cancel();
    await _stopPlaybackSub?.cancel();
    await _connectionSub?.cancel();
    await _playbackStateController.close();
    await _connectionStatusController.close();
  }

  void _ensureHubSubscriptions() {
    if (_playStreamSub != null) return;

    _playStreamSub = storeHubService.onPlayStream.listen((event) {
      if (!_isActiveSpace(event.spaceId)) return;
      _debugLog(
        'hub PlayStream spaceId=${event.spaceId} '
        'transition=${event.transitionType.name} '
        'queueItemId=${event.currentQueueItemId ?? '-'} '
        'trackId=${event.trackId ?? '-'} '
        'trackName=${event.trackName ?? '-'} '
        'hls=${event.hlsUrl}',
      );
      // Remote queue inserts can arrive before GET /state reflects the new
      // queue snapshot. Reuse the mutation reconcile loop so we do not miss
      // pending queue updates emitted by another device.
      unawaited(_refreshAfterMutation(baselineFingerprint: _lastFingerprint));
    });

    _playbackCommandSub = storeHubService.onPlaybackCommand.listen((event) {
      if (!_isActiveSpace(event.spaceId)) return;
      _traceLog(
        'SIGNALR_PLAYBACK_COMMAND '
        'spaceId=${event.spaceId} '
        'command=${event.command.name} '
        'seek=${event.seekPositionSeconds?.toStringAsFixed(2) ?? '-'} '
        'targetQueueItemId=${event.targetQueueItemId ?? '-'} '
        'targetTrackId=${event.targetTrackId ?? '-'}',
      );
      _debugLog(
        'hub PlaybackCommand spaceId=${event.spaceId} '
        'command=${event.command.name} '
        'seek=${event.seekPositionSeconds?.toStringAsFixed(2) ?? '-'} '
        'targetQueueItemId=${event.targetQueueItemId ?? '-'} '
        'targetTrackId=${event.targetTrackId ?? '-'}',
      );

      if (_consumePendingCommandEcho(
        command: event.command,
        seekPositionSeconds: event.seekPositionSeconds,
        targetQueueItemId: event.targetQueueItemId,
        targetTrackId: event.targetTrackId,
      )) {
        _debugLog(
          'ignore local command echo command=${event.command.name} '
          'targetQueueItemId=${event.targetQueueItemId ?? '-'} '
          'targetTrackId=${event.targetTrackId ?? '-'}',
        );
        return;
      }

      if (_isTrackJumpCommand(event.command)) {
        unawaited(refreshState(silent: true));
        return;
      }

      if (_isLocallyPatchableCommand(event.command)) {
        final patchedState = _applyPlaybackCommandPatch(
          current: _currentState,
          command: event.command,
          seekPositionSeconds: event.seekPositionSeconds,
          targetQueueItemId: event.targetQueueItemId,
          targetTrackId: event.targetTrackId,
        );
        if (patchedState != null) {
          _emitState(patchedState);
        } else {
          unawaited(refreshState(silent: true));
        }
      } else {
        unawaited(refreshState(silent: true));
      }
    });

    _stateSyncSub = storeHubService.onSpaceStateSync.listen((playbackState) {
      if (!_isActiveSpace(playbackState.spaceId)) return;
      _debugLog(
          'hub SpaceStateSync raw -> ${_describePlaybackState(playbackState)}');
      unawaited(_consumeAuthoritativeState(playbackState));
    });

    _stopPlaybackSub = storeHubService.onStopPlayback.listen((_) {
      final activeSpaceId = _activeSpaceId;
      if (activeSpaceId == null || activeSpaceId.isEmpty) return;

      _emitState(SpacePlaybackState(spaceId: activeSpaceId));
    });

    _connectionSub = storeHubService.onConnectionStatus.listen((status) {
      _connectionStatusController.add(status);
      if (status == ConnectionStatus.connected) {
        // Propagate measured clock drift to seek-offset calculations.
        SpacePlaybackState.serverClockOffsetMs =
            storeHubService.serverClockOffsetMs;
        if (_activeSpaceId != null && !_isBootstrapping) {
          unawaited(refreshState(silent: true));
        }
      }
    });
  }

  bool _isActiveSpace(String? spaceId) {
    if (spaceId == null || _activeSpaceId == null) return false;
    return spaceId.toLowerCase() == _activeSpaceId!.toLowerCase();
  }

  Future<void> _consumeAuthoritativeState(
    SpacePlaybackState playbackState,
  ) async {
    final normalizedState = await _normalizeIncomingState(playbackState);
    final guardedState = _applyPendingTrackJumpGuard(normalizedState);
    _maybeTraceStateSync(
      source: 'signalr-state-sync',
      playbackState: guardedState,
    );
    _emitState(guardedState);
  }

  Future<SpacePlaybackState> _normalizeIncomingState(
    SpacePlaybackState playbackState,
  ) async {
    var normalizedState = _normalizePlaybackStateForClientClock(
      incoming: playbackState,
      current: _currentState,
    );
    normalizedState = _preserveExplainabilityFallback(
      incoming: normalizedState,
      current: _currentState,
    );

    if (_shouldHydrateQueueSnapshot(normalizedState)) {
      final queueResult = await _hydrateQueueSnapshot(normalizedState);
      normalizedState = queueResult.fold(
        (failure) {
          _debugLog(
            'hydrate queue snapshot failed: ${_describeFailure(failure)}',
          );
          return normalizedState;
        },
        (queueItems) => queueItems.isEmpty
            ? normalizedState
            : _copyWithQueue(
                source: normalizedState,
                queueItems: _sortQueueItems(queueItems),
              ),
      );
    }

    return normalizedState;
  }

  SpacePlaybackState _preserveExplainabilityFallback({
    required SpacePlaybackState incoming,
    required SpacePlaybackState? current,
  }) {
    if (incoming.explainability?.hasAnyData == true) return incoming;
    final currentExplainability = current?.explainability;
    if (currentExplainability?.hasAnyData != true) return incoming;

    final incomingMood = incoming.moodName?.trim().toLowerCase();
    final currentMood = (currentExplainability!.moodName ?? current?.moodName)
        ?.trim()
        .toLowerCase();
    if (incomingMood != null &&
        incomingMood.isNotEmpty &&
        currentMood != null &&
        currentMood.isNotEmpty &&
        incomingMood != currentMood) {
      return incoming;
    }

    return incoming.copyWith(explainability: currentExplainability);
  }

  SpacePlaybackState _applyPendingTrackJumpGuard(
    SpacePlaybackState incoming,
  ) {
    final pendingQueueItemId = _pendingTrackJumpQueueItemId;
    final pendingIssuedAtUtc = _pendingTrackJumpIssuedAtUtc;
    if (pendingQueueItemId == null || pendingIssuedAtUtc == null) {
      return incoming;
    }

    final pendingAge = DateTime.now().toUtc().difference(pendingIssuedAtUtc);
    if (pendingAge > _pendingTrackJumpHoldDuration) {
      _clearPendingTrackJump();
      return incoming;
    }

    final incomingQueueItemId = incoming.effectiveQueueItemId;
    if (incomingQueueItemId != null &&
        incomingQueueItemId.toLowerCase() == pendingQueueItemId.toLowerCase()) {
      _clearPendingTrackJump();
      return incoming;
    }

    final current = _currentState;
    if (current == null ||
        current.effectiveQueueItemId?.toLowerCase() !=
            pendingQueueItemId.toLowerCase()) {
      return incoming;
    }

    _debugLog(
      'hold stale state while track jump is pending '
      'target=$pendingQueueItemId incoming=${incomingQueueItemId ?? '-'}',
    );
    return current.copyWith(
      isPaused: incoming.isPaused,
      pausePositionSeconds: incoming.pausePositionSeconds,
      clearPausePositionSeconds: incoming.pausePositionSeconds == null,
      seekOffsetSeconds:
          incoming.seekOffsetSeconds ?? current.seekOffsetSeconds,
      volumePercent: incoming.volumePercent,
      isIotDeviceAssigned: incoming.isIotDeviceAssigned,
      isIotDeviceOffline: incoming.isIotDeviceOffline,
      isMuted: incoming.isMuted,
      queueEndBehavior: incoming.queueEndBehavior,
      manualOverrideRemainingSeconds: incoming.manualOverrideRemainingSeconds,
      manualOverrideTtlSeconds: incoming.manualOverrideTtlSeconds,
      manualOverrideExpiresAtUtc: incoming.manualOverrideExpiresAtUtc,
    );
  }

  Future<void> _refreshAfterMutation({
    required String? baselineFingerprint,
  }) async {
    _debugLog('reconcile after mutation started');
    await refreshState(silent: true);
    if (baselineFingerprint == null ||
        _lastFingerprint != baselineFingerprint) {
      _debugLog('reconcile detected immediate state change');
      return;
    }

    for (var attempt = 0; attempt < 3; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (_activeSpaceId == null) return;
      await refreshState(silent: true);
      if (_lastFingerprint != baselineFingerprint) {
        _debugLog('reconcile changed on retry ${attempt + 1}');
        return;
      }
    }
    _debugLog('reconcile finished without fingerprint change');
  }

  void _emitState(SpacePlaybackState playbackState) {
    final fingerprint = _fingerprintFor(playbackState);
    _currentState = playbackState;
    if (_lastFingerprint == fingerprint) return;

    _lastFingerprint = fingerprint;
    _debugLog('emitState ${_describePlaybackState(playbackState)}');
    _playbackStateController.add(playbackState);
  }

  String _fingerprintFor(SpacePlaybackState playbackState) {
    final queueItems = [...playbackState.spaceQueueItems]
      ..sort((a, b) => a.position.compareTo(b.position));
    final queueFingerprint = queueItems
        .map((item) => [
              item.queueItemId,
              item.trackId,
              item.position,
              item.queueStatus,
              item.hlsUrl ?? '',
              item.coverImageUrl ?? '',
            ].join(':'))
        .join('|');

    return [
      playbackState.spaceId,
      playbackState.currentIdentityId ?? '',
      playbackState.pendingQueueItemId ?? '',
      playbackState.currentDisplayName ?? '',
      playbackState.currentPlaylistName ?? '',
      playbackState.effectiveHlsUrl ?? '',
      playbackState.isManualOverride ? '1' : '0',
      playbackState.overrideMode?.value.toString() ?? '',
      playbackState.overrideReason ?? '',
      playbackState.manualOverrideActivatedAtUtc?.toUtc().toIso8601String() ??
          '',
      playbackState.manualOverrideExpiresAtUtc?.toUtc().toIso8601String() ?? '',
      playbackState.manualOverrideTtlSeconds?.toString() ?? '',
      playbackState.manualOverrideRemainingSeconds?.toString() ?? '',
      playbackState.isScheduling ? '1' : '0',
      playbackState.schedulingSlotId ?? '',
      playbackState.schedulingSlotOrigin?.value.toString() ?? '',
      playbackState.schedulingEndsAtUtc?.toUtc().toIso8601String() ?? '',
      playbackState.schedulingRemainingSeconds?.toString() ?? '',
      playbackState.isPaused ? '1' : '0',
      playbackState.startedAtUtc?.toUtc().toIso8601String() ?? '',
      playbackState.seekOffsetSeconds?.toStringAsFixed(3) ?? '',
      playbackState.pausePositionSeconds?.toString() ?? '',
      playbackState.volumePercent.toString(),
      playbackState.isIotDeviceAssigned == null
          ? ''
          : (playbackState.isIotDeviceAssigned! ? '1' : '0'),
      playbackState.isIotDeviceOffline ? '1' : '0',
      playbackState.isMuted ? '1' : '0',
      playbackState.queueEndBehavior.toString(),
      playbackState.explainability?.moodName ?? '',
      playbackState.explainability?.recommendedBpmMin?.toString() ?? '',
      playbackState.explainability?.recommendedBpmMax?.toString() ?? '',
      playbackState.explainability?.recommendedBpmTarget?.toString() ?? '',
      playbackState.explainability?.triggeredRule ?? '',
      playbackState.explainability?.reason ?? '',
      playbackState.explainability?.usedMoodOnlyFallback?.toString() ?? '',
      playbackState.explainability?.fuzzyProfileName ?? '',
      playbackState.explainability?.fuzzyProfileTemplate ?? '',
      queueFingerprint,
    ].join('||');
  }

  bool _shouldHydrateQueueSnapshot(SpacePlaybackState playbackState) {
    final hasQueueIdentity =
        (playbackState.currentQueueItemId?.isNotEmpty ?? false) ||
            (playbackState.pendingQueueItemId?.isNotEmpty ?? false);
    final queueItems = playbackState.spaceQueueItems;
    if (queueItems.isEmpty) {
      return hasQueueIdentity || playbackState.hasPlayableHls;
    }

    final currentQueueItemId = playbackState.currentQueueItemId;
    if (currentQueueItemId != null &&
        currentQueueItemId.isNotEmpty &&
        !queueItems.any((item) => item.queueItemId == currentQueueItemId)) {
      return true;
    }

    final pendingQueueItemId = playbackState.pendingQueueItemId;
    if (pendingQueueItemId != null &&
        pendingQueueItemId.isNotEmpty &&
        !queueItems.any((item) => item.queueItemId == pendingQueueItemId)) {
      return true;
    }

    final sortedItems = _sortQueueItems(queueItems);
    final firstPosition = sortedItems.first.position;
    final hasPositionGap = firstPosition > 1;
    final looksLikeSmallWindow = sortedItems.length <= 3 &&
        (hasQueueIdentity || playbackState.hasPlayableHls);
    return hasPositionGap || looksLikeSmallWindow;
  }

  Future<Either<Failure, List<SpaceQueueStateItem>>> _hydrateQueueSnapshot(
    SpacePlaybackState playbackState,
  ) {
    final key = _queueHydrationKey(playbackState);
    final nowUtc = DateTime.now().toUtc();

    final cachedAt = _lastQueueHydrationAtUtc;
    final cachedItems = _lastQueueHydrationItems;
    if (_lastQueueHydrationKey == key &&
        cachedAt != null &&
        cachedItems != null &&
        nowUtc.difference(cachedAt) <= _queueHydrationReuseWindow) {
      _debugLog('reuse hydrated queue snapshot key=$key');
      return Future.value(Right(cachedItems));
    }

    final inFlight = _queueHydrationInFlight;
    if (_queueHydrationInFlightKey == key && inFlight != null) {
      _debugLog('join in-flight queue hydration key=$key');
      return inFlight;
    }

    final cacheEpoch = _queueHydrationCacheEpoch;
    late final Future<Either<Failure, List<SpaceQueueStateItem>>> future;
    future = getSpaceQueue(
      QueueScopeParams(
        spaceId: playbackState.spaceId,
        usePlaybackDeviceScope: _usePlaybackDeviceScope,
      ),
    ).then((result) {
      result.fold(
        (_) {},
        (queueItems) {
          if (cacheEpoch != _queueHydrationCacheEpoch) return;
          _lastQueueHydrationKey = key;
          _lastQueueHydrationAtUtc = DateTime.now().toUtc();
          _lastQueueHydrationItems = _sortQueueItems(queueItems);
        },
      );
      return result;
    }).whenComplete(() {
      if (_queueHydrationInFlight == future) {
        _queueHydrationInFlight = null;
        _queueHydrationInFlightKey = null;
      }
    });

    _queueHydrationInFlightKey = key;
    _queueHydrationInFlight = future;
    return future;
  }

  String _queueHydrationKey(SpacePlaybackState playbackState) {
    return [
      playbackState.spaceId.toLowerCase(),
      _usePlaybackDeviceScope ? 'device' : 'manager',
      playbackState.currentQueueItemId ?? '',
      playbackState.pendingQueueItemId ?? '',
      playbackState.hlsUrl ?? '',
    ].join('|');
  }

  void _clearQueueHydrationCache() {
    _queueHydrationInFlight = null;
    _queueHydrationInFlightKey = null;
    _lastQueueHydrationKey = null;
    _lastQueueHydrationAtUtc = null;
    _lastQueueHydrationItems = null;
    _queueHydrationCacheEpoch += 1;
  }

  List<SpaceQueueStateItem> _sortQueueItems(
    List<SpaceQueueStateItem> queueItems,
  ) {
    final sortedItems = [...queueItems]
      ..sort((a, b) => a.position.compareTo(b.position));
    return List<SpaceQueueStateItem>.unmodifiable(sortedItems);
  }

  SpacePlaybackState _copyWithQueue({
    required SpacePlaybackState source,
    required List<SpaceQueueStateItem> queueItems,
  }) {
    return source.copyWith(spaceQueueItems: queueItems);
  }

  bool _isLocallyPatchableCommand(PlaybackCommandEnum command) {
    return command == PlaybackCommandEnum.pause ||
        command == PlaybackCommandEnum.resume ||
        command == PlaybackCommandEnum.seek ||
        command == PlaybackCommandEnum.seekForward ||
        command == PlaybackCommandEnum.seekBackward ||
        command == PlaybackCommandEnum.skipNext ||
        command == PlaybackCommandEnum.skipPrevious ||
        command == PlaybackCommandEnum.skipToTrack ||
        command == PlaybackCommandEnum.trackEnded;
  }

  bool _isTrackJumpCommand(PlaybackCommandEnum command) {
    return command == PlaybackCommandEnum.skipNext ||
        command == PlaybackCommandEnum.skipPrevious ||
        command == PlaybackCommandEnum.skipToTrack ||
        command == PlaybackCommandEnum.trackEnded;
  }

  SpacePlaybackState? _applyPlaybackCommandPatch({
    required SpacePlaybackState? current,
    required PlaybackCommandEnum command,
    required double? seekPositionSeconds,
    String? targetQueueItemId,
    String? targetTrackId,
  }) {
    if (current == null) return null;

    final nowUtc = DateTime.now().toUtc();
    final safeSeek = seekPositionSeconds == null || seekPositionSeconds < 0
        ? 0.0
        : seekPositionSeconds;
    final effectiveOffset = seekPositionSeconds ?? current.effectiveSeekOffset;

    switch (command) {
      case PlaybackCommandEnum.pause:
        return current.copyWith(
          isPaused: true,
          pausePositionSeconds: effectiveOffset.round(),
          seekOffsetSeconds: effectiveOffset,
        );
      case PlaybackCommandEnum.resume:
        return current.copyWith(
          startedAtUtc: nowUtc.subtract(
            Duration(milliseconds: (effectiveOffset * 1000).round()),
          ),
          isPaused: false,
          clearPausePositionSeconds: true,
          seekOffsetSeconds: effectiveOffset,
        );
      case PlaybackCommandEnum.seek:
      case PlaybackCommandEnum.seekForward:
      case PlaybackCommandEnum.seekBackward:
        return current.copyWith(
          startedAtUtc: current.isPaused
              ? current.startedAtUtc
              : nowUtc.subtract(
                  Duration(milliseconds: (safeSeek * 1000).round()),
                ),
          pausePositionSeconds: current.isPaused ? safeSeek.round() : null,
          clearPausePositionSeconds: !current.isPaused,
          seekOffsetSeconds: safeSeek,
        );
      case PlaybackCommandEnum.skipNext:
      case PlaybackCommandEnum.skipPrevious:
      case PlaybackCommandEnum.skipToTrack:
      case PlaybackCommandEnum.trackEnded:
        final targetQueueItem = _resolveCommandTargetQueueItem(
          current: current,
          command: command,
          targetQueueItemId: targetQueueItemId,
          targetTrackId: targetTrackId,
        );
        if (targetQueueItem == null) return null;
        _rememberPendingTrackJump(targetQueueItem.queueItemId);
        return _applyTrackJumpPatch(
          current: current,
          targetQueueItem: targetQueueItem,
          nowUtc: nowUtc,
        );
    }
  }

  SpaceQueueStateItem? _resolveCommandTargetQueueItem({
    required SpacePlaybackState current,
    required PlaybackCommandEnum command,
    String? targetQueueItemId,
    String? targetTrackId,
  }) {
    final sortedItems = current.sortedQueueItems;
    if (sortedItems.isEmpty) return null;

    if (targetQueueItemId != null && targetQueueItemId.isNotEmpty) {
      for (final item in sortedItems) {
        if (item.queueItemId == targetQueueItemId) return item;
      }
    }

    if (targetTrackId != null && targetTrackId.isNotEmpty) {
      for (final item in sortedItems) {
        if (item.trackId == targetTrackId) return item;
      }
    }

    final focusedIndex = sortedItems.indexWhere(
      (item) => item.queueItemId == current.effectiveQueueItemId,
    );
    final fallbackIndex = focusedIndex >= 0
        ? focusedIndex
        : sortedItems.indexWhere(
            (item) => item.queueStatus == SpacePlaybackState.queueStatusPlaying,
          );

    switch (command) {
      case PlaybackCommandEnum.skipNext:
      case PlaybackCommandEnum.trackEnded:
        final nextIndex = fallbackIndex + 1;
        if (fallbackIndex >= 0 && nextIndex < sortedItems.length) {
          return sortedItems[nextIndex];
        }
        return null;
      case PlaybackCommandEnum.skipPrevious:
        final previousIndex = fallbackIndex - 1;
        if (fallbackIndex > 0 && previousIndex < sortedItems.length) {
          return sortedItems[previousIndex];
        }
        return null;
      case PlaybackCommandEnum.skipToTrack:
        return null;
      case PlaybackCommandEnum.pause:
      case PlaybackCommandEnum.resume:
      case PlaybackCommandEnum.seek:
      case PlaybackCommandEnum.seekForward:
      case PlaybackCommandEnum.seekBackward:
        return null;
    }
  }

  SpacePlaybackState _applyTrackJumpPatch({
    required SpacePlaybackState current,
    required SpaceQueueStateItem targetQueueItem,
    required DateTime nowUtc,
  }) {
    final targetHlsUrl = targetQueueItem.hlsUrl?.trim();
    final targetTrackName = targetQueueItem.trackName?.trim();
    final hasTargetHlsUrl = targetHlsUrl != null && targetHlsUrl.isNotEmpty;
    return current.copyWith(
      currentQueueItemId: targetQueueItem.queueItemId,
      currentTrackName: targetTrackName != null && targetTrackName.isNotEmpty
          ? targetTrackName
          : null,
      clearCurrentTrackName: targetTrackName == null || targetTrackName.isEmpty,
      hlsUrl: hasTargetHlsUrl ? targetHlsUrl : null,
      clearHlsUrl: !hasTargetHlsUrl,
      startedAtUtc: nowUtc,
      isPaused: false,
      clearPausePositionSeconds: true,
      seekOffsetSeconds: 0,
      clearPendingQueueItemId: true,
      spaceQueueItems: _markQueueItemPlaying(
        current.spaceQueueItems,
        targetQueueItem.queueItemId,
      ),
    );
  }

  List<SpaceQueueStateItem> _markQueueItemPlaying(
    List<SpaceQueueStateItem> queueItems,
    String targetQueueItemId,
  ) {
    if (queueItems.isEmpty) return queueItems;
    SpaceQueueStateItem? target;
    for (final item in queueItems) {
      if (item.queueItemId == targetQueueItemId) {
        target = item;
        break;
      }
    }
    if (target == null) return queueItems;
    final targetPosition = target.position;

    return queueItems.map((item) {
      final nextStatus = item.queueItemId == targetQueueItemId
          ? SpacePlaybackState.queueStatusPlaying
          : item.position < targetPosition
              ? SpacePlaybackState.queueStatusPlayed
              : SpacePlaybackState.queueStatusPending;
      return SpaceQueueStateItem(
        queueItemId: item.queueItemId,
        trackId: item.trackId,
        trackName: item.trackName,
        position: item.position,
        queueStatus: nextStatus,
        source: item.source,
        hlsUrl: item.hlsUrl,
        coverImageUrl: item.coverImageUrl,
        isReadyToStream: item.isReadyToStream,
      );
    }).toList(growable: false);
  }

  SpacePlaybackState? _applyAudioStatePatch({
    required SpacePlaybackState? current,
    required int? volumePercent,
    required bool? isMuted,
    required int? queueEndBehavior,
  }) {
    if (current == null) return null;

    return current.copyWith(
      volumePercent: volumePercent ?? current.volumePercent,
      isMuted: isMuted ?? current.isMuted,
      queueEndBehavior: queueEndBehavior ?? current.queueEndBehavior,
    );
  }

  SpacePlaybackState _buildClearedQueueState(String spaceId) {
    final current = _currentState;
    if (current == null) {
      return SpacePlaybackState(spaceId: spaceId);
    }

    return current.copyWith(
      spaceId: spaceId,
      clearCurrentQueueItemId: true,
      clearCurrentTrackName: true,
      clearCurrentPlaylistId: true,
      clearCurrentPlaylistName: true,
      clearHlsUrl: true,
      clearStartedAtUtc: true,
      clearExpectedEndAtUtc: true,
      isPaused: false,
      clearPausePositionSeconds: true,
      clearSeekOffsetSeconds: true,
      clearPendingQueueItemId: true,
      clearPendingPlaylistId: true,
      clearPendingOverrideReason: true,
      spaceQueueItems: const [],
    );
  }

  SpacePlaybackState _normalizePlaybackStateForClientClock({
    required SpacePlaybackState incoming,
    required SpacePlaybackState? current,
  }) {
    if (incoming.isPaused) return incoming;

    if (incoming.seekOffsetSeconds != null) {
      final startedAtUtc = DateTime.now().toUtc().subtract(
            Duration(
                milliseconds: (incoming.seekOffsetSeconds! * 1000).round()),
          );
      return incoming.copyWith(
        startedAtUtc: startedAtUtc,
      );
    }

    if (current != null &&
        current.currentQueueItemId == incoming.currentQueueItemId &&
        current.hlsUrl == incoming.hlsUrl &&
        current.startedAtUtc != null &&
        incoming.startedAtUtc == null) {
      return incoming.copyWith(
        startedAtUtc: current.startedAtUtc,
      );
    }

    return incoming;
  }

  void _debugLog(String message) {
    debugPrint('[QueueFirstV2] $message');
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

  void _rememberPendingTraceCommand({
    required PlaybackCommandEnum command,
    double? seekPositionSeconds,
    String? targetQueueItemId,
    String? targetTrackId,
  }) {
    if (!_shouldTraceStateSync(command)) {
      return;
    }
    _pendingTraceCommand = command;
    _pendingTraceSeekPositionSeconds = seekPositionSeconds;
    _pendingTraceTargetQueueItemId = targetQueueItemId;
    _pendingTraceTargetTrackId = targetTrackId;
    _pendingTraceIssuedAtUtc = DateTime.now().toUtc();
  }

  bool _shouldTraceStateSync(PlaybackCommandEnum command) {
    return command == PlaybackCommandEnum.seek ||
        command == PlaybackCommandEnum.seekForward ||
        command == PlaybackCommandEnum.seekBackward ||
        command == PlaybackCommandEnum.trackEnded;
  }

  void _maybeTraceStateSync({
    required String source,
    required SpacePlaybackState playbackState,
  }) {
    final pendingCommand = _pendingTraceCommand;
    if (pendingCommand == null) {
      return;
    }

    final traceLabel = switch (pendingCommand) {
      PlaybackCommandEnum.seek ||
      PlaybackCommandEnum.seekForward ||
      PlaybackCommandEnum.seekBackward =>
        'STATE_SYNC_AFTER_SEEK',
      PlaybackCommandEnum.trackEnded => 'STATE_SYNC_AFTER_TRACK_ENDED',
      _ => null,
    };

    if (traceLabel == null) {
      _clearPendingTraceCommand();
      return;
    }

    final ageMs = _pendingTraceIssuedAtUtc == null
        ? -1
        : DateTime.now()
            .toUtc()
            .difference(_pendingTraceIssuedAtUtc!)
            .inMilliseconds;
    _traceLog(
      '$traceLabel '
      'source=$source '
      'ageMs=$ageMs '
      'command=${pendingCommand.name} '
      'seekRequest=${_pendingTraceSeekPositionSeconds?.toStringAsFixed(2) ?? '-'} '
      'targetQueueItemId=${_pendingTraceTargetQueueItemId ?? '-'} '
      'targetTrackId=${_pendingTraceTargetTrackId ?? '-'} '
      '${_describePlaybackState(playbackState)}',
    );
    _clearPendingTraceCommand();
  }

  void _clearPendingTraceCommand() {
    _pendingTraceCommand = null;
    _pendingTraceSeekPositionSeconds = null;
    _pendingTraceTargetQueueItemId = null;
    _pendingTraceTargetTrackId = null;
    _pendingTraceIssuedAtUtc = null;
  }

  void _rememberPendingTrackJump(String queueItemId) {
    _pendingTrackJumpQueueItemId = queueItemId;
    _pendingTrackJumpIssuedAtUtc = DateTime.now().toUtc();
  }

  void _clearPendingTrackJump() {
    _pendingTrackJumpQueueItemId = null;
    _pendingTrackJumpIssuedAtUtc = null;
  }

  String _commandEchoSignature({
    required PlaybackCommandEnum command,
    double? seekPositionSeconds,
    String? targetQueueItemId,
    String? targetTrackId,
  }) {
    final seekMillis = seekPositionSeconds == null
        ? ''
        : (seekPositionSeconds * 1000).round().toString();
    return [
      command.name,
      seekMillis,
      targetQueueItemId?.trim().toLowerCase() ?? '',
      targetTrackId?.trim().toLowerCase() ?? '',
    ].join('|');
  }

  void _rememberPendingCommandEcho({
    required PlaybackCommandEnum command,
    double? seekPositionSeconds,
    String? targetQueueItemId,
    String? targetTrackId,
  }) {
    _prunePendingCommandEchoes();
    final signature = _commandEchoSignature(
      command: command,
      seekPositionSeconds: seekPositionSeconds,
      targetQueueItemId: targetQueueItemId,
      targetTrackId: targetTrackId,
    );
    _pendingCommandEchoCounts[signature] =
        (_pendingCommandEchoCounts[signature] ?? 0) + 1;
    _pendingCommandEchoIssuedAtUtc[signature] = DateTime.now().toUtc();
  }

  bool _consumePendingCommandEcho({
    required PlaybackCommandEnum command,
    double? seekPositionSeconds,
    String? targetQueueItemId,
    String? targetTrackId,
  }) {
    _prunePendingCommandEchoes();
    final signature = _commandEchoSignature(
      command: command,
      seekPositionSeconds: seekPositionSeconds,
      targetQueueItemId: targetQueueItemId,
      targetTrackId: targetTrackId,
    );
    final count = _pendingCommandEchoCounts[signature] ?? 0;
    if (count <= 0) return false;

    if (count == 1) {
      _pendingCommandEchoCounts.remove(signature);
      _pendingCommandEchoIssuedAtUtc.remove(signature);
    } else {
      _pendingCommandEchoCounts[signature] = count - 1;
    }
    return true;
  }

  void _forgetPendingCommandEcho({
    required PlaybackCommandEnum command,
    double? seekPositionSeconds,
    String? targetQueueItemId,
    String? targetTrackId,
  }) {
    _prunePendingCommandEchoes();
    final signature = _commandEchoSignature(
      command: command,
      seekPositionSeconds: seekPositionSeconds,
      targetQueueItemId: targetQueueItemId,
      targetTrackId: targetTrackId,
    );
    final count = _pendingCommandEchoCounts[signature] ?? 0;
    if (count <= 1) {
      _pendingCommandEchoCounts.remove(signature);
      _pendingCommandEchoIssuedAtUtc.remove(signature);
      return;
    }
    _pendingCommandEchoCounts[signature] = count - 1;
  }

  void _prunePendingCommandEchoes() {
    if (_pendingCommandEchoIssuedAtUtc.isEmpty) return;

    final nowUtc = DateTime.now().toUtc();
    final expiredSignatures = _pendingCommandEchoIssuedAtUtc.entries
        .where((entry) =>
            nowUtc.difference(entry.value) > _pendingCommandEchoHoldDuration)
        .map((entry) => entry.key)
        .toList(growable: false);

    for (final signature in expiredSignatures) {
      _pendingCommandEchoIssuedAtUtc.remove(signature);
      _pendingCommandEchoCounts.remove(signature);
    }
  }

  void _clearPendingCommandEchoes() {
    _pendingCommandEchoCounts.clear();
    _pendingCommandEchoIssuedAtUtc.clear();
  }

  String _describePlaybackState(SpacePlaybackState playbackState) {
    final queuePreview = playbackState.spaceQueueItems
        .take(4)
        .map(
          (item) =>
              '${item.position}:${item.trackName ?? item.trackId}:${item.queueStatus}',
        )
        .join(' | ');
    return 'space=${playbackState.spaceId} '
        'current=${playbackState.currentIdentityId ?? '-'} '
        'pending=${playbackState.pendingQueueItemId ?? '-'} '
        'track=${playbackState.currentDisplayName ?? '-'} '
        'hls=${playbackState.effectiveHlsUrl ?? '-'} '
        'manual=${playbackState.isManualOverride} '
        'scheduling=${playbackState.isScheduling} '
        'paused=${playbackState.isPaused} '
        'queueCount=${playbackState.spaceQueueItems.length} '
        'queue=[$queuePreview]';
  }
}
