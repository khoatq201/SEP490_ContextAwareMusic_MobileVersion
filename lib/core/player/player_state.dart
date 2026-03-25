import 'package:equatable/equatable.dart';
import '../../features/space_control/domain/entities/track.dart';
import 'space_info.dart';

class PlayerState extends Equatable {
  final Track? currentTrack;
  final bool isPlaying;
  final int currentPosition; // seconds
  final double currentPositionPrecise; // seconds
  final int duration; // seconds

  /// The active space context (needed to dispatch commands back to MusicControlBloc).
  final String? activeStoreId;
  final String? activeSpaceId;

  /// Display name of the active space (e.g. "Main Floor").
  final String? activeSpaceName;

  /// All spaces belonging to the active store — used for the space-swap sheet
  /// in the Now Playing tab.
  final List<SpaceInfo> availableSpaces;

  /// Queue of tracks for playlist playback.
  final List<Track> queue;

  /// Current index within [queue]. -1 means no queue active.
  final int currentIndex;

  /// Name of the playlist/album currently playing from.
  final String? playlistName;

  /// Backend playlist identifier when playback is tied to a CMS playlist.
  final String? playlistId;

  /// Current HLS URL being streamed (from CAMS).
  final String? hlsUrl;

  /// Whether the player is streaming via HLS (CAMS mode).
  final bool isHlsMode;

  /// Queue-first remote identity fields.
  final String? currentQueueItemId;
  final String? currentTrackId;

  /// Increments when the local HLS player reports natural completion.
  final int hlsCompletionSequence;

  const PlayerState({
    this.currentTrack,
    this.isPlaying = false,
    this.currentPosition = 0,
    this.currentPositionPrecise = 0,
    this.duration = 0,
    this.activeStoreId,
    this.activeSpaceId,
    this.activeSpaceName,
    this.availableSpaces = const [],
    this.queue = const [],
    this.currentIndex = -1,
    this.playlistName,
    this.playlistId,
    this.hlsUrl,
    this.isHlsMode = false,
    this.currentQueueItemId,
    this.currentTrackId,
    this.hlsCompletionSequence = 0,
  });

  /// Whether we have enough data to render the MiniPlayer.
  bool get hasTrack => currentTrack != null;

  /// True when the player is following CAMS/SignalR state for a remote stream.
  bool get isSyncedCamsPlayback => isHlsMode && (hlsUrl?.isNotEmpty ?? false);

  /// True when audio is playing only on the current device.
  bool get isLocalPreview => hasTrack && !isSyncedCamsPlayback;

  /// Whether there is a next track in the queue.
  bool get hasNext => queue.isNotEmpty && currentIndex < queue.length - 1;

  /// Whether there is a previous track in the queue.
  bool get hasPrevious => queue.isNotEmpty && currentIndex > 0;

  int get totalQueueDuration {
    if (queue.isEmpty) return 0;

    final lastIndex = queue.length - 1;
    final lastTrackDuration = queue[lastIndex].duration ?? 0;
    return offsetForIndex(lastIndex) + lastTrackDuration;
  }

  int get normalizedPlaylistPosition {
    return normalizedPlaylistPositionPrecise.floor();
  }

  double get normalizedPlaylistPositionPrecise {
    if (!isSyncedCamsPlayback) {
      if (duration > 0) {
        return currentPositionPrecise
            .clamp(0.0, duration.toDouble())
            .toDouble();
      }
      return currentPositionPrecise < 0 ? 0 : currentPositionPrecise;
    }

    final queueDuration = totalQueueDuration.toDouble();
    if (queueDuration <= 0) {
      return currentPositionPrecise < 0 ? 0 : currentPositionPrecise;
    }

    final normalizedPosition = currentPositionPrecise % queueDuration;
    return normalizedPosition < 0
        ? normalizedPosition + queueDuration
        : normalizedPosition;
  }

