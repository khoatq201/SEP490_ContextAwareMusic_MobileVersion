import 'package:equatable/equatable.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/entities/sensor_entity.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final List<SensorEntity> sensors;
  final List<CategoryEntity> categories;
  final String? errorMessage;
  final bool autoModeEnabled;

  /// Current mood name from CAMS space state (e.g. "Chill", "Energetic").
  final String? currentMoodName;

  /// Current playlist name from CAMS space state.
  final String? currentPlaylistName;

  /// Whether the space is currently streaming.
  final bool isStreaming;

  const HomeState({
    this.status = HomeStatus.initial,
    this.sensors = const [],
    this.categories = const [],
    this.errorMessage,
    this.autoModeEnabled = true,
    this.currentMoodName,
    this.currentPlaylistName,
    this.isStreaming = false,
  });

  HomeState copyWith({
    HomeStatus? status,
    List<SensorEntity>? sensors,
    List<CategoryEntity>? categories,
    String? errorMessage,
    bool? autoModeEnabled,
    String? currentMoodName,
    String? currentPlaylistName,
    bool? isStreaming,
    bool clearMood = false,
    bool clearPlaylist = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      sensors: sensors ?? this.sensors,
      categories: categories ?? this.categories,
      errorMessage: errorMessage ?? this.errorMessage,
      autoModeEnabled: autoModeEnabled ?? this.autoModeEnabled,
      currentMoodName:
          clearMood ? null : (currentMoodName ?? this.currentMoodName),
      currentPlaylistName: clearPlaylist
          ? null
          : (currentPlaylistName ?? this.currentPlaylistName),
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  @override
  List<Object?> get props => [
        status,
        sensors,
        categories,
        errorMessage,
        autoModeEnabled,
        currentMoodName,
        currentPlaylistName,
        isStreaming,
      ];
}
