import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../audio/playback_notification_service.dart';
import '../enums/playback_command_enum.dart';
import '../network/dio_client.dart';
import '../player/playlist_queue_builder.dart';
import '../../features/cams/presentation/bloc/cams_playback_bloc.dart';
import '../../features/cams/presentation/bloc/cams_playback_event.dart';
import '../../features/cams/presentation/bloc/cams_playback_state.dart';
import '../../features/cams/domain/entities/space_playback_state.dart';
import '../../features/cams/domain/entities/space_queue_state_item.dart';
import '../../features/space_control/domain/entities/track.dart';
import '../../features/tracks/domain/entities/api_track.dart';
import '../../features/tracks/domain/usecases/track_usecases.dart';
import '../player/player_bloc.dart';
import '../player/player_event.dart';
import '../player/player_state.dart';
import '../services/local_storage_service.dart';
import '../session/session_cubit.dart';
import '../session/session_state.dart';
import '../../injection_container.dart';
import '../../router.dart';

/// Keeps Session, CAMS and the global PlayerBloc synchronized app-wide.
class AppPlaybackCoordinator extends StatefulWidget {
  const AppPlaybackCoordinator({super.key, required this.child});

  final Widget child;

  @override
  State<AppPlaybackCoordinator> createState() => _AppPlaybackCoordinatorState();
}

