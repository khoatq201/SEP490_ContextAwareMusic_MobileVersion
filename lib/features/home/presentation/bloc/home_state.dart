import 'package:equatable/equatable.dart';

import '../../../moods/domain/entities/mood.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/sensor_entity.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final List<SensorEntity> sensors;
  final List<CategoryEntity> categories;
  final String? errorMessage;

  /// Active space currently controlled on Home.
  final String? activeSpaceId;

  /// Whether CAMS currently has active manual override on the space.
  final bool isManualOverride;

  /// Local UI mode while user turned Manual on but has not selected mood yet.
  final bool isManualSelectionOpen;

  /// In-flight state for override/cancel requests.
  final bool isApplyingOverride;

  /// Mood list from GET /api/moods.
  final List<Mood> moods;

  /// Current mood name from CAMS space state (e.g. "Chill", "Energetic").
  final String? currentMoodName;

  /// Current playlist name from CAMS space state.
  final String? currentPlaylistName;

  /// Whether the space is currently streaming.
  final bool isStreaming;

  /// True when override returned accepted/pending transcode.
  final bool isPendingTranscode;

  /// Inline message for mode changes (pending transcode, action failures, etc.).
  final String? modeMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.sensors = const [],
    this.categories = const [],
    this.errorMessage,
    this.activeSpaceId,
    this.isManualOverride = false,
    this.isManualSelectionOpen = false,
    this.isApplyingOverride = false,
    this.moods = const [],
    this.currentMoodName,
    this.currentPlaylistName,
    this.isStreaming = false,
    this.isPendingTranscode = false,
    this.modeMessage,
  });

  bool get isManualMode => isManualOverride || isManualSelectionOpen;
  bool get autoModeEnabled => !isManualMode;
  bool get showMoodPicker => isManualSelectionOpen;

  HomeState copyWith({
    HomeStatus? status,
    List<SensorEntity>? sensors,
    List<CategoryEntity>? categories,
    String? errorMessage,
    String? activeSpaceId,
    bool? isManualOverride,
    bool? isManualSelectionOpen,
    bool? isApplyingOverride,
    List<Mood>? moods,
    String? currentMoodName,
    String? currentPlaylistName,
    bool? isStreaming,
    bool? isPendingTranscode,
    String? modeMessage,
    bool clearError = false,
    bool clearMood = false,
    bool clearPlaylist = false,
    bool clearModeMessage = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      sensors: sensors ?? this.sensors,
      categories: categories ?? this.categories,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeSpaceId: activeSpaceId ?? this.activeSpaceId,
      isManualOverride: isManualOverride ?? this.isManualOverride,
      isManualSelectionOpen:
          isManualSelectionOpen ?? this.isManualSelectionOpen,
      isApplyingOverride: isApplyingOverride ?? this.isApplyingOverride,
      moods: moods ?? this.moods,
      currentMoodName:
          clearMood ? null : (currentMoodName ?? this.currentMoodName),
      currentPlaylistName: clearPlaylist
          ? null
          : (currentPlaylistName ?? this.currentPlaylistName),
      isStreaming: isStreaming ?? this.isStreaming,
      isPendingTranscode: isPendingTranscode ?? this.isPendingTranscode,
      modeMessage: clearModeMessage ? null : (modeMessage ?? this.modeMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        sensors,
        categories,
        errorMessage,
        activeSpaceId,
        isManualOverride,
        isManualSelectionOpen,
        isApplyingOverride,
        moods,
        currentMoodName,
        currentPlaylistName,
        isStreaming,
        isPendingTranscode,
        modeMessage,
      ];
}
