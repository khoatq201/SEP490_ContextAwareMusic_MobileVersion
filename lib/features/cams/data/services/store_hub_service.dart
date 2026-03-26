import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/enums/playback_command_enum.dart';
import '../../../../core/enums/transition_type_enum.dart';
import '../../../suno/domain/entities/suno_generation_status.dart';
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
  String? _currentManagerBrandId;

  /// Offset in milliseconds: (deviceTimeUtc - serverTimeUtc).
  /// Positive = device clock is ahead of server.
  /// Used to compensate seek calculations derived from `startedAtUtc`.
  int _serverClockOffsetMs = 0;

  /// Public getter for the calculated server clock offset.
  int get serverClockOffsetMs => _serverClockOffsetMs;

  StoreHubService({required String Function() accessTokenFactory})
      : _accessTokenFactory = accessTokenFactory;

  // ─── Stream controllers for broadcasting events ─────────────────────────

  final _playStreamController = StreamController<PlayStreamEvent>.broadcast();
  final _playbackCommandController =
      StreamController<PlaybackCommandEvent>.broadcast();
  final _statesSyncController =
      StreamController<SpacePlaybackStateModel>.broadcast();
  final _stopPlaybackController = StreamController<void>.broadcast();
  final _sunoGenerationStatusController =
      StreamController<SunoGenerationStatusChangedEvent>.broadcast();
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

  /// Stream of Suno async generation status changes.
  Stream<SunoGenerationStatusChangedEvent> get onSunoGenerationStatusChanged =>
      _sunoGenerationStatusController.stream;

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
    if (_currentManagerBrandId != null) {
      await leaveBrandManagerRoom(_currentManagerBrandId!);
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

  Future<void> joinBrandManagerRoom(String brandId) async {
    _currentManagerBrandId = brandId;
    await _connection?.invoke('JoinBrandManagerRoomAsync', args: [brandId]);
  }

  Future<void> leaveBrandManagerRoom(String brandId) async {
    try {
      await _connection?.invoke('LeaveBrandManagerRoomAsync', args: [brandId]);
    } catch (_) {
      // Some environments may not expose LeaveBrandManagerRoomAsync yet.
    }
    if (_currentManagerBrandId == brandId) {
      _currentManagerBrandId = null;
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
        debugPrint(
          '[StoreHub] Connected to group: ${_readString(data, 'spaceId') ?? _readString(data, 'storeId')}',
        );
        // Compute clock drift from server timestamp.
        final serverTimeUtc = _parseDateTime(_readValue(data, 'serverTimeUtc'));
        if (serverTimeUtc != null) {
          _serverClockOffsetMs =
              DateTime.now().toUtc().difference(serverTimeUtc.toUtc()).inMilliseconds;
          debugPrint(
            '[StoreHub] Clock offset: ${_serverClockOffsetMs}ms '
            '(positive = device ahead)',
          );
        }
      }
    });

    // Playlist changed (AI or override)
    conn.on('PlayStream', (args) {
      final payload = _asMap(args?[0]);
      if (payload == null) return;

      final transitionType =
          TransitionTypeEnum.fromJson(_readValue(payload, 'transitionType')) ??
              TransitionTypeEnum.immediate;
      final hlsUrl = _readString(payload, 'hlsUrl') ?? '';

      // Pending means stream is not ready yet.
      if (transitionType == TransitionTypeEnum.pending && hlsUrl.isEmpty) {
        return;
      }

      _playStreamController.add(PlayStreamEvent(
        spaceId: _readString(payload, 'spaceId') ?? '',
        hlsUrl: hlsUrl,
        playlistId: _readString(payload, 'playlistId'),
        currentQueueItemId: _readString(payload, 'currentQueueItemId'),
        trackId: _readString(payload, 'trackId'),
        trackName: _readString(payload, 'trackName'),
        transitionType: transitionType,
        isManualOverride: _readBool(payload, 'isManualOverride') ?? false,
        startedAtUtc: _parseDateTime(_readValue(payload, 'startedAtUtc')),
      ));
    });

    // Playback command from manager
    conn.on('PlaybackStateChanged', (args) {
      final payload = _asMap(args?[0]);
      if (payload == null) return;

      _playbackCommandController.add(PlaybackCommandEvent(
        spaceId: _readString(payload, 'spaceId') ?? '',
        command: PlaybackCommandEnum.fromValue(
          _readNum(payload, 'command')?.toInt() ?? 1,
        ),
        seekPositionSeconds:
            _readNum(payload, 'seekPositionSeconds')?.toDouble(),
        targetTrackId: _readString(payload, 'targetTrackId'),
      ));
    });

    // Full state sync (after cancel override)
    conn.on('SpaceStateSync', (args) {
      final payload = _asMap(args?[0]);
      if (payload != null) {
        _statesSyncController.add(
          SpacePlaybackStateModel.fromSignalR(_normalizeKeyCasing(payload)),
        );
      }
    });

    // Stop playback
    conn.on('StopPlayback', (_) {
      _stopPlaybackController.add(null);
    });

    conn.on('SunoGenerationStatusChanged', (args) {
      final payload = _asMap(args?[0]);
      if (payload == null) return;

      _sunoGenerationStatusController.add(
        SunoGenerationStatusChangedEvent(
          id: _readString(payload, 'id') ?? '',
          brandId: _readString(payload, 'brandId') ?? '',
          generationStatus:
              SunoGenerationStatus.fromJson(
                _readValue(payload, 'generationStatus'),
              ),
          progressPercent: _readNum(payload, 'progressPercent')?.toInt(),
          errorMessage: _readString(payload, 'errorMessage'),
          generatedTrackId: _readString(payload, 'generatedTrackId'),
        ),
      );
    });

    // Error from hub
    conn.on('Error', (args) {
      final message = args?[0] as String?;
      debugPrint('[StoreHub] Server error: $message');
    });

    // Reconnect lifecycle
    conn.onreconnecting(({error}) {
      debugPrint('[StoreHub] Reconnecting... $error');
      _connectionController.add(ConnectionStatus.reconnecting);
    });

    conn.onreconnected(({connectionId}) {
      debugPrint('[StoreHub] Reconnected: $connectionId');
      _connectionController.add(ConnectionStatus.connected);
      // Re-join Space after reconnect
      if (_currentSpaceId != null) {
        unawaited(joinSpace(_currentSpaceId!));
      }
      if (_currentManagerStoreId != null) {
        unawaited(joinManagerRoom(_currentManagerStoreId!));
      }
      if (_currentManagerBrandId != null) {
        unawaited(joinBrandManagerRoom(_currentManagerBrandId!));
      }
    });

    conn.onclose(({error}) {
      debugPrint('[StoreHub] Connection closed: $error');
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
    _sunoGenerationStatusController.close();
    _connectionController.close();
  }

  Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Map<String, dynamic> _normalizeKeyCasing(Map<String, dynamic> payload) {
    final normalized = <String, dynamic>{};
    payload.forEach((key, value) {
      normalized[key] = value;
      if (key.isEmpty) return;
      final camelCaseKey = '${key[0].toLowerCase()}${key.substring(1)}';
      normalized.putIfAbsent(camelCaseKey, () => value);
    });
    return normalized;
  }

  dynamic _readValue(Map<String, dynamic> payload, String key) {
    if (payload.containsKey(key)) return payload[key];
    if (key.isEmpty) return null;
    final pascalCaseKey = '${key[0].toUpperCase()}${key.substring(1)}';
    if (payload.containsKey(pascalCaseKey)) return payload[pascalCaseKey];
    return null;
  }

  String? _readString(Map<String, dynamic> payload, String key) {
    final value = _readValue(payload, key);
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  num? _readNum(Map<String, dynamic> payload, String key) {
    final value = _readValue(payload, key);
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  bool? _readBool(Map<String, dynamic> payload, String key) {
    final value = _readValue(payload, key);
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return null;
  }

  DateTime? _parseDateTime(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}

// ─── Event DTOs ───────────────────────────────────────────────────────────────

/// Payload for PlayStream event.
class PlayStreamEvent {
  final String spaceId;
  final String hlsUrl;
  final String? playlistId;
  final String? currentQueueItemId;
  final String? trackId;
  final String? trackName;
  final TransitionTypeEnum transitionType;
  final bool isManualOverride;
  final DateTime? startedAtUtc;

  const PlayStreamEvent({
    required this.spaceId,
    required this.hlsUrl,
    this.playlistId,
    this.currentQueueItemId,
    this.trackId,
    this.trackName,
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

class SunoGenerationStatusChangedEvent {
  final String id;
  final String brandId;
  final SunoGenerationStatus generationStatus;
  final int? progressPercent;
  final String? errorMessage;
  final String? generatedTrackId;

  const SunoGenerationStatusChangedEvent({
    required this.id,
    required this.brandId,
    required this.generationStatus,
    this.progressPercent,
    this.errorMessage,
    this.generatedTrackId,
  });
}

/// Connection status enum for UI.
enum ConnectionStatus {
  connected,
  disconnected,
  reconnecting,
}
