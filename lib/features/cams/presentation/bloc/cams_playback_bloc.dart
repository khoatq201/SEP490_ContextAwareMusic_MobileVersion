import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  }) : super(const CamsPlaybackState()) {
    on<CamsInitPlayback>(_onInit);
    on<CamsDisposePlayback>(_onDispose);
    on<CamsOverrideMood>(_onOverrideMood);
    on<CamsOverridePlaylist>(_onOverridePlaylist);
    on<CamsCancelOverride>(_onCancelOverride);
    on<CamsSendCommand>(_onSendCommand);
    on<CamsPlayStreamReceived>(_onPlayStream);
    on<CamsPlaybackCommandReceived>(_onPlaybackCommand);
    on<CamsStateSyncReceived>(_onStateSync);
    on<CamsStopPlaybackReceived>(_onStopPlayback);
    on<CamsRefreshState>(_onRefreshState);
  }

  Future<void> _onInit(
    CamsInitPlayback event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    emit(state.copyWith(
      status: CamsStatus.loading,
      spaceId: event.spaceId,
      clearError: true,
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
    final stateResult = await getSpaceState(event.spaceId);
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
          status: pbState.isStreaming ? CamsStatus.active : CamsStatus.idle,
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
        hlsUrl: event.hlsUrl,
        playlistId: event.playlistId,
        isManualOverride: event.isManualOverride,
        startedAtUtc: event.startedAtUtc,
      ));
    });

    _playbackCommandSub = storeHubService.onPlaybackCommand.listen((event) {
      add(CamsPlaybackCommandReceived(
        command: event.command,
        seekPositionSeconds: event.seekPositionSeconds,
        targetTrackId: event.targetTrackId,
      ));
    });

    _stateSyncSub = storeHubService.onSpaceStateSync.listen((model) {
      add(CamsStateSyncReceived(
        spaceId: model.spaceId,
        hlsUrl: model.hlsUrl,
        playlistId: model.currentPlaylistId,
        playlistName: model.currentPlaylistName,
        moodName: model.moodName,
        isManualOverride: model.isManualOverride,
        seekOffsetSeconds: model.seekOffsetSeconds,
      ));
    });

    _stopPlaybackSub = storeHubService.onStopPlayback.listen((_) {
      add(const CamsStopPlaybackReceived());
    });

    _connectionSub = storeHubService.onConnectionStatus.listen((status) {
      // Re-join space on reconnect handled by StoreHubService internally
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
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isOverriding: false,
        errorMessage: 'Override failed: ${failure.message}',
      )),
      (response) {
        // Update playback state from override response
        final newPlaybackState = SpacePlaybackState(
          spaceId: spaceId,
          currentPlaylistId: response.playlistId,
          currentPlaylistName: response.playlistName,
          hlsUrl: response.hlsUrl,
          moodName: response.moodName,
          isManualOverride: response.isManualOverride,
          overrideMode: response.overrideMode,
          startedAtUtc: response.startedAtUtc,
          expectedEndAtUtc: response.expectedEndAtUtc,
        );

        emit(state.copyWith(
          isOverriding: false,
          lastOverrideResponse: response,
          playbackState: newPlaybackState,
          status: response.isStreamReady ? CamsStatus.active : CamsStatus.idle,
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
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isOverriding: false,
        errorMessage: 'Override failed: ${failure.message}',
      )),
      (response) {
        final newPlaybackState = SpacePlaybackState(
          spaceId: spaceId,
          currentPlaylistId: response.playlistId,
          currentPlaylistName: response.playlistName,
          hlsUrl: response.hlsUrl,
          moodName: response.moodName,
          isManualOverride: response.isManualOverride,
          overrideMode: response.overrideMode,
          startedAtUtc: response.startedAtUtc,
          expectedEndAtUtc: response.expectedEndAtUtc,
        );

        emit(state.copyWith(
          isOverriding: false,
          lastOverrideResponse: response,
          playbackState: newPlaybackState,
          status: response.isStreamReady ? CamsStatus.active : CamsStatus.idle,
        ));
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

    final result = await cancelOverride(spaceId);

    result.fold(
      (failure) => emit(state.copyWith(
        isOverriding: false,
        errorMessage: 'Cancel override failed: ${failure.message}',
      )),
      (_) => emit(state.copyWith(
        isOverriding: false,
        clearOverrideResponse: true,
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
    final spaceId = state.spaceId ?? '';
    final current = state.playbackState;

    emit(state.copyWith(
      status: CamsStatus.active,
      playbackState: SpacePlaybackState(
        spaceId: spaceId,
        currentPlaylistId: event.playlistId,
        currentPlaylistName: current?.currentPlaylistName,
        hlsUrl: event.hlsUrl,
        moodName: current?.moodName,
        isManualOverride: event.isManualOverride,
        overrideMode: current?.overrideMode,
        startedAtUtc: event.startedAtUtc,
        expectedEndAtUtc: current?.expectedEndAtUtc,
        seekOffsetSeconds: 0,
      ),
    ));
  }

  void _onPlaybackCommand(
    CamsPlaybackCommandReceived event,
    Emitter<CamsPlaybackState> emit,
  ) {
    // Playback commands are forwarded to PlayerBloc via the UI layer.
    // We update local state for pause/resume tracking.
    // The UI listens to this event and delegates to PlayerBloc.
  }

  void _onStateSync(
    CamsStateSyncReceived event,
    Emitter<CamsPlaybackState> emit,
  ) {
    final newState = SpacePlaybackState(
      spaceId: event.spaceId,
      currentPlaylistId: event.playlistId,
      currentPlaylistName: event.playlistName,
      hlsUrl: event.hlsUrl,
      moodName: event.moodName,
      isManualOverride: event.isManualOverride,
      seekOffsetSeconds: event.seekOffsetSeconds,
    );

    emit(state.copyWith(
      status: newState.isStreaming ? CamsStatus.active : CamsStatus.idle,
      playbackState: newState,
      clearOverrideResponse: true,
    ));
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
    ));
  }

  Future<void> _onRefreshState(
    CamsRefreshState event,
    Emitter<CamsPlaybackState> emit,
  ) async {
    final spaceId = state.spaceId;
    if (spaceId == null) return;

    final result = await getSpaceState(spaceId);
    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: failure.message,
      )),
      (playbackState) => emit(state.copyWith(
        status: playbackState.isStreaming ? CamsStatus.active : CamsStatus.idle,
        playbackState: playbackState,
      )),
    );
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
