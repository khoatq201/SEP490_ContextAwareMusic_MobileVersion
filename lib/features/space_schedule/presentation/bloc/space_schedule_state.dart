import 'package:equatable/equatable.dart';

import '../../domain/entities/schedule_music_item.dart';
import '../../domain/entities/schedule_source.dart';
import '../../domain/entities/space_schedule.dart';

enum SpaceScheduleStatus { initial, loading, loaded, saving, error }

enum SpaceScheduleStage { welcome, sourcePicker, editor }

class SpaceScheduleState extends Equatable {
  final SpaceScheduleStatus status;
  final SpaceScheduleStage stage;
  final String? spaceId;
  final String? storeId;
  final String? spaceName;
  final int selectedDay;
  final SpaceSchedule? draftSchedule;
  final List<ScheduleSource> librarySources;
  final List<ScheduleTemplate> templateSources;
  final List<ScheduleMusicItem> musicCatalog;
  final ScheduleSourceType sourcePickerTab;
  final String? errorMessage;
  final String? feedbackMessage;

  const SpaceScheduleState({
    this.status = SpaceScheduleStatus.initial,
    this.stage = SpaceScheduleStage.welcome,
    this.spaceId,
    this.storeId,
    this.spaceName,
    this.selectedDay = 7,
    this.draftSchedule,
    this.librarySources = const [],
    this.templateSources = const [],
    this.musicCatalog = const [],
    this.sourcePickerTab = ScheduleSourceType.library,
    this.errorMessage,
    this.feedbackMessage,
  });

  SpaceScheduleState copyWith({
    SpaceScheduleStatus? status,
    SpaceScheduleStage? stage,
    String? spaceId,
    String? storeId,
    String? spaceName,
    int? selectedDay,
    SpaceSchedule? draftSchedule,
    List<ScheduleSource>? librarySources,
    List<ScheduleTemplate>? templateSources,
    List<ScheduleMusicItem>? musicCatalog,
    ScheduleSourceType? sourcePickerTab,
    String? errorMessage,
    String? feedbackMessage,
    bool clearErrorMessage = false,
    bool clearFeedbackMessage = false,
  }) {
    return SpaceScheduleState(
      status: status ?? this.status,
      stage: stage ?? this.stage,
      spaceId: spaceId ?? this.spaceId,
      storeId: storeId ?? this.storeId,
      spaceName: spaceName ?? this.spaceName,
      selectedDay: selectedDay ?? this.selectedDay,
      draftSchedule: draftSchedule ?? this.draftSchedule,
      librarySources: librarySources ?? this.librarySources,
      templateSources: templateSources ?? this.templateSources,
      musicCatalog: musicCatalog ?? this.musicCatalog,
      sourcePickerTab: sourcePickerTab ?? this.sourcePickerTab,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        stage,
        spaceId,
        storeId,
        spaceName,
        selectedDay,
        draftSchedule,
        librarySources,
        templateSources,
        musicCatalog,
        sourcePickerTab,
        errorMessage,
        feedbackMessage,
      ];
}
