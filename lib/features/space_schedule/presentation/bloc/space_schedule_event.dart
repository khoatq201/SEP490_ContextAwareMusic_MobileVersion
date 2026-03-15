import 'package:equatable/equatable.dart';

import '../../domain/entities/schedule_source.dart';
import '../../domain/entities/schedule_slot.dart';

abstract class SpaceScheduleEvent extends Equatable {
  const SpaceScheduleEvent();

  @override
  List<Object?> get props => [];
}

class SpaceScheduleStarted extends SpaceScheduleEvent {
  final String spaceId;
  final String storeId;
  final String spaceName;

  const SpaceScheduleStarted({
    required this.spaceId,
    required this.storeId,
    required this.spaceName,
  });

  @override
  List<Object?> get props => [spaceId, storeId, spaceName];
}

class SpaceScheduleCreateNewRequested extends SpaceScheduleEvent {
  const SpaceScheduleCreateNewRequested();
}

class SpaceScheduleSourcePickerRequested extends SpaceScheduleEvent {
  final ScheduleSourceType initialTab;

  const SpaceScheduleSourcePickerRequested({
    this.initialTab = ScheduleSourceType.library,
  });

  @override
  List<Object?> get props => [initialTab];
}

class SpaceScheduleSourceTabChanged extends SpaceScheduleEvent {
  final ScheduleSourceType sourceType;

  const SpaceScheduleSourceTabChanged(this.sourceType);

  @override
  List<Object?> get props => [sourceType];
}

class SpaceScheduleSourceSelected extends SpaceScheduleEvent {
  final ScheduleSource source;

  const SpaceScheduleSourceSelected(this.source);

  @override
  List<Object?> get props => [source];
}

class SpaceScheduleDaySelected extends SpaceScheduleEvent {
  final int day;

  const SpaceScheduleDaySelected(this.day);

  @override
  List<Object?> get props => [day];
}

class SpaceScheduleSlotSaved extends SpaceScheduleEvent {
  final ScheduleSlot slot;

  const SpaceScheduleSlotSaved(this.slot);

  @override
  List<Object?> get props => [slot];
}

class SpaceScheduleSlotDeleted extends SpaceScheduleEvent {
  final String slotId;

  const SpaceScheduleSlotDeleted(this.slotId);

  @override
  List<Object?> get props => [slotId];
}

class SpaceScheduleSavedToLibrary extends SpaceScheduleEvent {
  final String title;
  final String? subtitle;

  const SpaceScheduleSavedToLibrary({
    required this.title,
    this.subtitle,
  });

  @override
  List<Object?> get props => [title, subtitle];
}

class SpaceScheduleEditorReopened extends SpaceScheduleEvent {
  const SpaceScheduleEditorReopened();
}

class SpaceScheduleFeedbackCleared extends SpaceScheduleEvent {
  const SpaceScheduleFeedbackCleared();
}
