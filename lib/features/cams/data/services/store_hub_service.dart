import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/enums/playback_command_enum.dart';
import '../../../../core/enums/transition_type_enum.dart';
import '../models/space_playback_state_model.dart';

/// Service for real-time communication with CAMS StoreHub via SignalR.
///
/// Events received (Server → Client):
/// - `PlayStream`           — AI/override changed the playlist
/// - `PlaybackStateChanged` — Playback command relay (Pause/Resume/Seek/Skip)
/// - `SpaceStateSync`       — Full state re-sync after cancel override
/// - `StopPlayback`         — Stop all playback
/// - `ConnectionConfirmed`  — Acknowledgement after joining a Space/ManagerRoom
///
/// Methods sent (Client → Server):
/// - `JoinSpaceAsync`       — Tablet joins Space group
/// - `LeaveSpaceAsync`      — Tablet leaves Space group
/// - `ReportPlaybackStateAsync` — Health/analytics reporting
class StoreHubService {
  final String Function() _accessTokenFactory;
  HubConnection? _connection;
  String? _currentSpaceId;
  String? _currentManagerStoreId;

  StoreHubService({required String Function() accessTokenFactory})
      : _accessTokenFactory = accessTokenFactory;

  // ─── Stream controllers for broadcasting events ─────────────────────────

  final _playStreamController = StreamController<PlayStreamEvent>.broadcast();
  final _playbackCommandController =
      StreamController<PlaybackCommandEvent>.broadcast();
  final _statesSyncController =
      StreamController<SpacePlaybackStateModel>.broadcast();
  final _stopPlaybackController = StreamController<void>.broadcast();
  final _connectionController = StreamController<ConnectionStatus>.broadcast();

  /// Stream of PlayStream events (playlist changes).
  Stream<PlayStreamEvent> get onPlayStream => _playStreamController.stream;

  /// Stream of playback commands from manager.
  Stream<PlaybackCommandEvent> get onPlaybackCommand =>
      _playbackCommandController.stream;

  /// Stream of full state syncs (after cancel override).
  Stream<SpacePlaybackStateModel> get onSpaceStateSync =>
      _statesSyncController.stream;

  /// Stream of stop playback events.
  Stream<void> get onStopPlayback => _stopPlaybackController.stream;

  /// Stream of connection status changes.
  Stream<ConnectionStatus> get onConnectionStatus =>
      _connectionController.stream;

  /// Current connection state.
  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  /// Connect to the StoreHub.
  Future<void> connect() async {
    if (_connection != null &&
        _connection!.state == HubConnectionState.Connected) {
      return; // Already connected
    }

    _connection = HubConnectionBuilder()
        .withUrl(
      ApiConstants.storeHubUrl,
      options: HttpConnectionOptions(
        accessTokenFactory: () async => _accessTokenFactory(),
        transport: HttpTransportType.WebSockets,
        skipNegotiation: true,
      ),
    )
        .withAutomaticReconnect(
      retryDelays: [0, 2000, 5000, 10000, 30000],
    ).build();

    _registerListeners();
    await _connection!.start();

    _connectionController.add(ConnectionStatus.connected);
  }

  /// Disconnect from the StoreHub.
  Future<void> disconnect() async {
    if (_currentSpaceId != null) {
      await leaveSpace(_currentSpaceId!);
    }
    if (_currentManagerStoreId != null) {
      await leaveManagerRoom(_currentManagerStoreId!);
    }
    await _connection?.stop();
    _connection = null;
    _connectionController.add(ConnectionStatus.disconnected);
  }

  // ─── Client → Server methods ─────────────────────────────────────────────

  /// Join a Space group to receive its events.
  Future<void> joinSpace(String spaceId) async {
    _currentSpaceId = spaceId;
    await _connection?.invoke('JoinSpaceAsync', args: [spaceId]);
  }

  /// Leave a Space group.
  Future<void> leaveSpace(String spaceId) async {
    await _connection?.invoke('LeaveSpaceAsync', args: [spaceId]);
    if (_currentSpaceId == spaceId) {
      _currentSpaceId = null;
    }
  }

  Future<void> joinManagerRoom(String storeId) async {
    _currentManagerStoreId = storeId;
    await _connection?.invoke('JoinManagerRoomAsync', args: [storeId]);
  }

  Future<void> leaveManagerRoom(String storeId) async {
    try {
      await _connection?.invoke('LeaveManagerRoomAsync', args: [storeId]);
    } catch (_) {
      // Some environments may not expose LeaveManagerRoomAsync yet.
    }
    if (_currentManagerStoreId == storeId) {
      _currentManagerStoreId = null;
    }
  }

