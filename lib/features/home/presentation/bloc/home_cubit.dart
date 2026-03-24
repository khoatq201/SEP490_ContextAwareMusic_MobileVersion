import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cams/domain/usecases/cancel_override.dart';
import '../../../cams/domain/usecases/get_space_state.dart';
import '../../../cams/domain/usecases/override_space.dart';
import '../../../moods/domain/usecases/get_moods.dart';
import '../../domain/repositories/home_repository.dart';
import 'home_state.dart';

/// Cubit for the Home Dashboard tab.
/// Loads sensor/category data and controls CAMS auto/manual override flow.
class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repository;
  final GetSpaceState _getSpaceState;
  final GetMoods _getMoods;
  final OverrideSpace _overrideSpace;
  final CancelOverride _cancelOverride;

  HomeCubit(
    this._repository, {
    required GetSpaceState getSpaceState,
    required GetMoods getMoods,
    required OverrideSpace overrideSpace,
    required CancelOverride cancelOverride,
  })  : _getSpaceState = getSpaceState,
        _getMoods = getMoods,
        _overrideSpace = overrideSpace,
        _cancelOverride = cancelOverride,
        super(const HomeState());

  Future<void> load() async {
    emit(state.copyWith(
      status: HomeStatus.loading,
      clearError: true,
    ));

    final sensorsResult = await _repository.getSensorData();
    final categoriesResult = await _repository.getCategories();
    final moodsResult = await _getMoods();

    sensorsResult.fold(
      (failure) => emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: failure.message,
      )),
      (sensors) {
        categoriesResult.fold(
          (failure) => emit(state.copyWith(
            status: HomeStatus.error,
            errorMessage: failure.message,
          )),
          (categories) {
            final moods = moodsResult.fold((_) => state.moods, (data) => data);
            emit(state.copyWith(
              status: HomeStatus.loaded,
              sensors: sensors,
              categories: categories,
              moods: moods,
            ));
          },
        );
      },
    );
  }

  Future<void> syncForSpace(String? spaceId) async {
    if (spaceId == null || spaceId.isEmpty) {
      emit(state.copyWith(
        clearActiveSpace: true,
        isManualOverride: false,
        isManualSelectionOpen: false,
        isApplyingOverride: false,
        isPendingTranscode: false,
        clearMood: true,
        clearPlaylist: true,
        clearModeMessage: true,
      ));
      return;
    }

    emit(state.copyWith(
      activeSpaceId: spaceId,
      clearModeMessage: true,
    ));

    await _ensureMoodsLoaded();
    await loadSpacePlaybackState(spaceId);
  }

  /// Fetch CAMS playback state for the given space to display mood and mode.
  Future<void> loadSpacePlaybackState(String spaceId) async {
    final result = await _getSpaceState(spaceId);
    result.fold(
      (_) {}, // Non-fatal - fallback UI still works
      (pbState) {
        emit(state.copyWith(
          activeSpaceId: spaceId,
          isManualOverride: pbState.isManualOverride,
          isManualSelectionOpen: false,
          currentMoodName: pbState.moodName,
          currentPlaylistName:
              pbState.currentTrackName ?? pbState.currentPlaylistName,
          isStreaming: pbState.isStreaming,
          isPendingTranscode: pbState.hasPendingPlayback,
          clearMood: pbState.moodName == null,
          clearPlaylist:
              (pbState.currentTrackName ?? pbState.currentPlaylistName) == null,
        ));
      },
    );
  }

  void openManualSelection() {
    final spaceId = state.activeSpaceId;
    if (spaceId == null || state.isApplyingOverride) return;
    emit(state.copyWith(
      isManualSelectionOpen: true,
      clearModeMessage: true,
    ));
  }

  void closeManualSelection() {
    if (state.isApplyingOverride || !state.isManualSelectionOpen) return;
    emit(state.copyWith(
      isManualSelectionOpen: false,
      clearModeMessage: true,
    ));
  }

  Future<void> selectAutoMode() async {
    final spaceId = state.activeSpaceId;
    if (spaceId == null || state.isApplyingOverride) return;

    if (state.autoModeEnabled) {
      return;
    }

    if (!state.isManualOverride) {
      emit(state.copyWith(
        isManualSelectionOpen: false,
        isPendingTranscode: false,
        clearModeMessage: true,
      ));
      return;
    }

    emit(state.copyWith(
      isApplyingOverride: true,
      clearModeMessage: true,
    ));

    final result = await _cancelOverride(spaceId);
    result.fold(
      (failure) => emit(state.copyWith(
        isApplyingOverride: false,
        modeMessage: 'Switch to auto failed: ${failure.message}',
      )),
      (_) async {
        emit(state.copyWith(
          isApplyingOverride: false,
          isManualSelectionOpen: false,
          isPendingTranscode: false,
        ));
        await loadSpacePlaybackState(spaceId);
      },
    );
  }

  Future<void> applyMoodOverride(String moodId) async {
    final spaceId = state.activeSpaceId;
    if (spaceId == null || state.isApplyingOverride) return;

    emit(state.copyWith(
      isApplyingOverride: true,
      clearModeMessage: true,
    ));

    final result = await _overrideSpace(
      spaceId: spaceId,
      moodId: moodId,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isApplyingOverride: false,
        modeMessage: 'Override failed: ${failure.message}',
      )),
      (_) async {
        emit(state.copyWith(
          isApplyingOverride: false,
          isManualOverride: true,
          isManualSelectionOpen: false,
          modeMessage: null,
        ));
        await loadSpacePlaybackState(spaceId);
      },
    );
  }

  Future<void> _ensureMoodsLoaded() async {
    if (state.moods.isNotEmpty) return;
    final result = await _getMoods();
    result.fold(
      (_) {},
      (moods) => emit(state.copyWith(moods: moods)),
    );
  }
}