  int offsetForIndex(int index) {
    if (index < 0 || index >= queue.length) return 0;

    final explicitOffset = queue[index].seekOffsetSeconds;
    if (explicitOffset != null) return explicitOffset;

    var cumulativeOffset = 0;
    for (var offsetIndex = 0; offsetIndex < index; offsetIndex++) {
      cumulativeOffset += queue[offsetIndex].duration ?? 0;
    }
    return cumulativeOffset;
  }

  int get currentTrackStartOffset {
    if (!isSyncedCamsPlayback ||
        queue.isEmpty ||
        currentIndex < 0 ||
        currentIndex >= queue.length) {
      return 0;
    }

    return offsetForIndex(currentIndex);
  }

  int get displayPosition {
    return displayPositionPrecise.floor();
  }

  double get displayPositionPrecise {
    if (!isSyncedCamsPlayback) {
      return normalizedPlaylistPositionPrecise;
    }

    final relativePosition =
        normalizedPlaylistPositionPrecise - currentTrackStartOffset;
    if (duration <= 0) return relativePosition < 0 ? 0 : relativePosition;
    return relativePosition.clamp(0.0, duration.toDouble()).toDouble();
  }

  int get remainingDuration {
    if (duration <= 0) return 0;
    return (duration - displayPosition).clamp(0, duration).toInt();
  }

  double get progress => (duration > 0)
      ? (displayPositionPrecise / duration).clamp(0.0, 1.0)
      : 0.0;

  PlayerState copyWith({
    Track? currentTrack,
    bool? isPlaying,
    int? currentPosition,
    double? currentPositionPrecise,
    int? duration,
    String? activeStoreId,
    String? activeSpaceId,
    String? activeSpaceName,
    List<SpaceInfo>? availableSpaces,
    List<Track>? queue,
    int? currentIndex,
    String? playlistName,
    String? playlistId,
    String? hlsUrl,
    bool? isHlsMode,
    String? currentQueueItemId,
    String? currentTrackId,
    int? hlsCompletionSequence,
    bool clearTrack = false,
    bool clearPlaylistName = false,
    bool clearPlaylistId = false,
    bool clearHlsUrl = false,
    bool clearCurrentQueueItemId = false,
    bool clearCurrentTrackId = false,
  }) {
    final resolvedCurrentPosition = currentPosition ?? this.currentPosition;
    final resolvedCurrentPositionPrecise = currentPositionPrecise ??
        (currentPosition != null
            ? currentPosition.toDouble()
            : this.currentPositionPrecise);

    return PlayerState(
      currentTrack: clearTrack ? null : (currentTrack ?? this.currentTrack),
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: resolvedCurrentPosition,
      currentPositionPrecise: resolvedCurrentPositionPrecise,
      duration: duration ?? this.duration,
      activeStoreId: activeStoreId ?? this.activeStoreId,
      activeSpaceId: activeSpaceId ?? this.activeSpaceId,
      activeSpaceName: activeSpaceName ?? this.activeSpaceName,
      availableSpaces: availableSpaces ?? this.availableSpaces,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      playlistName:
          clearPlaylistName ? null : (playlistName ?? this.playlistName),
      playlistId: clearPlaylistId ? null : (playlistId ?? this.playlistId),
      hlsUrl: clearHlsUrl ? null : (hlsUrl ?? this.hlsUrl),
      isHlsMode: isHlsMode ?? this.isHlsMode,
      currentQueueItemId: clearCurrentQueueItemId
          ? null
          : (currentQueueItemId ?? this.currentQueueItemId),
      currentTrackId:
          clearCurrentTrackId ? null : (currentTrackId ?? this.currentTrackId),
      hlsCompletionSequence:
          hlsCompletionSequence ?? this.hlsCompletionSequence,
    );
  }

  @override
  List<Object?> get props => [
        currentTrack,
        isPlaying,
        currentPosition,
        currentPositionPrecise,
        duration,
        activeStoreId,
        activeSpaceId,
        activeSpaceName,
        availableSpaces,
        queue,
        currentIndex,
        playlistName,
        playlistId,
        hlsUrl,
        isHlsMode,
        currentQueueItemId,
        currentTrackId,
        hlsCompletionSequence,
      ];
}
