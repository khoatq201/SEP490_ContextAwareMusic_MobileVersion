import 'package:equatable/equatable.dart';
import '../../../../core/enums/playback_command_enum.dart';
import '../../../config_governance/domain/entities/config_governance_enums.dart';
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

  /// Brand-level playback block, usually caused by wallet/quota business rules.
  final String? playbackBlockedMessage;

  /// Brand id associated with the block when the current playback snapshot has it.
  final String? playbackBlockedBrandId;

  /// Space/store mutation block, usually caused by strict sync governance.
  final String? playbackMutationBlockedMessage;

  /// SignalR connection status.
  final bool isHubConnected;

  /// Last playback command received from SignalR.
  final PlaybackCommandEnum? lastPlaybackCommand;
  final double? lastSeekPositionSeconds;
  final String? lastTargetQueueItemId;
  final String? lastTargetTrackId;
  final int commandSequence;
  final PlaybackCommandEnum? failedPlaybackCommand;
  final double? failedSeekPositionSeconds;
  final int playbackCommandFailureSequence;
  final int audioSettingsFailureSequence;
  final bool isPlaybackCommandInFlight;
  final PlaybackCommandEnum? inFlightPlaybackCommand;
  final String? pendingTrackPlaylistId;
  final String? pendingTrackId;

  const CamsPlaybackState({
    this.status = CamsStatus.initial,
    this.spaceId,
    this.playbackState,
    this.moods = const [],
    this.isOverriding = false,
    this.lastOverrideResponse,
    this.errorMessage,
    this.playbackBlockedMessage,
    this.playbackBlockedBrandId,
    this.playbackMutationBlockedMessage,
    this.isHubConnected = false,
    this.lastPlaybackCommand,
    this.lastSeekPositionSeconds,
    this.lastTargetQueueItemId,
    this.lastTargetTrackId,
    this.commandSequence = 0,
    this.failedPlaybackCommand,
    this.failedSeekPositionSeconds,
    this.playbackCommandFailureSequence = 0,
    this.audioSettingsFailureSequence = 0,
    this.isPlaybackCommandInFlight = false,
    this.inFlightPlaybackCommand,
    this.pendingTrackPlaylistId,
    this.pendingTrackId,
  });

  /// Whether any playlist is currently streaming.
  bool get isStreaming => playbackState?.isStreaming ?? false;

  /// Whether CAMS is preparing a pending queue item.
  bool get isPreparing => playbackState?.hasPendingPlayback ?? false;

  /// Whether override is currently active.
  ///
  /// Some backend snapshots mark manual override with `isManualOverride`
  /// before an override mode is available. The UI should still expose cancel.
  bool get hasActiveOverride => playbackState?.isManualOverride ?? false;

  /// Current HLS URL (from playback state).
  String? get hlsUrl => playbackState?.effectiveHlsUrl;

  /// Current track name (queue-first state).
  String? get currentTrackName => playbackState?.effectiveTrackName;

  /// Current playback label for UI (track -> playlist -> mood).
  String? get currentPlaybackName => playbackState?.currentDisplayName;

  /// Legacy UI getter kept for compatibility.
  String? get currentPlaylistName => currentPlaybackName;

  /// Current mood name.
  String? get currentMoodName => playbackState?.moodName;

  SpacePlaybackExplainability? get explainability =>
      playbackState?.explainability;

  bool get hasExplainability => explainability?.hasAnyData ?? false;

  StoreGovernanceMode? get governanceMode => playbackState?.governanceMode;

  bool get isStrictSyncGovernance =>
      governanceMode == StoreGovernanceMode.strictSync;

  bool get isBrandPlaybackBlocked =>
      playbackBlockedMessage != null && playbackBlockedMessage!.isNotEmpty;

  bool get isPlaybackMutationBlocked =>
      playbackMutationBlockedMessage != null &&
      playbackMutationBlockedMessage!.isNotEmpty;

  CamsPlaybackState copyWith({
    CamsStatus? status,
    String? spaceId,
    SpacePlaybackState? playbackState,
    List<Mood>? moods,
    bool? isOverriding,
    OverrideResponse? lastOverrideResponse,
    String? errorMessage,
    String? playbackBlockedMessage,
    String? playbackBlockedBrandId,
    String? playbackMutationBlockedMessage,
    bool? isHubConnected,
    PlaybackCommandEnum? lastPlaybackCommand,
    double? lastSeekPositionSeconds,
    String? lastTargetQueueItemId,
    String? lastTargetTrackId,
    int? commandSequence,
    PlaybackCommandEnum? failedPlaybackCommand,
    double? failedSeekPositionSeconds,
    int? playbackCommandFailureSequence,
    int? audioSettingsFailureSequence,
    bool? isPlaybackCommandInFlight,
    PlaybackCommandEnum? inFlightPlaybackCommand,
    String? pendingTrackPlaylistId,
    String? pendingTrackId,
    bool clearError = false,
    bool clearPlaybackBlock = false,
    bool clearPlaybackMutationBlock = false,
    bool clearPlaybackState = false,
    bool clearOverrideResponse = false,
    bool clearLastCommand = false,
    bool clearFailedPlaybackCommand = false,
    bool clearLastSeekPosition = false,
    bool clearLastTargetQueueItemId = false,
    bool clearLastTargetTrackId = false,
    bool clearInFlightPlaybackCommand = false,
    bool clearPendingTrackJump = false,
  }) {
    return CamsPlaybackState(
      status: status ?? this.status,
      spaceId: spaceId ?? this.spaceId,
      playbackState:
          clearPlaybackState ? null : (playbackState ?? this.playbackState),
      moods: moods ?? this.moods,
      isOverriding: isOverriding ?? this.isOverriding,
      lastOverrideResponse: clearOverrideResponse
          ? null
          : (lastOverrideResponse ?? this.lastOverrideResponse),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      playbackBlockedMessage: clearPlaybackBlock
          ? null
          : (playbackBlockedMessage ?? this.playbackBlockedMessage),
      playbackBlockedBrandId: clearPlaybackBlock
          ? null
          : (playbackBlockedBrandId ?? this.playbackBlockedBrandId),
      playbackMutationBlockedMessage: clearPlaybackMutationBlock
          ? null
          : (playbackMutationBlockedMessage ??
              this.playbackMutationBlockedMessage),
      isHubConnected: isHubConnected ?? this.isHubConnected,
      lastPlaybackCommand: clearLastCommand
          ? null
          : (lastPlaybackCommand ?? this.lastPlaybackCommand),
      lastSeekPositionSeconds: (clearLastCommand || clearLastSeekPosition)
          ? null
          : (lastSeekPositionSeconds ?? this.lastSeekPositionSeconds),
      lastTargetQueueItemId: (clearLastCommand || clearLastTargetQueueItemId)
          ? null
          : (lastTargetQueueItemId ?? this.lastTargetQueueItemId),
      lastTargetTrackId: (clearLastCommand || clearLastTargetTrackId)
          ? null
          : (lastTargetTrackId ?? this.lastTargetTrackId),
      commandSequence: commandSequence ?? this.commandSequence,
      failedPlaybackCommand: clearFailedPlaybackCommand
          ? null
          : (failedPlaybackCommand ?? this.failedPlaybackCommand),
      failedSeekPositionSeconds: clearFailedPlaybackCommand
          ? null
          : (failedSeekPositionSeconds ?? this.failedSeekPositionSeconds),
      playbackCommandFailureSequence:
          playbackCommandFailureSequence ?? this.playbackCommandFailureSequence,
      audioSettingsFailureSequence:
          audioSettingsFailureSequence ?? this.audioSettingsFailureSequence,
      isPlaybackCommandInFlight:
          isPlaybackCommandInFlight ?? this.isPlaybackCommandInFlight,
      inFlightPlaybackCommand: clearInFlightPlaybackCommand
          ? null
          : (inFlightPlaybackCommand ?? this.inFlightPlaybackCommand),
      pendingTrackPlaylistId: clearPendingTrackJump
          ? null
          : (pendingTrackPlaylistId ?? this.pendingTrackPlaylistId),
      pendingTrackId: clearPendingTrackJump
          ? null
          : (pendingTrackId ?? this.pendingTrackId),
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
        playbackBlockedMessage,
        playbackBlockedBrandId,
        playbackMutationBlockedMessage,
        isHubConnected,
        lastPlaybackCommand,
        lastSeekPositionSeconds,
        lastTargetQueueItemId,
        lastTargetTrackId,
        commandSequence,
        failedPlaybackCommand,
        failedSeekPositionSeconds,
        playbackCommandFailureSequence,
        audioSettingsFailureSequence,
        isPlaybackCommandInFlight,
        inFlightPlaybackCommand,
        pendingTrackPlaylistId,
        pendingTrackId,
      ];
}
