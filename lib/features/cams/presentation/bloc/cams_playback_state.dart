import 'package:equatable/equatable.dart';
import '../../../../core/enums/playback_command_enum.dart';
import '../../../moods/domain/entities/mood.dart';
import '../../domain/entities/space_playback_state.dart';
import '../../data/models/override_response_model.dart';

enum CamsStatus { initial, loading, active, error, idle }

class CamsPlaybackState extends Equatable {
  final CamsStatus status;

  /// Current space being monitored.
  final String? spaceId;

  /// Live playback state from CAMS API / SignalR.
  final SpacePlaybackState? playbackState;

  /// Available moods for override.
  final List<Mood> moods;

  /// Whether a mood/playlist override is in progress.
  final bool isOverriding;

  /// Latest override response (for pending transcode feedback).
  final OverrideResponse? lastOverrideResponse;

  /// Error message.
  final String? errorMessage;

  /// SignalR connection status.
  final bool isHubConnected;

  /// Last playback command received from SignalR.
  final PlaybackCommandEnum? lastPlaybackCommand;
  final double? lastSeekPositionSeconds;
  final String? lastTargetTrackId;
  final int commandSequence;

  const CamsPlaybackState({
    this.status = CamsStatus.initial,
    this.spaceId,
    this.playbackState,
    this.moods = const [],
    this.isOverriding = false,
    this.lastOverrideResponse,
    this.errorMessage,
    this.isHubConnected = false,
    this.lastPlaybackCommand,
    this.lastSeekPositionSeconds,
    this.lastTargetTrackId,
    this.commandSequence = 0,
  });

  /// Whether any playlist is currently streaming.
  bool get isStreaming => playbackState?.isStreaming ?? false;

  /// Whether override is currently active.
  bool get hasActiveOverride => playbackState?.hasActiveOverride ?? false;

  /// Current HLS URL (from playback state).
  String? get hlsUrl => playbackState?.hlsUrl;

  /// Current playlist name.
  String? get currentPlaylistName => playbackState?.currentPlaylistName;

  /// Current mood name.
  String? get currentMoodName => playbackState?.moodName;

  CamsPlaybackState copyWith({
    CamsStatus? status,
    String? spaceId,
    SpacePlaybackState? playbackState,
    List<Mood>? moods,
    bool? isOverriding,
    OverrideResponse? lastOverrideResponse,
    String? errorMessage,
    bool? isHubConnected,
    PlaybackCommandEnum? lastPlaybackCommand,
    double? lastSeekPositionSeconds,
    String? lastTargetTrackId,
    int? commandSequence,
    bool clearError = false,
    bool clearOverrideResponse = false,
    bool clearLastCommand = false,
  }) {
    return CamsPlaybackState(
      status: status ?? this.status,
      spaceId: spaceId ?? this.spaceId,
      playbackState: playbackState ?? this.playbackState,
      moods: moods ?? this.moods,
      isOverriding: isOverriding ?? this.isOverriding,
      lastOverrideResponse: clearOverrideResponse
          ? null
          : (lastOverrideResponse ?? this.lastOverrideResponse),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isHubConnected: isHubConnected ?? this.isHubConnected,
      lastPlaybackCommand: clearLastCommand
          ? null
          : (lastPlaybackCommand ?? this.lastPlaybackCommand),
      lastSeekPositionSeconds: clearLastCommand
          ? null
          : (lastSeekPositionSeconds ?? this.lastSeekPositionSeconds),
      lastTargetTrackId: clearLastCommand
          ? null
          : (lastTargetTrackId ?? this.lastTargetTrackId),
      commandSequence: commandSequence ?? this.commandSequence,
    );
  }

  @override
  List<Object?> get props => [
        status,
        spaceId,
        playbackState,
        moods,
        isOverriding,
        lastOverrideResponse,
        errorMessage,
        isHubConnected,
        lastPlaybackCommand,
        lastSeekPositionSeconds,
        lastTargetTrackId,
        commandSequence,
      ];
}
