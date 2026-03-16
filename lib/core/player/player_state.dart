import 'package:equatable/equatable.dart';
import '../../features/space_control/domain/entities/track.dart';
import 'space_info.dart';

class PlayerState extends Equatable {
  final Track? currentTrack;
  final bool isPlaying;
  final int currentPosition; // seconds
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

  const PlayerState({
    this.currentTrack,
    this.isPlaying = false,
    this.currentPosition = 0,
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
  });

  /// Whether we have enough data to render the MiniPlayer.
  bool get hasTrack => currentTrack != null;

  /// True when the player is following CAMS/SignalR state for a remote stream.
  bool get isSyncedCamsPlayback =>
      isHlsMode && (hlsUrl?.isNotEmpty ?? false);

  /// True when audio is playing only on the current device.
  bool get isLocalPreview => hasTrack && !isSyncedCamsPlayback;

  /// Whether there is a next track in the queue.
  bool get hasNext => queue.isNotEmpty && currentIndex < queue.length - 1;

  /// Whether there is a previous track in the queue.
  bool get hasPrevious => queue.isNotEmpty && currentIndex > 0;

  double get progress =>
      (duration > 0) ? (currentPosition / duration).clamp(0.0, 1.0) : 0.0;

  PlayerState copyWith({
    Track? currentTrack,
    bool? isPlaying,
    int? currentPosition,
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
    bool clearTrack = false,
    bool clearPlaylistName = false,
    bool clearPlaylistId = false,
    bool clearHlsUrl = false,
  }) {
    return PlayerState(
      currentTrack: clearTrack ? null : (currentTrack ?? this.currentTrack),
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
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
    );
  }

  @override
  List<Object?> get props => [
        currentTrack,
        isPlaying,
        currentPosition,
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
      ];
}
