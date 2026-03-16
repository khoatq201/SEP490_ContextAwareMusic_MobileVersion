import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/playback_command_enum.dart';
import '../../../../core/session/session_cubit.dart';
import '../../domain/entities/space_playback_state.dart';
import '../../domain/usecases/get_space_state.dart';
import '../../domain/usecases/override_space.dart';
import '../../domain/usecases/cancel_override.dart';
import '../../domain/usecases/send_playback_command.dart';
import '../../data/services/store_hub_service.dart';
import '../../../moods/domain/usecases/get_moods.dart';
import 'cams_playback_event.dart';
import 'cams_playback_state.dart';

/// BLoC that manages CAMS playback state, SignalR integration,
/// and exposes mood/override controls for the NowPlaying UI.
class CamsPlaybackBloc extends Bloc<CamsPlaybackEvent, CamsPlaybackState> {
  final GetSpaceState getSpaceState;
  final OverrideSpace overrideSpace;
  final CancelOverride cancelOverride;
  final SendPlaybackCommand sendPlaybackCommand;
  final GetMoods getMoods;
  final StoreHubService storeHubService;
  final SessionCubit sessionCubit;

  StreamSubscription? _playStreamSub;
  StreamSubscription? _playbackCommandSub;
  StreamSubscription? _stateSyncSub;
  StreamSubscription? _stopPlaybackSub;
  StreamSubscription? _connectionSub;

