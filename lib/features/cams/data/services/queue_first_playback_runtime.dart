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
  String? _pendingTraceTargetTrackId;
  DateTime? _pendingTraceIssuedAtUtc;

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
      return Left(ServerFailure('No active space is attached to runtime.'));
    }

    final result = await getSpaceState(
      activeSpaceId,
      usePlaybackDeviceScope: _usePlaybackDeviceScope,
    );

    return await result.fold(
      (failure) async {
        _debugLog('refreshState failed: ${failure.message}');
        return Left(failure);
      },
      (playbackState) async {
        final normalizedState = await _normalizeIncomingState(playbackState);
        _maybeTraceStateSync(
          source: 'http-refresh',
          playbackState: normalizedState,
        );
        if (!silent) {
          _debugLog(
              'refreshState -> ${_describePlaybackState(normalizedState)}');
        }
        _emitState(normalizedState);
        return Right(normalizedState);
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
      return Left(ServerFailure('No active space is attached to runtime.'));
    }

    _debugLog(
      'playTrack request spaceId=$activeSpaceId trackId=$trackId '
      'mode=${requestedMode.name} clear=$clearExistingQueue '
      'reason="${reason ?? '-'}"',
    );
    final baselineFingerprint = _lastFingerprint;
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
      return Left(ServerFailure('No active space is attached to runtime.'));
    }

    _debugLog(
      'playPlaylist request spaceId=$activeSpaceId playlistId=$playlistId '
      'mode=${requestedMode.name} clear=$clearExistingQueue '
      'reason="${reason ?? '-'}"',
    );
    final baselineFingerprint = _lastFingerprint;
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
      return Left(ServerFailure('No active space is attached to runtime.'));
    }

    final baselineFingerprint = _lastFingerprint;
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
      return Left(ServerFailure('No active space is attached to runtime.'));
    }

    final baselineFingerprint = _lastFingerprint;
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
      return Left(ServerFailure('No active space is attached to runtime.'));
    }

    final baselineFingerprint = _lastFingerprint;
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
    String? targetTrackId,
  }) async {
    final activeSpaceId = _activeSpaceId;
    if (activeSpaceId == null || activeSpaceId.isEmpty) {
      return Left(ServerFailure('No active space is attached to runtime.'));
    }

    final baselineFingerprint = _lastFingerprint;
    _traceLog(
      'API_COMMAND_PIPELINE '
      'spaceId=$activeSpaceId '
      'scope=${_usePlaybackDeviceScope ? 'playback_device' : 'manager'} '
      'command=${command.name} '
      'seek=${seekPositionSeconds?.toStringAsFixed(2) ?? '-'} '
      'targetTrackId=${targetTrackId ?? '-'}',
    );
    final result = await sendPlaybackCommand(
      spaceId: activeSpaceId,
      command: command,
      seekPositionSeconds: seekPositionSeconds,
      targetTrackId: targetTrackId,
      usePlaybackDeviceScope: _usePlaybackDeviceScope,
    );

    return result.fold(
      (failure) {
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
          targetTrackId: targetTrackId,
        );
        if (_isLocallyPatchableCommand(command)) {
          final patchedState = _applyPlaybackCommandPatch(
            current: _currentState,
            command: command,
            seekPositionSeconds: seekPositionSeconds,
          );
          if (patchedState != null) {
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
  }) async {
    final activeSpaceId = _activeSpaceId;
    if (activeSpaceId == null || activeSpaceId.isEmpty) {
      return Left(ServerFailure('No active space is attached to runtime.'));
    }

    final baselineFingerprint = _lastFingerprint;
    final result = await updateAudioState(
      UpdateAudioStateParams(
        spaceId: activeSpaceId,
        volumePercent: volumePercent,
        isMuted: isMuted,
        queueEndBehavior: queueEndBehavior,
        usePlaybackDeviceScope: _usePlaybackDeviceScope,
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
        'queueItemId=${event.currentQueueItemId ?? '-'} '
        'trackId=${event.trackId ?? '-'} '
        'trackName=${event.trackName ?? '-'} '
        'hls=${event.hlsUrl}',
      );
      unawaited(refreshState(silent: true));
    });

    _playbackCommandSub = storeHubService.onPlaybackCommand.listen((event) {
      if (!_isActiveSpace(event.spaceId)) return;
      _traceLog(
        'SIGNALR_PLAYBACK_COMMAND '
        'spaceId=${event.spaceId} '
        'command=${event.command.name} '
        'seek=${event.seekPositionSeconds?.toStringAsFixed(2) ?? '-'} '
        'targetTrackId=${event.targetTrackId ?? '-'}',
      );
      _debugLog(
        'hub PlaybackCommand spaceId=${event.spaceId} '
        'command=${event.command.name} '
        'seek=${event.seekPositionSeconds?.toStringAsFixed(2) ?? '-'} '
        'targetTrackId=${event.targetTrackId ?? '-'}',
      );

      if (_isLocallyPatchableCommand(event.command)) {
        final patchedState = _applyPlaybackCommandPatch(
          current: _currentState,
          command: event.command,
          seekPositionSeconds: event.seekPositionSeconds,
        );
        if (patchedState != null) {
          _emitState(patchedState);
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
    _maybeTraceStateSync(
      source: 'signalr-state-sync',
      playbackState: normalizedState,
    );
    _emitState(normalizedState);
  }

  Future<SpacePlaybackState> _normalizeIncomingState(
    SpacePlaybackState playbackState,
  ) async {
    var normalizedState = _normalizePlaybackStateForClientClock(
      incoming: playbackState,
      current: _currentState,
    );

    if (_shouldHydrateQueueSnapshot(normalizedState)) {
      final queueResult = await getSpaceQueue(
        QueueScopeParams(
          spaceId: normalizedState.spaceId,
          usePlaybackDeviceScope: _usePlaybackDeviceScope,
        ),
      );
      normalizedState = queueResult.fold(
        (_) => normalizedState,
        (queueItems) => queueItems.isEmpty
            ? normalizedState
            : _copyWithQueue(
                source: normalizedState,
                queueItems: _reindexQueueItems(queueItems),
              ),
      );
    }

    return normalizedState;
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
            ].join(':'))
        .join('|');

    return [
      playbackState.spaceId,
      playbackState.currentIdentityId ?? '',
      playbackState.pendingQueueItemId ?? '',
      playbackState.currentDisplayName ?? '',
      playbackState.currentPlaylistName ?? '',
      playbackState.effectiveHlsUrl ?? '',
      playbackState.isPaused ? '1' : '0',
      playbackState.startedAtUtc?.toUtc().toIso8601String() ?? '',
      playbackState.seekOffsetSeconds?.toStringAsFixed(3) ?? '',
      playbackState.pausePositionSeconds?.toString() ?? '',
      playbackState.volumePercent.toString(),
      playbackState.isMuted ? '1' : '0',
      playbackState.queueEndBehavior.toString(),
      queueFingerprint,
    ].join('||');
  }

  bool _shouldHydrateQueueSnapshot(SpacePlaybackState playbackState) {
    if (playbackState.spaceQueueItems.isNotEmpty) return false;

    final hasQueueIdentity =
        (playbackState.currentQueueItemId?.isNotEmpty ?? false) ||
            (playbackState.pendingQueueItemId?.isNotEmpty ?? false);
    if (hasQueueIdentity) return true;

    return playbackState.hasPlayableHls;
  }

  List<SpaceQueueStateItem> _reindexQueueItems(
    List<SpaceQueueStateItem> queueItems,
  ) {
    final sortedItems = [...queueItems]
      ..sort((a, b) => a.position.compareTo(b.position));

    return List<SpaceQueueStateItem>.generate(sortedItems.length, (index) {
      final item = sortedItems[index];
      return SpaceQueueStateItem(
        queueItemId: item.queueItemId,
        trackId: item.trackId,
        trackName: item.trackName,
        position: index + 1,
        queueStatus: item.queueStatus,
        source: item.source,
        hlsUrl: item.hlsUrl,
        isReadyToStream: item.isReadyToStream,
      );
    }, growable: false);
  }

  SpacePlaybackState _copyWithQueue({
    required SpacePlaybackState source,
    required List<SpaceQueueStateItem> queueItems,
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
      volumePercent: source.volumePercent,
      isMuted: source.isMuted,
      queueEndBehavior: source.queueEndBehavior,
      spaceQueueItems: queueItems,
    );
  }

  bool _isLocallyPatchableCommand(PlaybackCommandEnum command) {
    return command == PlaybackCommandEnum.pause ||
        command == PlaybackCommandEnum.resume ||
        command == PlaybackCommandEnum.seek ||
        command == PlaybackCommandEnum.seekForward ||
        command == PlaybackCommandEnum.seekBackward;
  }

  SpacePlaybackState? _applyPlaybackCommandPatch({
    required SpacePlaybackState? current,
    required PlaybackCommandEnum command,
    required double? seekPositionSeconds,
  }) {
    if (current == null) return null;

    final nowUtc = DateTime.now().toUtc();
    final safeSeek = seekPositionSeconds == null || seekPositionSeconds < 0
        ? 0.0
        : seekPositionSeconds;
    final effectiveOffset = seekPositionSeconds ?? current.effectiveSeekOffset;

    switch (command) {
      case PlaybackCommandEnum.pause:
        return SpacePlaybackState(
          spaceId: current.spaceId,
          storeId: current.storeId,
          brandId: current.brandId,
          currentQueueItemId: current.currentQueueItemId,
          currentTrackName: current.currentTrackName,
          currentPlaylistId: current.currentPlaylistId,
          currentPlaylistName: current.currentPlaylistName,
          hlsUrl: current.hlsUrl,
          moodName: current.moodName,
          isManualOverride: current.isManualOverride,
          overrideMode: current.overrideMode,
          startedAtUtc: current.startedAtUtc,
          expectedEndAtUtc: current.expectedEndAtUtc,
          isPaused: true,
          pausePositionSeconds: effectiveOffset.round(),
          seekOffsetSeconds: effectiveOffset,
          pendingQueueItemId: current.pendingQueueItemId,
          pendingPlaylistId: current.pendingPlaylistId,
          pendingOverrideReason: current.pendingOverrideReason,
          volumePercent: current.volumePercent,
          isMuted: current.isMuted,
          queueEndBehavior: current.queueEndBehavior,
          spaceQueueItems: current.spaceQueueItems,
        );
      case PlaybackCommandEnum.resume:
        return SpacePlaybackState(
          spaceId: current.spaceId,
          storeId: current.storeId,
          brandId: current.brandId,
          currentQueueItemId: current.currentQueueItemId,
          currentTrackName: current.currentTrackName,
          currentPlaylistId: current.currentPlaylistId,
          currentPlaylistName: current.currentPlaylistName,
          hlsUrl: current.hlsUrl,
          moodName: current.moodName,
          isManualOverride: current.isManualOverride,
          overrideMode: current.overrideMode,
          startedAtUtc: nowUtc.subtract(
            Duration(milliseconds: (effectiveOffset * 1000).round()),
          ),
          expectedEndAtUtc: current.expectedEndAtUtc,
          isPaused: false,
          pausePositionSeconds: null,
          seekOffsetSeconds: effectiveOffset,
          pendingQueueItemId: current.pendingQueueItemId,
          pendingPlaylistId: current.pendingPlaylistId,
          pendingOverrideReason: current.pendingOverrideReason,
          volumePercent: current.volumePercent,
          isMuted: current.isMuted,
          queueEndBehavior: current.queueEndBehavior,
          spaceQueueItems: current.spaceQueueItems,
        );
      case PlaybackCommandEnum.seek:
      case PlaybackCommandEnum.seekForward:
      case PlaybackCommandEnum.seekBackward:
        return SpacePlaybackState(
          spaceId: current.spaceId,
          storeId: current.storeId,
          brandId: current.brandId,
          currentQueueItemId: current.currentQueueItemId,
          currentTrackName: current.currentTrackName,
          currentPlaylistId: current.currentPlaylistId,
          currentPlaylistName: current.currentPlaylistName,
          hlsUrl: current.hlsUrl,
          moodName: current.moodName,
          isManualOverride: current.isManualOverride,
          overrideMode: current.overrideMode,
          startedAtUtc: current.isPaused
              ? current.startedAtUtc
              : nowUtc.subtract(
                  Duration(milliseconds: (safeSeek * 1000).round()),
                ),
          expectedEndAtUtc: current.expectedEndAtUtc,
          isPaused: current.isPaused,
          pausePositionSeconds: current.isPaused ? safeSeek.round() : null,
          seekOffsetSeconds: safeSeek,
          pendingQueueItemId: current.pendingQueueItemId,
          pendingPlaylistId: current.pendingPlaylistId,
          pendingOverrideReason: current.pendingOverrideReason,
          volumePercent: current.volumePercent,
          isMuted: current.isMuted,
          queueEndBehavior: current.queueEndBehavior,
          spaceQueueItems: current.spaceQueueItems,
        );
      case PlaybackCommandEnum.skipNext:
      case PlaybackCommandEnum.skipPrevious:
      case PlaybackCommandEnum.skipToTrack:
      case PlaybackCommandEnum.trackEnded:
        return current;
    }
  }

  SpacePlaybackState? _applyAudioStatePatch({
    required SpacePlaybackState? current,
    required int? volumePercent,
    required bool? isMuted,
    required int? queueEndBehavior,
  }) {
    if (current == null) return null;

    return SpacePlaybackState(
      spaceId: current.spaceId,
      storeId: current.storeId,
      brandId: current.brandId,
      currentQueueItemId: current.currentQueueItemId,
      currentTrackName: current.currentTrackName,
      currentPlaylistId: current.currentPlaylistId,
      currentPlaylistName: current.currentPlaylistName,
      hlsUrl: current.hlsUrl,
      moodName: current.moodName,
      isManualOverride: current.isManualOverride,
      overrideMode: current.overrideMode,
      startedAtUtc: current.startedAtUtc,
      expectedEndAtUtc: current.expectedEndAtUtc,
      isPaused: current.isPaused,
      pausePositionSeconds: current.pausePositionSeconds,
      seekOffsetSeconds: current.seekOffsetSeconds,
      pendingQueueItemId: current.pendingQueueItemId,
      pendingPlaylistId: current.pendingPlaylistId,
      pendingOverrideReason: current.pendingOverrideReason,
      volumePercent: volumePercent ?? current.volumePercent,
      isMuted: isMuted ?? current.isMuted,
      queueEndBehavior: queueEndBehavior ?? current.queueEndBehavior,
      spaceQueueItems: current.spaceQueueItems,
    );
  }

  SpacePlaybackState _buildClearedQueueState(String spaceId) {
    final current = _currentState;
    if (current == null) {
      return SpacePlaybackState(spaceId: spaceId);
    }

    return SpacePlaybackState(
      spaceId: spaceId,
      storeId: current.storeId,
      brandId: current.brandId,
      currentQueueItemId: null,
      currentTrackName: null,
      currentPlaylistId: null,
      currentPlaylistName: null,
      hlsUrl: null,
      moodName: current.moodName,
      isManualOverride: current.isManualOverride,
      overrideMode: current.overrideMode,
      startedAtUtc: null,
      expectedEndAtUtc: null,
      isPaused: false,
      pausePositionSeconds: null,
      seekOffsetSeconds: null,
      pendingQueueItemId: null,
      pendingPlaylistId: null,
      pendingOverrideReason: null,
      volumePercent: current.volumePercent,
      isMuted: current.isMuted,
      queueEndBehavior: current.queueEndBehavior,
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
      return SpacePlaybackState(
        spaceId: incoming.spaceId,
        storeId: incoming.storeId,
        brandId: incoming.brandId,
        currentQueueItemId: incoming.currentQueueItemId,
        currentTrackName: incoming.currentTrackName,
        currentPlaylistId: incoming.currentPlaylistId,
        currentPlaylistName: incoming.currentPlaylistName,
        hlsUrl: incoming.hlsUrl,
        moodName: incoming.moodName,
        isManualOverride: incoming.isManualOverride,
        overrideMode: incoming.overrideMode,
        startedAtUtc: startedAtUtc,
        expectedEndAtUtc: incoming.expectedEndAtUtc,
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
    }

    if (current != null &&
        current.currentQueueItemId == incoming.currentQueueItemId &&
        current.hlsUrl == incoming.hlsUrl &&
        current.startedAtUtc != null &&
        incoming.startedAtUtc == null) {
      return SpacePlaybackState(
        spaceId: incoming.spaceId,
        storeId: incoming.storeId,
        brandId: incoming.brandId,
        currentQueueItemId: incoming.currentQueueItemId,
        currentTrackName: incoming.currentTrackName,
        currentPlaylistId: incoming.currentPlaylistId,
        currentPlaylistName: incoming.currentPlaylistName,
        hlsUrl: incoming.hlsUrl,
        moodName: incoming.moodName,
        isManualOverride: incoming.isManualOverride,
        overrideMode: incoming.overrideMode,
        startedAtUtc: current.startedAtUtc,
        expectedEndAtUtc: incoming.expectedEndAtUtc,
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
    }

    return incoming;
  }

  void _debugLog(String message) {
    debugPrint('[QueueFirstV2] $message');
  }

  void _traceLog(String message) {
    debugPrint('[PlaybackTrace] $message');
  }

  void _rememberPendingTraceCommand({
    required PlaybackCommandEnum command,
    double? seekPositionSeconds,
    String? targetTrackId,
  }) {
    if (!_shouldTraceStateSync(command)) {
      return;
    }
    _pendingTraceCommand = command;
    _pendingTraceSeekPositionSeconds = seekPositionSeconds;
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
      'targetTrackId=${_pendingTraceTargetTrackId ?? '-'} '
      '${_describePlaybackState(playbackState)}',
    );
    _clearPendingTraceCommand();
  }

  void _clearPendingTraceCommand() {
    _pendingTraceCommand = null;
    _pendingTraceSeekPositionSeconds = null;
    _pendingTraceTargetTrackId = null;
    _pendingTraceIssuedAtUtc = null;
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
        'paused=${playbackState.isPaused} '
        'queueCount=${playbackState.spaceQueueItems.length} '
        'queue=[$queuePreview]';
  }
}