  /// Report playback state for analytics/health monitoring.
  Future<void> reportPlaybackState({
    required String spaceId,
    required bool isPlaying,
    double? positionSeconds,
    String? currentHlsUrl,
  }) async {
    await _connection?.invoke('ReportPlaybackStateAsync', args: [
      {
        'spaceId': spaceId,
        'isPlaying': isPlaying,
        'positionSeconds': positionSeconds,
        'currentHlsUrl': currentHlsUrl,
      }
    ]);
  }

  // ─── Server → Client event listeners ──────────────────────────────────────

  void _registerListeners() {
    final conn = _connection;
    if (conn == null) return;

    // Connection confirmed after joining
    conn.on('ConnectionConfirmed', (args) {
      final data = _asMap(args?[0]);
      if (data != null) {
        print(
          '[StoreHub] Connected to group: ${data['spaceId'] ?? data['storeId']}',
        );
      }
    });

    // Playlist changed (AI or override)
    conn.on('PlayStream', (args) {
      final payload = _asMap(args?[0]);
      if (payload == null) return;

      final transitionType = payload['transitionType'] as int? ?? 1;

      // Skip Pending (3) — wait for the next event with ready HLS
      if (transitionType == TransitionTypeEnum.pending.value) return;

      _playStreamController.add(PlayStreamEvent(
        spaceId: payload['spaceId'] as String? ?? '',
        hlsUrl: payload['hlsUrl'] as String? ?? '',
        playlistId: payload['playlistId'] as String? ?? '',
        transitionType: TransitionTypeEnum.fromValue(transitionType),
        isManualOverride: payload['isManualOverride'] as bool? ?? false,
        startedAtUtc: payload['startedAtUtc'] != null
            ? DateTime.tryParse(payload['startedAtUtc'] as String)
            : null,
      ));
    });

    // Playback command from manager
    conn.on('PlaybackStateChanged', (args) {
      final payload = _asMap(args?[0]);
      if (payload == null) return;

      _playbackCommandController.add(PlaybackCommandEvent(
        spaceId: payload['spaceId'] as String? ?? '',
        command: PlaybackCommandEnum.fromValue(payload['command'] as int? ?? 1),
        seekPositionSeconds:
            (payload['seekPositionSeconds'] as num?)?.toDouble(),
        targetTrackId: payload['targetTrackId'] as String?,
      ));
    });

    // Full state sync (after cancel override)
    conn.on('SpaceStateSync', (args) {
      final payload = _asMap(args?[0]);
      if (payload != null) {
        _statesSyncController.add(
          SpacePlaybackStateModel.fromSignalR(payload),
        );
      }
    });

    // Stop playback
    conn.on('StopPlayback', (_) {
      _stopPlaybackController.add(null);
    });

    // Error from hub
    conn.on('Error', (args) {
      final message = args?[0] as String?;
      print('[StoreHub] Server error: $message');
    });

    // Reconnect lifecycle
    conn.onreconnecting(({error}) {
      print('[StoreHub] Reconnecting... $error');
      _connectionController.add(ConnectionStatus.reconnecting);
    });

    conn.onreconnected(({connectionId}) {
      print('[StoreHub] Reconnected: $connectionId');
      _connectionController.add(ConnectionStatus.connected);
      // Re-join Space after reconnect
      if (_currentSpaceId != null) {
        joinSpace(_currentSpaceId!);
      }
      if (_currentManagerStoreId != null) {
        joinManagerRoom(_currentManagerStoreId!);
      }
    });

    conn.onclose(({error}) {
      print('[StoreHub] Connection closed: $error');
      _connectionController.add(ConnectionStatus.disconnected);
    });
  }

  // ─── Cleanup ──────────────────────────────────────────────────────────────

  void dispose() {
    _connection?.stop();
    _playStreamController.close();
    _playbackCommandController.close();
    _statesSyncController.close();
    _stopPlaybackController.close();
    _connectionController.close();
  }

  Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }
}

// ─── Event DTOs ───────────────────────────────────────────────────────────────

/// Payload for PlayStream event.
class PlayStreamEvent {
  final String spaceId;
  final String hlsUrl;
  final String playlistId;
  final TransitionTypeEnum transitionType;
  final bool isManualOverride;
  final DateTime? startedAtUtc;

  const PlayStreamEvent({
    required this.spaceId,
    required this.hlsUrl,
    required this.playlistId,
    required this.transitionType,
    this.isManualOverride = false,
    this.startedAtUtc,
  });
}

/// Payload for PlaybackStateChanged event.
class PlaybackCommandEvent {
  final String spaceId;
  final PlaybackCommandEnum command;
  final double? seekPositionSeconds;
  final String? targetTrackId;

  const PlaybackCommandEvent({
    required this.spaceId,
    required this.command,
    this.seekPositionSeconds,
    this.targetTrackId,
  });
}

/// Connection status enum for UI.
enum ConnectionStatus {
  connected,
  disconnected,
  reconnecting,
}