  CamsPlaybackBloc({
    required this.getSpaceState,
    required this.overrideSpace,
    required this.cancelOverride,
    required this.sendPlaybackCommand,
    required this.getMoods,
    required this.storeHubService,
    required this.sessionCubit,
  }) : super(const CamsPlaybackState()) {
    on<CamsInitPlayback>(_onInit);
    on<CamsDisposePlayback>(_onDispose);
    on<CamsOverrideMood>(_onOverrideMood);
    on<CamsOverridePlaylist>(_onOverridePlaylist);
    on<CamsPlayPlaylistTrack>(_onPlayPlaylistTrack);
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
    ));

    // 1. Connect SignalR + join space
    try {
      await storeHubService.connect();
      await storeHubService.joinSpace(event.spaceId);
      emit(state.copyWith(isHubConnected: true));
    } catch (e) {
      // Non-fatal: continue without real-time updates
    }

    // 2. Subscribe to SignalR events
    _subscribeToHub();

    // 3. Fetch initial state + moods in parallel
    final stateResult = await getSpaceState(
      event.spaceId,
      usePlaybackDeviceScope: sessionCubit.state.isPlaybackDevice,
    );
    final moodsResult = await getMoods();

    // Process moods
    moodsResult.fold(
      (_) {}, // Non-fatal
      (moods) => emit(state.copyWith(moods: moods)),
    );

    // Process playback state
    stateResult.fold(
      (failure) => emit(state.copyWith(
        status: CamsStatus.error,
        errorMessage: failure.message,
      )),
      (pbState) {
        emit(state.copyWith(
          status: (pbState.isStreaming || pbState.hasPendingPlaylist)
              ? CamsStatus.active
              : CamsStatus.idle,
          playbackState: pbState,
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
        add(const CamsRefreshState());
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
        final isPending = !response.isStreamReady;
        // Update playback state from override response
        final newPlaybackState = SpacePlaybackState(
          spaceId: spaceId,
          currentPlaylistId: isPending ? null : response.playlistId,
          currentPlaylistName: isPending ? null : response.playlistName,
          hlsUrl: response.hlsUrl,
          moodName: response.moodName,
          isManualOverride: response.isManualOverride,
          overrideMode: response.overrideMode,
          startedAtUtc: response.startedAtUtc,
          expectedEndAtUtc: response.expectedEndAtUtc,
          seekOffsetSeconds: null,
          pendingPlaylistId: isPending ? response.playlistId : null,
          pendingOverrideReason:
              isPending ? (event.reason ?? 'Preparing stream') : null,
        );

        emit(state.copyWith(
          isOverriding: false,
          lastOverrideResponse: response,
          playbackState: newPlaybackState,
          status: (newPlaybackState.isStreaming || newPlaybackState.hasPendingPlaylist)
              ? CamsStatus.active
              : CamsStatus.idle,
          clearPendingTrackJump: true,
        ));
      },
    );
  }

  Future<void> _onOverridePlaylist(
    CamsOverridePlaylist event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    final spaceId = state.spaceId;
    if (spaceId == null) return;

    emit(state.copyWith(isOverriding: true, clearError: true));

    final result = await overrideSpace(
      spaceId: spaceId,
      playlistId: event.playlistId,
      reason: event.reason,
      usePlaybackDeviceScope: sessionCubit.state.isPlaybackDevice,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isOverriding: false,
        errorMessage: 'Override failed: ${failure.message}',
        clearPendingTrackJump: true,
      )),
      (response) {
        final isPending = !response.isStreamReady;
        final current = state.playbackState;
        final newPlaybackState = SpacePlaybackState(
          spaceId: spaceId,
          currentPlaylistId: isPending ? null : response.playlistId,
          currentPlaylistName: isPending ? null : response.playlistName,
          hlsUrl: response.hlsUrl,
          moodName: response.moodName,
          isManualOverride: response.isManualOverride,
          overrideMode: response.overrideMode,
          startedAtUtc: response.startedAtUtc,
          expectedEndAtUtc: response.expectedEndAtUtc,
          seekOffsetSeconds: null,
          storeId: current?.storeId,
          brandId: current?.brandId,
          pendingPlaylistId: isPending ? response.playlistId : null,
          pendingOverrideReason:
              isPending ? (event.reason ?? 'Preparing stream') : null,
        );

        emit(state.copyWith(
          isOverriding: false,
          lastOverrideResponse: response,
          playbackState: newPlaybackState,
          status: (newPlaybackState.isStreaming || newPlaybackState.hasPendingPlaylist)
              ? CamsStatus.active
              : CamsStatus.idle,
          clearPendingTrackJump: true,
        ));
      },
    );
  }

  Future<void> _onPlayPlaylistTrack(
    CamsPlayPlaylistTrack event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    final spaceId = state.spaceId;
    if (spaceId == null) return;

    final current = state.playbackState;
    final isCurrentPlaylist = current?.currentPlaylistId == event.playlistId;
    final isPendingCurrentPlaylist = current?.pendingPlaylistId == event.playlistId;

    if (isCurrentPlaylist && (current?.isStreaming ?? false)) {
      emit(state.copyWith(
        pendingTrackPlaylistId: event.playlistId,
        pendingTrackId: event.targetTrackId,
        clearError: true,
      ));
      _dispatchDeferredTrackJump(
        playbackState: current!,
        emit: emit,
      );
      return;
    }

    if (isPendingCurrentPlaylist) {
      emit(state.copyWith(
        pendingTrackPlaylistId: event.playlistId,
        pendingTrackId: event.targetTrackId,
        clearError: true,
      ));
      return;
    }

    emit(state.copyWith(
      isOverriding: true,
      clearError: true,
      pendingTrackPlaylistId: event.playlistId,
      pendingTrackId: event.targetTrackId,
    ));

    final result = await overrideSpace(
      spaceId: spaceId,
      playlistId: event.playlistId,
      reason: event.reason ?? 'Play selected track',
      usePlaybackDeviceScope: sessionCubit.state.isPlaybackDevice,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isOverriding: false,
        errorMessage: 'Play track failed: ${failure.message}',
        clearPendingTrackJump: true,
      )),
      (response) {
        final isPending = !response.isStreamReady;
        final updatedState = SpacePlaybackState(
          spaceId: spaceId,
          storeId: current?.storeId,
          brandId: current?.brandId,
          currentPlaylistId: isPending ? null : response.playlistId,
          currentPlaylistName: isPending ? null : response.playlistName,
          hlsUrl: response.hlsUrl,
          moodName: response.moodName,
          isManualOverride: response.isManualOverride,
          overrideMode: response.overrideMode,
          startedAtUtc: response.startedAtUtc,
          expectedEndAtUtc: response.expectedEndAtUtc,
          isPaused: false,
          pausePositionSeconds: null,
          seekOffsetSeconds: null,
          pendingPlaylistId: isPending ? response.playlistId : null,
          pendingOverrideReason: isPending
              ? (event.reason ?? 'Play selected track')
              : null,
        );

        emit(state.copyWith(
          isOverriding: false,
          lastOverrideResponse: response,
          playbackState: updatedState,
          status: (updatedState.isStreaming || updatedState.hasPendingPlaylist)
              ? CamsStatus.active
              : CamsStatus.idle,
        ));

        if (!isPending) {
          _dispatchDeferredTrackJump(
            playbackState: updatedState,
            emit: emit,
          );
        }
      },
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
        clearPendingTrackJump: true,
      )),
      (_) => emit(state.copyWith(
        isOverriding: false,
        clearOverrideResponse: true,
        clearPendingTrackJump: true,
      )),
    );
    // State will be updated via SpaceStateSync SignalR event
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
        // Commands are relayed via SignalR — no local state update needed
      },
    );
  }

  void _onPlayStream(
    CamsPlayStreamReceived event,
    Emitter<CamsPlaybackState> emit,
  ) {
    if (event.spaceId != state.spaceId) return;
    final spaceId = state.spaceId ?? '';
    final current = state.playbackState;
    final nextPlaybackState = SpacePlaybackState(
      spaceId: spaceId,
      currentPlaylistId: event.playlistId,
      currentPlaylistName: current?.currentPlaylistName,
      hlsUrl: event.hlsUrl,
      moodName: current?.moodName,
      isManualOverride: event.isManualOverride,
      overrideMode: current?.overrideMode,
      startedAtUtc: event.startedAtUtc,
      expectedEndAtUtc: current?.expectedEndAtUtc,
      isPaused: false,
      pausePositionSeconds: null,
      seekOffsetSeconds: null,
      storeId: current?.storeId,
      brandId: current?.brandId,
      pendingPlaylistId: null,
      pendingOverrideReason: null,
    );

    emit(state.copyWith(
      status: CamsStatus.active,
      playbackState: nextPlaybackState,
    ));

    _dispatchDeferredTrackJump(playbackState: nextPlaybackState, emit: emit);
  }

  void _onPlaybackCommand(
    CamsPlaybackCommandReceived event,
    Emitter<CamsPlaybackState> emit,
  ) {
    if (event.spaceId != state.spaceId) return;
    emit(state.copyWith(
      lastPlaybackCommand: event.command,
      lastSeekPositionSeconds: event.seekPositionSeconds,
      lastTargetTrackId: event.targetTrackId,
      commandSequence: state.commandSequence + 1,
    ));
  }

  void _onStateSync(
    CamsStateSyncReceived event,
    Emitter<CamsPlaybackState> emit,
  ) {
    final newState = event.playbackState;
    if (newState.spaceId != state.spaceId) return;

    emit(state.copyWith(
      status: (newState.isStreaming || newState.hasPendingPlaylist)
          ? CamsStatus.active
          : CamsStatus.idle,
      playbackState: newState,
      clearOverrideResponse: true,
    ));

    _dispatchDeferredTrackJump(playbackState: newState, emit: emit);
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
    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: failure.message,
      )),
      (playbackState) {
        emit(state.copyWith(
          status: (playbackState.isStreaming || playbackState.hasPendingPlaylist)
              ? CamsStatus.active
              : CamsStatus.idle,
          playbackState: playbackState,
        ));
        _dispatchDeferredTrackJump(playbackState: playbackState, emit: emit);
      },
    );
  }

  void _dispatchDeferredTrackJump({
    required SpacePlaybackState playbackState,
    required Emitter<CamsPlaybackState> emit,
  }) {
    final pendingTrackId = state.pendingTrackId;
    final pendingTrackPlaylistId = state.pendingTrackPlaylistId;
    if (pendingTrackId == null ||
        pendingTrackPlaylistId == null ||
        !playbackState.isStreaming ||
        playbackState.currentPlaylistId != pendingTrackPlaylistId) {
      return;
    }

    emit(state.copyWith(clearPendingTrackJump: true));
    add(CamsSendCommand(
      command: PlaybackCommandEnum.skipToTrack,
      targetTrackId: pendingTrackId,
    ));
  }

  Future<void> _onReportPlaybackState(
    CamsReportPlaybackState event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    if (!state.isHubConnected) return;
    final activeSpaceId = state.spaceId;
    if (activeSpaceId == null || activeSpaceId != event.spaceId) return;

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

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}