class _AppPlaybackCoordinatorState extends State<AppPlaybackCoordinator>
    with WidgetsBindingObserver {
  StreamSubscription<PlaybackNotificationCommand>? _notificationCommandSub;
  StreamSubscription<void>? _sessionInvalidatedSub;
  String? _hydratedPlaylistId;
  final Map<String, Track> _trackMetadataCache = <String, Track>{};
  final Set<String> _trackMetadataInFlight = <String>{};
  Timer? _managerProgressTicker;
  Timer? _expectedEndTimer;
  Timer? _playbackHealthTicker;
  String? _expectedEndSignature;
  String? _managerWarmupSignature;
  String? _playbackHealthSignature;
  DateTime? _managerWarmupUntilUtc;
  DateTime? _lastHealthyHlsAtUtc;
  DateTime? _hlsStallGraceUntilUtc;
  DateTime? _lastHlsRecoveryAttemptAtUtc;
  double? _lastHealthyHlsPositionSeconds;
  String? _lastAppliedRemotePlaybackSignature;

  /// Set when a trackEnded command fires; holds the queueItemId of the track
  /// that just finished. While this is non-null, stale SpaceStateSync
  /// snapshots that still reference this queueItemId are ignored to prevent
  /// seek-to-0 jitter and progress bar freezes.
  String? _trackEndedQueueItemId;

  /// Holds the HLS URL of the completed track so stale snapshots that no
  /// longer include queue identity can still be suppressed.
  String? _trackEndedHlsUrl;

  /// When the trackEnded guard was set. Kept for tracing while the player is
  /// waiting for CAMS to publish the next authoritative stream.
  DateTime? _trackEndedAtUtc;
  bool _hlsRefreshIssuedForCurrentStall = false;
  static const Duration _managerWarmupDuration = Duration(seconds: 4);
  static const double _managerWarmupCompensationSeconds = 2;
  static const Duration _managerProgressTickInterval =
      Duration(milliseconds: 250);
  static const Duration _playbackHealthTickInterval = Duration(seconds: 2);
  static const Duration _hlsStallThreshold = Duration(seconds: 8);
  static const Duration _hlsReloadThreshold = Duration(seconds: 16);
  static const Duration _hlsRecoveryCooldown = Duration(seconds: 10);
  static const Duration _hlsStartupGrace = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notificationCommandSub =
          context.read<PlaybackNotificationService>().commands.listen(
                _handleNotificationCommand,
              );
      if (sl.isRegistered<DioClient>()) {
        _sessionInvalidatedSub =
            sl<DioClient>().onSessionInvalidated.listen((_) {
          if (!mounted) return;
          _debugLog('auth session invalidated -> resetting SessionCubit');
          _addCamsEvent(const CamsDisposePlayback());
          _addPlayerEvent(const PlayerContextCleared());
          unawaited(context.read<PlaybackNotificationService>().clear());
          context.read<SessionCubit>().reset();
          AppRouter.router.go('/welcome');
        });
      }
      _syncSession(context.read<SessionCubit>().state);
      unawaited(
        _attemptPlaybackDeviceRefreshIfNeeded(reason: 'post-init'),
      );
      _syncNotification(
        session: context.read<SessionCubit>().state,
        playerState: context.read<PlayerBloc>().state,
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        _attemptPlaybackDeviceRefreshIfNeeded(reason: 'app-resumed'),
      );
    }
  }

  void _syncSession(SessionState session) {
    final hasLocalStorage = sl.isRegistered<LocalStorageService>();
    final localStorage = hasLocalStorage ? sl<LocalStorageService>() : null;
    _debugLog(
      'syncSession '
      'mode=${session.appMode.name} '
      'role=${session.currentRole.label} '
      'store=${session.currentStore?.id ?? '-'} '
      'space=${session.currentSpace?.id ?? '-'} '
      'activeSessionMode=${localStorage?.getActiveSessionMode() ?? 'n/a'} '
      'hasManagerToken=${(localStorage?.getManagerAuthToken()?.isNotEmpty ?? false)} '
      'hasDeviceAccessToken=${(localStorage?.getDeviceAccessToken()?.isNotEmpty ?? false)} '
      'hasDeviceRefreshToken=${(localStorage?.getDeviceRefreshToken()?.isNotEmpty ?? false)}',
    );

    // If local device auth context is gone (e.g. refresh failure cleared it),
    // force a session reset so router can leave playback-device mode instead
    // of continuously firing unauthorized manager APIs.
    if (session.isPlaybackDevice && localStorage != null) {
      final deviceAccessToken = localStorage.getDeviceAccessToken();
      final deviceRefreshToken = localStorage.getDeviceRefreshToken();
      final hasDeviceAuthContext =
          (deviceAccessToken != null && deviceAccessToken.isNotEmpty) ||
              (deviceRefreshToken != null && deviceRefreshToken.isNotEmpty);
      if (!hasDeviceAuthContext) {
        _debugLog(
          'playback-device session has no local auth context -> reset session '
          '(hasDeviceAccessToken=${deviceAccessToken != null && deviceAccessToken.isNotEmpty} '
          'hasDeviceRefreshToken=${deviceRefreshToken != null && deviceRefreshToken.isNotEmpty})',
        );
        context.read<SessionCubit>().reset();
        return;
      }
    }

    final playerBloc = context.read<PlayerBloc>();
    final camsBloc = context.read<CamsPlaybackBloc>();
    final notificationService = context.read<PlaybackNotificationService>();
    final store = session.currentStore;
    final space = session.currentSpace;

    if (store == null || space == null) {
      _hydratedPlaylistId = null;
      _trackMetadataCache.clear();
      _trackMetadataInFlight.clear();
      _clearTrackEndedGuard();
      _lastAppliedRemotePlaybackSignature = null;
      _stopManagerProgressTicker();
      _resetManagerWarmup();
      _stopExpectedEndWatcher();
      _stopPlaybackHealthTicker();
      playerBloc.add(const PlayerContextCleared());
      camsBloc.add(const CamsDisposePlayback());
      unawaited(notificationService.clear());
      return;
    }

    if (playerBloc.state.activeSpaceId != space.id) {
      _hydratedPlaylistId = null;
      _trackMetadataCache.clear();
      _trackMetadataInFlight.clear();
      _lastAppliedRemotePlaybackSignature = null;
      _trackEndedQueueItemId = null;
      _trackEndedHlsUrl = null;
      _trackEndedAtUtc = null;
      _resetManagerWarmup();
      _stopExpectedEndWatcher();
      _resetPlaybackHealthTracking();
    }

    playerBloc.add(PlayerContextUpdated(
      storeId: store.id,
      spaceId: space.id,
      spaceName: space.name,
    ));
    camsBloc.add(CamsInitPlayback(spaceId: space.id));
    _syncManagerProgressTicker(
      session: session,
      playbackState: camsBloc.state.playbackState,
    );
    _syncPlaybackHealthTicker(
      session: session,
      camsState: camsBloc.state,
      playerState: playerBloc.state,
    );
  }

  void _syncNotification({
    required SessionState session,
    required PlayerState playerState,
  }) {
    final shouldEnable = session.isPlaybackDevice &&
        session.currentStore != null &&
        session.currentSpace != null;

    context.read<PlaybackNotificationService>().syncPlayerState(
          playerState,
          enabled: shouldEnable,
        );
  }

  void _addPlayerEvent(PlayerEvent event) {
    if (!mounted) return;
    final playerBloc = context.read<PlayerBloc>();
    if (playerBloc.isClosed) return;
    playerBloc.add(event);
  }

  void _addCamsEvent(CamsPlaybackEvent event) {
    if (!mounted) return;
    final camsBloc = context.read<CamsPlaybackBloc>();
    if (camsBloc.isClosed) return;
    camsBloc.add(event);
  }

  void _syncCamsState(CamsPlaybackState camsState) {
    final playbackState = camsState.playbackState;
    final playerBloc = context.read<PlayerBloc>();
    final session = context.read<SessionCubit>().state;

    _debugLog(
      'syncCamsState '
      'status=${camsState.status.name} '
      'playback=${playbackState == null ? 'null' : _describePlaybackState(playbackState)} '
      'playerTrack=${playerBloc.state.currentTrack?.title ?? '-'} '
      'playerHls=${playerBloc.state.hlsUrl ?? '-'}',
    );

    _syncManagerProgressTicker(
      session: session,
      playbackState: playbackState,
    );
    _syncExpectedEndWatcher(
      session: session,
      playbackState: playbackState,
    );
    _syncPlaybackHealthTicker(
      session: session,
      camsState: camsState,
      playerState: playerBloc.state,
    );

    if (playbackState == null) {
      _clearTrackEndedGuard();
      _lastAppliedRemotePlaybackSignature = null;
      return;
    }

    final playbackWindowExpired = playbackState.hasPlayableHls &&
        !playbackState.isPaused &&
        !playbackState.isWithinPlaybackWindow;
    final incomingHlsUrl = playbackState.effectiveHlsUrl;
    final localHlsMatchesIncoming = playerBloc.state.isSyncedCamsPlayback &&
        incomingHlsUrl != null &&
        incomingHlsUrl.isNotEmpty &&
        incomingHlsUrl == playerBloc.state.hlsUrl;
    final localQueueMatchesIncoming =
        playerBloc.state.currentQueueItemId != null &&
            playerBloc.state.currentQueueItemId ==
                playbackState.effectiveQueueItemId;
    final shouldHoldExpiredCurrentStream = playbackWindowExpired &&
        (localHlsMatchesIncoming ||
            localQueueMatchesIncoming ||
            _matchesCompletedTrack(playbackState));
    if (shouldHoldExpiredCurrentStream) {
      _debugLog(
        'playback window expired for current HLS -> wait for next identity/HLS '
        'queueItemId=${playbackState.effectiveQueueItemId ?? '-'} '
        'hls=${incomingHlsUrl ?? '-'} '
        'expectedEnd=${playbackState.expectedEndAtUtc?.toUtc().toIso8601String() ?? '-'}',
      );
      if (session.isPlaybackDevice && playerBloc.state.isPlaying) {
        _addPlayerEvent(const PlayerRemoteCommandApplied(
          command: PlaybackCommandEnum.pause,
          playLocally: true,
        ));
      }
      _addPlayerEvent(PlayerAudioSettingsApplied(
        volumePercent: playbackState.volumePercent,
        isMuted: playbackState.isMuted,
      ));
      if (!session.isPlaybackDevice) {
        _pushManagerPositionSnapshot(playbackState);
      }
      return;
    }

    if (!camsState.isStreaming || !playbackState.hasPlayableHls) {
      final hasQueueIdentity =
          (playbackState.effectiveQueueItemId?.isNotEmpty ?? false) ||
              ((_resolveCurrentTrackId(playbackState)?.isNotEmpty ?? false));
      final hasQueueSnapshot = playbackState.spaceQueueItems.isNotEmpty;
      final shouldPreserveActiveRemoteStream =
          playerBloc.state.isSyncedCamsPlayback &&
              playerBloc.state.hasTrack &&
              playbackState.hasPendingPlayback;
      final shouldHoldCompletedTrack = _hasTrackEndedGuard() &&
          playerBloc.state.isSyncedCamsPlayback &&
          (playbackState.hasPendingPlayback || hasQueueSnapshot);
      if (shouldPreserveActiveRemoteStream) {
        _debugLog(
            'preserving active remote stream while pending queue update arrives');
        return;
      }
      if (shouldHoldCompletedTrack) {
        if (hasQueueSnapshot) {
          unawaited(_hydrateQueueForPlayback(playbackState));
        }
        final guardAgeSeconds = _trackEndedAtUtc == null
            ? 0
            : DateTime.now().toUtc().difference(_trackEndedAtUtc!).inSeconds;
        _debugLog(
          'holding completed track at end while waiting for next HLS '
          'queueItemId=${_trackEndedQueueItemId ?? '-'} '
          'ageSeconds=$guardAgeSeconds',
        );
        _addPlayerEvent(PlayerAudioSettingsApplied(
          volumePercent: playbackState.volumePercent,
          isMuted: playbackState.isMuted,
        ));
        return;
      }
      if (hasQueueSnapshot) {
        unawaited(_hydrateQueueForPlayback(playbackState));
        final focusedQueueItem = _resolveFocusedQueueItem(playbackState);
        if (focusedQueueItem != null) {
          _lastAppliedRemotePlaybackSignature = null;
          _debugLog(
            'queue-only snapshot -> focus preview '
            'queueItemId=${focusedQueueItem.queueItemId} '
            'trackId=${focusedQueueItem.trackId} '
            'trackName=${focusedQueueItem.trackName ?? '-'}',
          );
          _addPlayerEvent(PlayerQueueFocusApplied(
            queueItemId: focusedQueueItem.queueItemId,
            trackId: focusedQueueItem.trackId,
            isPlaying: false,
          ));
          _addPlayerEvent(PlayerAudioSettingsApplied(
            volumePercent: playbackState.volumePercent,
            isMuted: playbackState.isMuted,
          ));
        } else if (playerBloc.state.isSyncedCamsPlayback) {
          _lastAppliedRemotePlaybackSignature = null;
          _debugLog(
            'queue snapshot contains no active/pending candidate -> stop local HLS playback',
          );
          _addPlayerEvent(const PlayerHlsStopped());
        }
        return;
      }
      final shouldStopPlayer =
          !playbackState.hasPendingPlayback && !hasQueueIdentity;
      if (!shouldStopPlayer) {
        _debugLog(
            'ignoring non-streaming snapshot because queue identity still exists');
        return;
      }
      _hydratedPlaylistId = null;
      _stopPlaybackHealthTicker();
      _clearTrackEndedGuard();
      _lastAppliedRemotePlaybackSignature = null;
      _debugLog('non-streaming snapshot with no queue identity -> stop player');
      _addPlayerEvent(const PlayerHlsStopped());
      return;
    }

    unawaited(_hydrateQueueForPlayback(playbackState));

    if (_hasTrackEndedGuard()) {
      if (_matchesCompletedTrack(playbackState)) {
        _debugLog(
          'ignoring stale HLS snapshot while waiting for next track '
          'queueItemId=${playbackState.effectiveQueueItemId ?? '-'} '
          'hls=${playbackState.effectiveHlsUrl ?? '-'}',
        );
        _addPlayerEvent(PlayerAudioSettingsApplied(
          volumePercent: playbackState.volumePercent,
          isMuted: playbackState.isMuted,
        ));
        return;
      }
      _debugLog(
        'new track identity/HLS arrived after completion -> clearing guard '
        'oldQueueItemId=${_trackEndedQueueItemId ?? '-'} '
        'newQueueItemId=${playbackState.effectiveQueueItemId ?? '-'}',
      );
      _clearTrackEndedGuard();
    }

    // Legacy queue-item guard kept as a secondary safety net for the short
    // race window before the broader completed-track guard above is updated.
    if (_trackEndedQueueItemId != null) {
      // Auto-expire the queue-item-only fallback; stale-HLS suppression above
      // remains active until a new authoritative stream arrives.
      final guardAge = _trackEndedAtUtc != null
          ? DateTime.now().toUtc().difference(_trackEndedAtUtc!)
          : Duration.zero;
      if (guardAge > const Duration(seconds: 10)) {
        _debugLog(
          'trackEnded guard expired after ${guardAge.inSeconds}s — clearing',
        );
        _trackEndedQueueItemId = null;
        _trackEndedAtUtc = null;
      } else {
        final incoming = playbackState.effectiveQueueItemId;
        if (incoming != null &&
            incoming.isNotEmpty &&
            incoming == _trackEndedQueueItemId) {
          _debugLog(
            'ignoring stale HLS snapshot — '
            'queueItemId=$incoming matches completed track',
          );
          return;
        }
        // New track identity arrived — clear the guard.
        _trackEndedQueueItemId = null;
        _trackEndedAtUtc = null;
      }
    }

    final remotePlaybackSignature = _remotePlaybackSignatureFor(playbackState);
    if (_lastAppliedRemotePlaybackSignature == remotePlaybackSignature) {
      _addPlayerEvent(PlayerAudioSettingsApplied(
        volumePercent: playbackState.volumePercent,
        isMuted: playbackState.isMuted,
      ));
      if (!session.isPlaybackDevice) {
        _pushManagerPositionSnapshot(playbackState);
      }
      return;
    }
    _lastAppliedRemotePlaybackSignature = remotePlaybackSignature;

    _debugLog(
      'active HLS snapshot -> start player '
      'queueItemId=${playbackState.effectiveQueueItemId ?? '-'} '
      'trackId=${_resolveCurrentTrackId(playbackState) ?? '-'} '
      'trackName=${playbackState.effectiveTrackName ?? '-'} '
      'hls=${playbackState.effectiveHlsUrl}',
    );

    _addPlayerEvent(PlayerHlsStarted(
      hlsUrl: playbackState.effectiveHlsUrl!,
      playlistName: playbackState.currentDisplayName,
      queueItemId: playbackState.effectiveQueueItemId,
      trackId: _resolveCurrentTrackId(playbackState) ?? playbackState.spaceId,
      trackName: playbackState.effectiveTrackName,
      seekOffsetSeconds: playbackState.effectiveSeekOffset,
      isPaused: playbackState.isPaused,
      playLocally: session.isPlaybackDevice,
    ));

    _addPlayerEvent(PlayerAudioSettingsApplied(
      volumePercent: playbackState.volumePercent,
      isMuted: playbackState.isMuted,
    ));

    if (!session.isPlaybackDevice) {
      _pushManagerPositionSnapshot(playbackState);
    }
  }

  String _remotePlaybackSignatureFor(SpacePlaybackState playbackState) {
    return [
      playbackState.spaceId.toLowerCase(),
      playbackState.effectiveQueueItemId ?? '',
      _resolveCurrentTrackId(playbackState) ?? '',
      playbackState.effectiveHlsUrl ?? '',
      playbackState.isPaused ? '1' : '0',
      playbackState.effectiveSeekOffset.round().toString(),
    ].join('|');
  }

  String? _resolveCurrentTrackId(SpacePlaybackState playbackState) {
    return _resolveFocusedQueueItem(playbackState)?.trackId;
  }

  SpaceQueueStateItem? _resolveFocusedQueueItem(
    SpacePlaybackState playbackState,
  ) {
    final queueItems = playbackState.spaceQueueItems;
    if (queueItems.isEmpty) return null;

    final currentQueueItemId = playbackState.currentQueueItemId;
    if (currentQueueItemId != null && currentQueueItemId.isNotEmpty) {
      for (final queueItem in queueItems) {
        if (queueItem.queueItemId == currentQueueItemId) {
          return queueItem;
        }
      }
    }

    final pendingQueueItemId = playbackState.pendingQueueItemId;
    if (pendingQueueItemId != null && pendingQueueItemId.isNotEmpty) {
      for (final queueItem in queueItems) {
        if (queueItem.queueItemId == pendingQueueItemId) {
          return queueItem;
        }
      }
    }

    for (final queueItem in queueItems) {
      if (queueItem.queueStatus == SpacePlaybackState.queueStatusPlaying) {
        return queueItem;
      }
    }

    final sortedItems = [...queueItems]
      ..sort((a, b) => a.position.compareTo(b.position));
    for (final queueItem in sortedItems) {
      if (queueItem.queueStatus == SpacePlaybackState.queueStatusPending) {
        return queueItem;
      }
    }

    return null;
  }

  String _queueSignature(SpacePlaybackState? playbackState) {
    if (playbackState == null || playbackState.spaceQueueItems.isEmpty) {
      return '';
    }
    final sortedItems = [...playbackState.spaceQueueItems]
      ..sort((a, b) => a.position.compareTo(b.position));
    return sortedItems
        .map(
          (item) => [
            item.queueItemId,
            item.trackId,
            item.position,
            item.queueStatus,
            item.isReadyToStream ? 1 : 0,
          ].join(':'),
        )
        .join('|');
  }

  Map<String, Track> _trackMetadataSnapshot(PlayerState playerState) {
    final snapshot = <String, Track>{};

    void mergeTrack(Track? track) {
      if (track == null) return;
      final existing = snapshot[track.id];
      if (existing == null) {
        snapshot[track.id] = track;
        return;
      }
      final existingScore = _trackMetadataScore(existing);
      final candidateScore = _trackMetadataScore(track);
      snapshot[track.id] = candidateScore >= existingScore ? track : existing;
    }

    for (final track in _trackMetadataCache.values) {
      mergeTrack(track);
    }
    mergeTrack(playerState.currentTrack);
    for (final track in playerState.queue) {
      mergeTrack(track);
    }
    return snapshot;
  }

  int _trackMetadataScore(Track track) {
    var score = 0;
    if (track.artist.trim().isNotEmpty &&
        track.artist.trim().toLowerCase() != 'unknown artist') {
      score += 2;
    }
    if (track.albumArt?.trim().isNotEmpty ?? false) {
      score += 2;
    }
    if (track.duration != null && track.duration! > 0) {
      score += 1;
    }
    if (track.fileUrl.trim().isNotEmpty) {
      score += 1;
    }
    return score;
  }

  Track _trackFromApiTrack(ApiTrack apiTrack) {
    return Track(
      id: apiTrack.id,
      title: apiTrack.title,
      artist: (apiTrack.artist?.trim().isNotEmpty ?? false)
          ? apiTrack.artist!.trim()
          : 'Unknown Artist',
      fileUrl: apiTrack.hlsUrl ?? apiTrack.sourceAudioUrl ?? '',
      moodTags: [
        if (apiTrack.moodName?.trim().isNotEmpty ?? false)
          apiTrack.moodName!.trim(),
      ],
      duration: apiTrack.durationSec,
      albumArt: apiTrack.coverImageUrl,
    );
  }

  Future<bool> _primeTrackMetadataForQueue(
    List<SpaceQueueStateItem> queueItems,
  ) async {
    if (!sl.isRegistered<GetTrackById>()) return false;

    final pendingTrackIds = queueItems
        .map((item) => item.trackId)
        .where((trackId) =>
            trackId.isNotEmpty &&
            !_trackMetadataCache.containsKey(trackId) &&
            !_trackMetadataInFlight.contains(trackId))
        .toSet()
        .toList(growable: false);

    if (pendingTrackIds.isEmpty) return false;

    final getTrackById = sl<GetTrackById>();
    var didUpdate = false;

    await Future.wait(
      pendingTrackIds.map((trackId) async {
        _trackMetadataInFlight.add(trackId);
        try {
          final result = await getTrackById(trackId);
          result.fold(
            (_) {},
            (track) {
              _trackMetadataCache[trackId] = _trackFromApiTrack(track);
              didUpdate = true;
            },
          );
        } finally {
          _trackMetadataInFlight.remove(trackId);
        }
      }),
    );

    return didUpdate;
  }

  Future<void> _hydrateQueueForPlayback(
      SpacePlaybackState playbackState) async {
    if (!mounted) return;

    final queueItems = playbackState.spaceQueueItems;
    if (queueItems.isEmpty) {
      _hydratedPlaylistId = null;
      return;
    }

    final signature = [
      playbackState.spaceId,
      playbackState.effectiveQueueItemId ?? '',
      ...queueItems.map((item) => item.queueItemId),
    ].join('|');

    if (_hydratedPlaylistId != signature) {
      _hydratedPlaylistId = signature;
      final queue = buildSpaceQueue(
        queueItems,
        trackMetadataById: _trackMetadataSnapshot(
          context.read<PlayerBloc>().state,
        ),
      );
      _debugLog(
        'hydrateQueueForPlayback '
        'queueCount=${queue.length} '
        'signature=$signature '
        'tracks=${queue.take(4).map((track) => track.title).join(' | ')}',
      );
      _addPlayerEvent(PlayerQueueSeeded(
        tracks: queue,
        playlistName: playbackState.currentDisplayName,
        playlistId: null,
        force: true,
      ));
    }

    final didHydrateMetadata = await _primeTrackMetadataForQueue(queueItems);
    if (!mounted || !didHydrateMetadata) return;

    final latestPlaybackState =
        context.read<CamsPlaybackBloc>().state.playbackState;
    if (latestPlaybackState == null ||
        latestPlaybackState.spaceId != playbackState.spaceId ||
        _queueSignature(latestPlaybackState) !=
            _queueSignature(playbackState)) {
      return;
    }

    final enrichedQueue = buildSpaceQueue(
      queueItems,
      trackMetadataById: _trackMetadataSnapshot(
        context.read<PlayerBloc>().state,
      ),
    );
    _debugLog(
      'hydrateQueueForPlayback metadata refreshed '
      'queueCount=${enrichedQueue.length} '
      'tracks=${enrichedQueue.take(4).map((track) => '${track.title}/${track.artist}').join(' | ')}',
    );
    _addPlayerEvent(PlayerQueueSeeded(
      tracks: enrichedQueue,
      playlistName: playbackState.currentDisplayName,
      playlistId: null,
      force: true,
    ));

    if (!latestPlaybackState.hasPlayableHls) {
      final focusedQueueItem = _resolveFocusedQueueItem(latestPlaybackState);
      if (focusedQueueItem != null) {
        _addPlayerEvent(PlayerQueueFocusApplied(
          queueItemId: focusedQueueItem.queueItemId,
          trackId: focusedQueueItem.trackId,
          isPlaying: false,
        ));
      }
    }
  }

  void _syncManagerProgressTicker({
    required SessionState session,
    required SpacePlaybackState? playbackState,
  }) {
    if (session.isPlaybackDevice ||
        playbackState == null ||
        !playbackState.isStreaming) {
      _stopManagerProgressTicker();
      _resetManagerWarmup();
      return;
    }

    _updateManagerWarmup(playbackState);
    _pushManagerPositionSnapshot(playbackState);

    if (playbackState.isPaused) {
      _stopManagerProgressTicker();
      _resetManagerWarmup();
      return;
    }

    _managerProgressTicker?.cancel();
    _managerProgressTicker = Timer.periodic(_managerProgressTickInterval, (_) {
      if (!mounted) return;

      final currentSession = context.read<SessionCubit>().state;
      final currentPlaybackState =
          context.read<CamsPlaybackBloc>().state.playbackState;
      if (currentSession.isPlaybackDevice ||
          currentPlaybackState == null ||
          !currentPlaybackState.isStreaming ||
          currentPlaybackState.isPaused) {
        _stopManagerProgressTicker();
        return;
      }

      _pushManagerPositionSnapshot(currentPlaybackState);
    });
  }

  void _pushManagerPositionSnapshot(SpacePlaybackState playbackState) {
    if (!mounted) return;

    _addPlayerEvent(
      PlayerPositionUpdated(
        positionSeconds: _snapshotPositionSeconds(playbackState),
        isAbsolutePosition: true,
      ),
    );
  }

  double _snapshotPositionSeconds(SpacePlaybackState playbackState) {
    var effectiveSeekOffset = playbackState.effectiveSeekOffset;
    if (!playbackState.isPaused && _isManagerWarmupActive(playbackState)) {
      effectiveSeekOffset =
          (effectiveSeekOffset - _managerWarmupCompensationSeconds)
              .clamp(0.0, double.infinity);
    }
    return effectiveSeekOffset;
  }

  void _stopManagerProgressTicker() {
    _managerProgressTicker?.cancel();
    _managerProgressTicker = null;
  }

  void _resetManagerWarmup() {
    _managerWarmupSignature = null;
    _managerWarmupUntilUtc = null;
  }

  String _streamWarmupSignature(SpacePlaybackState playbackState) {
    return [
      playbackState.spaceId.toLowerCase(),
      playbackState.currentIdentityId ?? '',
      playbackState.effectiveHlsUrl ?? '',
      playbackState.startedAtUtc?.toUtc().toIso8601String() ?? '',
    ].join('|');
  }

  void _updateManagerWarmup(SpacePlaybackState playbackState) {
    if (playbackState.isPaused) {
      _managerWarmupUntilUtc = null;
      return;
    }

    final signature = _streamWarmupSignature(playbackState);
    if (_managerWarmupSignature != signature) {
      _managerWarmupSignature = signature;
      if (playbackState.effectiveSeekOffset <= 6) {
        _managerWarmupUntilUtc =
            DateTime.now().toUtc().add(_managerWarmupDuration);
      } else {
        _managerWarmupUntilUtc = null;
      }
    }
  }

  bool _isManagerWarmupActive(SpacePlaybackState playbackState) {
    final warmupUntilUtc = _managerWarmupUntilUtc;
    if (warmupUntilUtc == null) return false;
    if (_managerWarmupSignature != _streamWarmupSignature(playbackState)) {
      return false;
    }
    final isActive = DateTime.now().toUtc().isBefore(warmupUntilUtc);
    if (!isActive) {
      _managerWarmupUntilUtc = null;
    }
    return isActive;
  }

  void _syncExpectedEndWatcher({
    required SessionState session,
    required SpacePlaybackState? playbackState,
  }) {
    if (session.currentSpace == null ||
        playbackState == null ||
        !playbackState.isStreaming ||
        playbackState.isPaused ||
        playbackState.expectedEndAtUtc == null) {
      _stopExpectedEndWatcher();
      return;
    }

    final expectedEndUtc = playbackState.expectedEndAtUtc!.toUtc();
    final signature = [
      playbackState.spaceId.toLowerCase(),
      playbackState.currentIdentityId ?? '',
      playbackState.effectiveHlsUrl ?? '',
      expectedEndUtc.toIso8601String(),
    ].join('|');

    if (_expectedEndSignature == signature && _expectedEndTimer != null) {
      return;
    }

    _expectedEndSignature = signature;
    _expectedEndTimer?.cancel();

    final delay = expectedEndUtc.difference(DateTime.now().toUtc());
    if (delay <= Duration.zero) {
      _handleExpectedEndReached(
        watchedSpaceId: playbackState.spaceId,
        watchedIdentityId: playbackState.currentIdentityId,
        watchedHlsUrl: playbackState.effectiveHlsUrl,
      );
      return;
    }

    _expectedEndTimer = Timer(delay, () {
      if (!mounted) return;
      _handleExpectedEndReached(
        watchedSpaceId: playbackState.spaceId,
        watchedIdentityId: playbackState.currentIdentityId,
        watchedHlsUrl: playbackState.effectiveHlsUrl,
      );
    });
  }

  void _handleExpectedEndReached({
    required String watchedSpaceId,
    required String? watchedIdentityId,
    required String? watchedHlsUrl,
  }) {
    if (!mounted) return;

    final camsBloc = context.read<CamsPlaybackBloc>();
    final activePlayback = camsBloc.state.playbackState;
    if (activePlayback == null || !activePlayback.isStreaming) {
      _stopExpectedEndWatcher();
      return;
    }

    final activeSpaceId = activePlayback.spaceId.toLowerCase();
    if (activeSpaceId != watchedSpaceId.toLowerCase()) {
      _stopExpectedEndWatcher();
      return;
    }
    if ((activePlayback.currentIdentityId ?? '') != (watchedIdentityId ?? '')) {
      _stopExpectedEndWatcher();
      return;
    }
    if ((activePlayback.effectiveHlsUrl ?? '') != (watchedHlsUrl ?? '')) {
      _stopExpectedEndWatcher();
      return;
    }

    final expectedEndUtc = activePlayback.expectedEndAtUtc?.toUtc();
    if (expectedEndUtc == null ||
        DateTime.now().toUtc().isBefore(
              expectedEndUtc.subtract(const Duration(seconds: 1)),
            )) {
      _syncExpectedEndWatcher(
        session: context.read<SessionCubit>().state,
        playbackState: activePlayback,
      );
      return;
    }

    // Do not force-stop local player from the timer alone because backend
    // ExpectedEndAtUtc can drift around pause/resume. Reconcile from server state.
    _addCamsEvent(const CamsRefreshState(silent: true));
    _stopExpectedEndWatcher();
  }

  void _stopExpectedEndWatcher() {
    _expectedEndTimer?.cancel();
    _expectedEndTimer = null;
    _expectedEndSignature = null;
  }

  bool _hasTrackEndedGuard() {
    return (_trackEndedQueueItemId?.isNotEmpty ?? false) ||
        (_trackEndedHlsUrl?.isNotEmpty ?? false);
  }

  bool _matchesCompletedTrack(SpacePlaybackState playbackState) {
    final incomingQueueItemId = playbackState.effectiveQueueItemId;
    if ((_trackEndedQueueItemId?.isNotEmpty ?? false) &&
        incomingQueueItemId != null &&
        incomingQueueItemId.isNotEmpty &&
        incomingQueueItemId == _trackEndedQueueItemId) {
      return true;
    }

    final incomingHlsUrl = playbackState.effectiveHlsUrl;
    if ((_trackEndedHlsUrl?.isNotEmpty ?? false) &&
        incomingHlsUrl != null &&
        incomingHlsUrl.isNotEmpty &&
        incomingHlsUrl == _trackEndedHlsUrl) {
      return true;
    }

    return false;
  }

  void _clearTrackEndedGuard() {
    _trackEndedQueueItemId = null;
    _trackEndedHlsUrl = null;
    _trackEndedAtUtc = null;
  }

  String _playbackHealthSignatureFor(SpacePlaybackState playbackState) {
    return [
      playbackState.spaceId.toLowerCase(),
      playbackState.currentIdentityId ?? '',
      playbackState.effectiveHlsUrl ?? '',
      playbackState.startedAtUtc?.toUtc().toIso8601String() ?? '',
    ].join('|');
  }

  void _resetPlaybackHealthTracking() {
    _playbackHealthSignature = null;
    _lastHealthyHlsAtUtc = null;
    _hlsStallGraceUntilUtc = null;
    _lastHlsRecoveryAttemptAtUtc = null;
    _lastHealthyHlsPositionSeconds = null;
    _hlsRefreshIssuedForCurrentStall = false;
  }

  void _stopPlaybackHealthTicker() {
    _playbackHealthTicker?.cancel();
    _playbackHealthTicker = null;
    _resetPlaybackHealthTracking();
  }

  void _syncPlaybackHealthTicker({
    required SessionState session,
    required CamsPlaybackState camsState,
    required PlayerState playerState,
  }) {
    final playbackState = camsState.playbackState;
    final shouldMonitor = session.isPlaybackDevice &&
        session.currentSpace != null &&
        playbackState != null &&
        playbackState.isStreaming &&
        !playbackState.isPaused &&
        playerState.isPlaying &&
        (playbackState.effectiveHlsUrl?.isNotEmpty ?? false);

    if (!shouldMonitor) {
      _stopPlaybackHealthTicker();
      return;
    }

    final nowUtc = DateTime.now().toUtc();
    final signature = _playbackHealthSignatureFor(playbackState);
    if (_playbackHealthSignature != signature) {
      _playbackHealthSignature = signature;
      _lastHealthyHlsPositionSeconds = playerState.currentPositionPrecise;
      _lastHealthyHlsAtUtc = nowUtc;
      _hlsStallGraceUntilUtc = nowUtc.add(_hlsStartupGrace);
      _hlsRefreshIssuedForCurrentStall = false;
      _lastHlsRecoveryAttemptAtUtc = null;
    }

    _playbackHealthTicker ??= Timer.periodic(
      _playbackHealthTickInterval,
      (_) => _checkPlaybackHealthTick(),
    );
  }

  void _checkPlaybackHealthTick() {
    if (!mounted) return;

    final session = context.read<SessionCubit>().state;
    final camsBloc = context.read<CamsPlaybackBloc>();
    final playerBloc = context.read<PlayerBloc>();
    final camsState = camsBloc.state;
    final playbackState = camsState.playbackState;
    final playerState = playerBloc.state;

    if (!session.isPlaybackDevice ||
        session.currentSpace == null ||
        playbackState == null ||
        !playbackState.isStreaming ||
        playbackState.isPaused ||
        playbackState.effectiveHlsUrl == null ||
        playbackState.effectiveHlsUrl!.isEmpty) {
      _stopPlaybackHealthTicker();
      return;
    }

    final signature = _playbackHealthSignatureFor(playbackState);
    if (_playbackHealthSignature != signature) {
      _syncPlaybackHealthTicker(
        session: session,
        camsState: camsState,
        playerState: playerState,
      );
      return;
    }

    final nowUtc = DateTime.now().toUtc();
    final graceUntilUtc = _hlsStallGraceUntilUtc;
    if (graceUntilUtc != null && nowUtc.isBefore(graceUntilUtc)) {
      _lastHealthyHlsPositionSeconds = playerState.currentPositionPrecise;
      _lastHealthyHlsAtUtc = nowUtc;
      return;
    }

    // Skip health checks until local player has finished syncing this stream.
    if (!playerState.isSyncedCamsPlayback ||
        playerState.hlsUrl != playbackState.effectiveHlsUrl) {
      return;
    }

    final currentPosition = playerState.currentPositionPrecise;
    final previousPosition = _lastHealthyHlsPositionSeconds;
    if (previousPosition == null || currentPosition > previousPosition) {
      _lastHealthyHlsPositionSeconds = currentPosition;
      _lastHealthyHlsAtUtc = nowUtc;
      _hlsRefreshIssuedForCurrentStall = false;
      return;
    }

    final lastHealthyAtUtc = _lastHealthyHlsAtUtc ?? nowUtc;
    final stallDuration = nowUtc.difference(lastHealthyAtUtc);
    final canAttemptRecovery = _lastHlsRecoveryAttemptAtUtc == null ||
        nowUtc.difference(_lastHlsRecoveryAttemptAtUtc!) >=
            _hlsRecoveryCooldown;

    if (stallDuration >= _hlsReloadThreshold &&
        _hlsRefreshIssuedForCurrentStall &&
        canAttemptRecovery) {
      _lastHlsRecoveryAttemptAtUtc = nowUtc;
      _hlsRefreshIssuedForCurrentStall = false;
      _addPlayerEvent(PlayerHlsStarted(
        hlsUrl: playbackState.effectiveHlsUrl!,
        playlistName: playbackState.currentDisplayName,
        queueItemId: playbackState.effectiveQueueItemId,
        trackId: _resolveCurrentTrackId(playbackState) ?? playbackState.spaceId,
        trackName: playbackState.effectiveTrackName,
        seekOffsetSeconds: playbackState.effectiveSeekOffset,
        isPaused: playbackState.isPaused,
        playLocally: true,
        forceReload: true,
      ));
      _addCamsEvent(const CamsRefreshState(silent: true));
      return;
    }

    if (stallDuration >= _hlsStallThreshold &&
        !_hlsRefreshIssuedForCurrentStall &&
        canAttemptRecovery) {
      _lastHlsRecoveryAttemptAtUtc = nowUtc;
      _hlsRefreshIssuedForCurrentStall = true;
      _addCamsEvent(const CamsRefreshState(silent: true));
    }
  }

  void _handleNotificationCommand(PlaybackNotificationCommand command) {
    if (!mounted) return;

    final session = context.read<SessionCubit>().state;
    if (!session.isPlaybackDevice) return;

    final playerBloc = context.read<PlayerBloc>();
    final playerState = playerBloc.state;
    final canRouteToCams =
        playerState.isHlsMode && session.currentSpace != null;

    if (canRouteToCams) {
      switch (command) {
        case PlaybackNotificationCommand.play:
          if (!playerState.isPlaying) {
            _addPlayerEvent(const PlayerRemoteCommandApplied(
              command: PlaybackCommandEnum.resume,
              playLocally: true,
            ));
            _addCamsEvent(const CamsSendCommand(
              command: PlaybackCommandEnum.resume,
            ));
          }
          return;
        case PlaybackNotificationCommand.pause:
          if (playerState.isPlaying) {
            _addPlayerEvent(const PlayerRemoteCommandApplied(
              command: PlaybackCommandEnum.pause,
              playLocally: true,
            ));
            _addCamsEvent(const CamsSendCommand(
              command: PlaybackCommandEnum.pause,
            ));
          }
          return;
        case PlaybackNotificationCommand.skipNext:
          _addCamsEvent(const CamsSendCommand(
            command: PlaybackCommandEnum.skipNext,
          ));
          return;
      }
    }

    switch (command) {
      case PlaybackNotificationCommand.play:
        if (!playerState.isPlaying) {
          _addPlayerEvent(const PlayerPlayPauseToggled());
        }
        return;
      case PlaybackNotificationCommand.pause:
        if (playerState.isPlaying) {
          _addPlayerEvent(const PlayerPlayPauseToggled());
        }
        return;
      case PlaybackNotificationCommand.skipNext:
        _addPlayerEvent(const PlayerSkipRequested());
        return;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationCommandSub?.cancel();
    _sessionInvalidatedSub?.cancel();
    _stopManagerProgressTicker();
    _stopExpectedEndWatcher();
    _stopPlaybackHealthTicker();
    super.dispose();
  }

  Future<void> _attemptPlaybackDeviceRefreshIfNeeded({
    required String reason,
  }) async {
    if (!mounted || !sl.isRegistered<DioClient>()) {
      return;
    }

    final session = context.read<SessionCubit>().state;
    final localStorage = sl.isRegistered<LocalStorageService>()
        ? sl<LocalStorageService>()
        : null;
    final activeMode = localStorage?.getActiveSessionMode();
    final shouldConsiderPlaybackRefresh = session.isPlaybackDevice ||
        activeMode == LocalStorageService.sessionModePlaybackDevice;
    if (!shouldConsiderPlaybackRefresh) {
      return;
    }

    final expiry = localStorage?.getDeviceAccessTokenExpiry();
    _debugLog(
      'attemptPlaybackDeviceRefreshIfNeeded '
      'reason=$reason '
      'expiry=${expiry?.toUtc().toIso8601String() ?? '-'}',
    );
    await sl<DioClient>().refreshPlaybackDeviceTokenIfNeeded();
  }

  void _debugLog(String message) {
    debugPrint('[AppPlaybackCoordinatorV2] $message');
  }

  void _traceLog(String message) {
    debugPrint('[PlaybackTrace] $message');
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
        'current=${playbackState.effectiveQueueItemId ?? '-'} '
        'pending=${playbackState.pendingQueueItemId ?? '-'} '
        'track=${playbackState.effectiveTrackName ?? '-'} '
        'hls=${playbackState.effectiveHlsUrl ?? '-'} '
        'queueCount=${playbackState.spaceQueueItems.length} '
        'queue=[$queuePreview]';
  }

  Widget _buildDebugAuthButton(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    final localStorage = sl<LocalStorageService>();
    final isPlaybackDevice = session.isPlaybackDevice;
    final hasDeviceAccessToken =
        localStorage.getDeviceAccessToken()?.isNotEmpty ?? false;
    final hasDeviceRefreshToken =
        localStorage.getDeviceRefreshToken()?.isNotEmpty ?? false;

    final backgroundColor = isPlaybackDevice
        ? Colors.orangeAccent.withValues(alpha: 0.95)
        : Colors.blueGrey.withValues(alpha: 0.92);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      elevation: 6,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _showDebugAuthSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bug_report_outlined, size: 16),
              const SizedBox(width: 6),
              Text(
                'AUTH ${isPlaybackDevice ? "PD" : "RC"} '
                '${hasDeviceAccessToken ? "A" : "-"}'
                '${hasDeviceRefreshToken ? "R" : "-"}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDebugAuthSheet(BuildContext context) async {
    final sheetContext = AppRouter.rootNavigatorKey.currentContext ?? context;
    final session = context.read<SessionCubit>().state;
    final localStorage = sl<LocalStorageService>();
    final deviceSession = localStorage.getDeviceSession();

    String formatExpiry(DateTime? value) {
      return value?.toUtc().toIso8601String() ?? 'null';
    }

    final details = <MapEntry<String, String>>[
      MapEntry('session.appMode', session.appMode.name),
      MapEntry('session.role', session.currentRole.label),
      MapEntry('session.storeId', session.currentStore?.id ?? 'null'),
      MapEntry('session.spaceId', session.currentSpace?.id ?? 'null'),
      MapEntry(
        'activeSessionMode',
        localStorage.getActiveSessionMode() ?? 'null',
      ),
      MapEntry(
        'hasManagerToken',
        ((localStorage.getManagerAuthToken()?.isNotEmpty ?? false)).toString(),
      ),
      MapEntry(
        'managerExpiryUtc',
        formatExpiry(localStorage.getManagerAccessTokenExpiry()),
      ),
      MapEntry(
        'hasDeviceAccessToken',
        ((localStorage.getDeviceAccessToken()?.isNotEmpty ?? false)).toString(),
      ),
      MapEntry(
        'deviceAccessExpiryUtc',
        formatExpiry(localStorage.getDeviceAccessTokenExpiry()),
      ),
      MapEntry(
        'hasDeviceRefreshToken',
        ((localStorage.getDeviceRefreshToken()?.isNotEmpty ?? false))
            .toString(),
      ),
      MapEntry(
        'deviceSessionKeys',
        deviceSession?.keys.join(', ') ?? '(none)',
      ),
    ];

    await showModalBottomSheet<void>(
      context: sheetContext,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            shrinkWrap: true,
            children: [
              Text(
                'Playback Auth Debug',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              for (final entry in details) ...[
                Text(
                  entry.key,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 2),
                SelectableText(
                  entry.value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = MultiBlocListener(
      listeners: [
        BlocListener<SessionCubit, SessionState>(
          listenWhen: (previous, current) =>
              previous.currentStore?.id != current.currentStore?.id ||
              previous.currentSpace?.id != current.currentSpace?.id ||
              previous.appMode != current.appMode ||
              previous.currentRole != current.currentRole,
          listener: (context, session) {
            _syncSession(session);
            _syncNotification(
              session: session,
              playerState: context.read<PlayerBloc>().state,
            );
            _syncPlaybackHealthTicker(
              session: session,
              camsState: context.read<CamsPlaybackBloc>().state,
              playerState: context.read<PlayerBloc>().state,
            );
          },
        ),
        BlocListener<CamsPlaybackBloc, CamsPlaybackState>(
          listenWhen: (previous, current) {
            final previousPlayback = previous.playbackState;
            final currentPlayback = current.playbackState;
            final previousQueueSignature = _queueSignature(previousPlayback);
            final currentQueueSignature = _queueSignature(currentPlayback);
            return previous.isStreaming != current.isStreaming ||
                previousPlayback?.hlsUrl != currentPlayback?.hlsUrl ||
                previousPlayback?.currentQueueItemId !=
                    currentPlayback?.currentQueueItemId ||
                previousQueueSignature != currentQueueSignature ||
                previousPlayback?.currentTrackName !=
                    currentPlayback?.currentTrackName ||
                previousPlayback?.isPaused != currentPlayback?.isPaused ||
                previousPlayback?.pausePositionSeconds !=
                    currentPlayback?.pausePositionSeconds ||
                previousPlayback?.seekOffsetSeconds !=
                    currentPlayback?.seekOffsetSeconds ||
                previousPlayback?.startedAtUtc !=
                    currentPlayback?.startedAtUtc ||
                previousPlayback?.pendingQueueItemId !=
                    currentPlayback?.pendingQueueItemId ||
                previousPlayback?.volumePercent !=
                    currentPlayback?.volumePercent ||
                previousPlayback?.isMuted != currentPlayback?.isMuted ||
                previous.status != current.status;
          },
          listener: (context, camsState) => _syncCamsState(camsState),
        ),
        BlocListener<PlayerBloc, PlayerState>(
          listenWhen: (previous, current) =>
              previous.hlsCompletionSequence != current.hlsCompletionSequence,
          listener: (context, playerState) {
            final session = context.read<SessionCubit>().state;
            final camsState = context.read<CamsPlaybackBloc>().state;
            if (!session.isPlaybackDevice ||
                !playerState.isSyncedCamsPlayback ||
                !camsState.isStreaming) {
              return;
            }
            _traceLog(
              'TRACK_ENDED_TRIGGER '
              'spaceId=${camsState.spaceId ?? '-'} '
              'queueItemId=${playerState.currentQueueItemId ?? '-'} '
              'trackId=${playerState.currentTrackId ?? playerState.currentTrack?.id ?? '-'} '
              'trackTitle=${playerState.currentTrack?.title ?? '-'} '
              'completionSequence=${playerState.hlsCompletionSequence}',
            );
            // Remember the completed track so we can ignore stale state
            // snapshots that still reference it.
            _trackEndedQueueItemId = playerState.currentQueueItemId;
            _trackEndedHlsUrl = playerState.hlsUrl;
            _trackEndedAtUtc = DateTime.now().toUtc();
            _lastAppliedRemotePlaybackSignature = null;
            _addCamsEvent(
              const CamsSendCommand(
                command: PlaybackCommandEnum.trackEnded,
              ),
            );
          },
        ),
        BlocListener<PlayerBloc, PlayerState>(
          listenWhen: (previous, current) => previous != current,
          listener: (context, playerState) {
            _syncNotification(
              session: context.read<SessionCubit>().state,
              playerState: playerState,
            );
            _syncPlaybackHealthTicker(
              session: context.read<SessionCubit>().state,
              camsState: context.read<CamsPlaybackBloc>().state,
              playerState: playerState,
            );
          },
        ),
      ],
      child: widget.child,
    );

    if (!kDebugMode || !sl.isRegistered<LocalStorageService>()) {
      return content;
    }

    return Stack(
      children: [
        content,
        Positioned(
          top: 16,
          right: 16,
          child: SafeArea(
            child: _buildDebugAuthButton(context),
          ),
        ),
      ],
    );
  }
}
