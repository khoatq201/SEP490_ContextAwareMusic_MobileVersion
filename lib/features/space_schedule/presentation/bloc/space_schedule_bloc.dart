import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/schedule_music_item.dart';
import '../../domain/entities/schedule_slot.dart';
import '../../domain/entities/space_schedule.dart';
import '../../domain/usecases/space_schedule_usecases.dart';
import 'space_schedule_event.dart';
import 'space_schedule_state.dart';

class SpaceScheduleBloc
    extends Bloc<SpaceScheduleEvent, SpaceScheduleState> {
  final GetSpaceScheduleBootstrap getSpaceScheduleBootstrap;
  final ApplyScheduleSource applyScheduleSource;
  final SaveSpaceSchedule saveSpaceSchedule;
  final SaveScheduleToLibrary saveScheduleToLibrary;
  final DeleteScheduleSlot deleteScheduleSlot;

  SpaceScheduleBloc({
    required this.getSpaceScheduleBootstrap,
    required this.applyScheduleSource,
    required this.saveSpaceSchedule,
    required this.saveScheduleToLibrary,
    required this.deleteScheduleSlot,
  }) : super(const SpaceScheduleState()) {
    on<SpaceScheduleStarted>(_onStarted);
    on<SpaceScheduleCreateNewRequested>(_onCreateNewRequested);
    on<SpaceScheduleSourcePickerRequested>(_onSourcePickerRequested);
    on<SpaceScheduleSourceTabChanged>(_onSourceTabChanged);
    on<SpaceScheduleSourceSelected>(_onSourceSelected);
    on<SpaceScheduleDaySelected>(_onDaySelected);
    on<SpaceScheduleSlotSaved>(_onSlotSaved);
    on<SpaceScheduleSlotDeleted>(_onSlotDeleted);
    on<SpaceScheduleSavedToLibrary>(_onSavedToLibrary);
    on<SpaceScheduleEditorReopened>(_onEditorReopened);
    on<SpaceScheduleFeedbackCleared>(_onFeedbackCleared);
  }

  Future<void> _onStarted(
    SpaceScheduleStarted event,
    Emitter<SpaceScheduleState> emit,
  ) async {
    emit(
      state.copyWith(
        status: SpaceScheduleStatus.loading,
        spaceId: event.spaceId,
        storeId: event.storeId,
        spaceName: event.spaceName,
        clearErrorMessage: true,
        clearFeedbackMessage: true,
      ),
    );

    final result = await getSpaceScheduleBootstrap(
      spaceId: event.spaceId,
      spaceName: event.spaceName,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SpaceScheduleStatus.error,
          errorMessage: failure.message,
          clearFeedbackMessage: true,
        ),
      ),
      (bootstrap) {
        emit(
          state.copyWith(
            status: SpaceScheduleStatus.loaded,
            stage: bootstrap.draftSchedule != null
                ? SpaceScheduleStage.editor
                : SpaceScheduleStage.welcome,
            draftSchedule: bootstrap.draftSchedule,
            librarySources: bootstrap.librarySources,
            templateSources: bootstrap.templateSources,
            musicCatalog: bootstrap.musicCatalog,
            selectedDay: _preferredInitialDay(bootstrap.draftSchedule),
            clearErrorMessage: true,
            clearFeedbackMessage: true,
          ),
        );
      },
    );
  }

  Future<void> _onCreateNewRequested(
    SpaceScheduleCreateNewRequested event,
    Emitter<SpaceScheduleState> emit,
  ) async {
    final spaceId = state.spaceId;
    final spaceName = state.spaceName;
    if (spaceId == null || spaceName == null) {
      emit(
        state.copyWith(
          status: SpaceScheduleStatus.error,
          errorMessage: 'Missing space context for schedule.',
        ),
      );
      return;
    }

    final schedule = SpaceSchedule(
      id: 'space-schedule-$spaceId',
      name: '$spaceName schedule',
      spaceId: spaceId,
      slots: const [],
      enabled: true,
      updatedAt: DateTime.now(),
    );

    emit(state.copyWith(status: SpaceScheduleStatus.saving));
    final result = await saveSpaceSchedule(schedule);
    _handleScheduleResult(
      result,
      emit,
      successStage: SpaceScheduleStage.editor,
      successMessage: 'Blank schedule created.',
    );
  }

  void _onSourcePickerRequested(
    SpaceScheduleSourcePickerRequested event,
    Emitter<SpaceScheduleState> emit,
  ) {
    emit(
      state.copyWith(
        stage: SpaceScheduleStage.sourcePicker,
        sourcePickerTab: event.initialTab,
        clearErrorMessage: true,
        clearFeedbackMessage: true,
      ),
    );
  }

  void _onSourceTabChanged(
    SpaceScheduleSourceTabChanged event,
    Emitter<SpaceScheduleState> emit,
  ) {
    emit(
      state.copyWith(
        sourcePickerTab: event.sourceType,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> _onSourceSelected(
    SpaceScheduleSourceSelected event,
    Emitter<SpaceScheduleState> emit,
  ) async {
    final spaceId = state.spaceId;
    final spaceName = state.spaceName;
    if (spaceId == null || spaceName == null) return;

    emit(state.copyWith(status: SpaceScheduleStatus.saving));
    final result = await applyScheduleSource(
      spaceId: spaceId,
      spaceName: spaceName,
      source: event.source,
    );
    _handleScheduleResult(
      result,
      emit,
      successStage: SpaceScheduleStage.editor,
      successMessage: '${event.source.title} loaded.',
    );
  }

  void _onDaySelected(
    SpaceScheduleDaySelected event,
    Emitter<SpaceScheduleState> emit,
  ) {
    emit(state.copyWith(selectedDay: event.day));
  }

  Future<void> _onSlotSaved(
    SpaceScheduleSlotSaved event,
    Emitter<SpaceScheduleState> emit,
  ) async {
    final schedule = state.draftSchedule;
    if (schedule == null) return;

    final validationMessage = _validateSlot(
      event.slot,
      state.musicCatalog,
      schedule.slots,
    );
    if (validationMessage != null) {
      emit(
        state.copyWith(
          status: SpaceScheduleStatus.loaded,
          errorMessage: validationMessage,
          clearFeedbackMessage: true,
        ),
      );
      return;
    }

    final updatedSlots = [...schedule.slots];
    final existingIndex =
        updatedSlots.indexWhere((slot) => slot.id == event.slot.id);
    if (existingIndex >= 0) {
      updatedSlots[existingIndex] = event.slot;
    } else {
      updatedSlots.add(event.slot);
    }
    updatedSlots.sort(_slotSortComparator);

    emit(state.copyWith(status: SpaceScheduleStatus.saving));
    final result = await saveSpaceSchedule(
      schedule.copyWith(
        slots: updatedSlots,
        updatedAt: DateTime.now(),
      ),
    );
    _handleScheduleResult(
      result,
      emit,
      successStage: SpaceScheduleStage.editor,
      successMessage: existingIndex >= 0
          ? 'Schedule slot updated.'
          : 'Schedule slot added.',
      selectedDay: event.slot.daysOfWeek.isNotEmpty
          ? _uiDayFromDomainDay(event.slot.daysOfWeek.first)
          : state.selectedDay,
    );
  }

  Future<void> _onSlotDeleted(
    SpaceScheduleSlotDeleted event,
    Emitter<SpaceScheduleState> emit,
  ) async {
    final spaceId = state.spaceId;
    if (spaceId == null) return;

    emit(state.copyWith(status: SpaceScheduleStatus.saving));
    final result = await deleteScheduleSlot(
      spaceId: spaceId,
      slotId: event.slotId,
    );
    _handleScheduleResult(
      result,
      emit,
      successStage: SpaceScheduleStage.editor,
      successMessage: 'Schedule slot removed.',
    );
  }

  Future<void> _onSavedToLibrary(
    SpaceScheduleSavedToLibrary event,
    Emitter<SpaceScheduleState> emit,
  ) async {
    final schedule = state.draftSchedule;
    if (schedule == null) return;

    emit(
      state.copyWith(
        status: SpaceScheduleStatus.saving,
        clearErrorMessage: true,
        clearFeedbackMessage: true,
      ),
    );

    final result = await saveScheduleToLibrary(
      schedule: schedule,
      title: event.title.trim(),
      subtitle: event.subtitle?.trim(),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SpaceScheduleStatus.loaded,
          errorMessage: failure.message,
        ),
      ),
      (source) => emit(
        state.copyWith(
          status: SpaceScheduleStatus.loaded,
          librarySources: [source, ...state.librarySources],
          feedbackMessage: 'Saved to library.',
          clearErrorMessage: true,
        ),
      ),
    );
  }

  void _onEditorReopened(
    SpaceScheduleEditorReopened event,
    Emitter<SpaceScheduleState> emit,
  ) {
    emit(
      state.copyWith(
        stage: SpaceScheduleStage.editor,
        clearErrorMessage: true,
        clearFeedbackMessage: true,
      ),
    );
  }

  void _onFeedbackCleared(
    SpaceScheduleFeedbackCleared event,
    Emitter<SpaceScheduleState> emit,
  ) {
    emit(
      state.copyWith(
        clearErrorMessage: true,
        clearFeedbackMessage: true,
      ),
    );
  }

  void _handleScheduleResult(
    Either<Failure, SpaceSchedule> result,
    Emitter<SpaceScheduleState> emit, {
    required SpaceScheduleStage successStage,
    required String successMessage,
    int? selectedDay,
  }) {
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SpaceScheduleStatus.loaded,
          errorMessage: failure.message,
          clearFeedbackMessage: true,
        ),
      ),
      (schedule) => emit(
        state.copyWith(
          status: SpaceScheduleStatus.loaded,
          stage: successStage,
          draftSchedule: schedule,
          selectedDay: selectedDay ?? _preferredInitialDay(schedule),
          feedbackMessage: successMessage,
          clearErrorMessage: true,
        ),
      ),
    );
  }

  int _preferredInitialDay(SpaceSchedule? schedule) {
    if (schedule == null) {
      return _uiDayFromDomainDay(_todayDomainDay());
    }
    final slot = schedule.slots.isNotEmpty ? schedule.slots.first : null;
    if (slot == null || slot.daysOfWeek.isEmpty) {
      return _uiDayFromDomainDay(_todayDomainDay());
    }
    return _uiDayFromDomainDay(slot.daysOfWeek.first);
  }

  String? _validateSlot(
    ScheduleSlot slot,
    List<ScheduleMusicItem> catalog,
    List<ScheduleSlot> existingSlots,
  ) {
    final hasMusic = catalog.any((item) => item.id == slot.musicId);
    if (!hasMusic) {
      return 'Please select music for this schedule slot.';
    }

    final start = _minutesOfDay(slot.startTime);
    final end = _minutesOfDay(slot.endTime);
    if (start == null || end == null) {
      return 'Please choose a valid start and end time.';
    }
    if (end <= start) {
      return 'End time must be later than start time.';
    }

    for (final other in existingSlots) {
      if (other.id == slot.id) continue;
      if (!_sharesAnyDay(slot.daysOfWeek, other.daysOfWeek)) continue;

      final otherStart = _minutesOfDay(other.startTime);
      final otherEnd = _minutesOfDay(other.endTime);
      if (otherStart == null || otherEnd == null) continue;
      if (max(start, otherStart) < min(end, otherEnd)) {
        return 'This time overlaps another schedule slot.';
      }
    }

    return null;
  }

  bool _sharesAnyDay(List<int> a, List<int> b) {
    for (final day in a) {
      if (b.contains(day)) return true;
    }
    return false;
  }

  int _slotSortComparator(ScheduleSlot a, ScheduleSlot b) {
    final aDay = a.daysOfWeek.isEmpty ? 8 : a.daysOfWeek.first;
    final bDay = b.daysOfWeek.isEmpty ? 8 : b.daysOfWeek.first;
    final dayCompare = aDay.compareTo(bDay);
    if (dayCompare != 0) return dayCompare;

    final startA = _minutesOfDay(a.startTime) ?? 0;
    final startB = _minutesOfDay(b.startTime) ?? 0;
    return startA.compareTo(startB);
  }

  int? _minutesOfDay(String value) {
    final segments = value.split(':');
    if (segments.length != 2) return null;
    final hour = int.tryParse(segments[0]);
    final minute = int.tryParse(segments[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  int _todayDomainDay() {
    final weekday = DateTime.now().weekday;
    return weekday == DateTime.sunday ? 7 : weekday;
  }

  int _uiDayFromDomainDay(int domainDay) {
    return domainDay == 7 ? 0 : domainDay;
  }
}
