import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../cams/domain/entities/space_playback_state.dart';
import '../../../cams/domain/usecases/cancel_override.dart';
import '../../../cams/domain/usecases/get_space_state.dart';
import '../../../cams/domain/usecases/override_space.dart';
import '../../../moods/domain/entities/mood.dart';
import '../../../moods/domain/usecases/get_moods.dart';
import '../../domain/repositories/home_repository.dart';
import 'home_state.dart';

/// Cubit for the Home Dashboard tab.
/// Loads sensor/category data and controls CAMS auto/manual override flow.
class HomeCubit extends Cubit<HomeState> {
  static const List<Duration> _autoRefreshRetrySchedule = [
    Duration.zero,
    Duration(milliseconds: 250),
    Duration(milliseconds: 600),
  ];

  final HomeRepository _repository;
  final GetSpaceState _getSpaceState;
  final GetMoods _getMoods;
  final OverrideSpace _overrideSpace;
  final CancelOverride _cancelOverride;
  bool _usePlaybackDeviceScope = false;

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

  Future<void> load({
    bool includeCatalog = true,
    bool loadMoods = true,
    String? storeId,
    String? spaceId,
  }) async {
    emit(state.copyWith(
      status: HomeStatus.loading,
      clearError: true,
    ));

    final sensorsResult = await _repository.getSensorData(
      storeId: storeId,
      spaceId: spaceId,
    );
    if (!includeCatalog) {
      emit(state.copyWith(
        status: HomeStatus.loaded,
        sensors: sensorsResult.getOrElse(() => const []),
        categories: const [],
        moods: const [],
      ));
      return;
    }

    final categoriesResult = await _repository.getCategories();
    final moodsResult = loadMoods ? await _getMoods() : null;

    final sensors = sensorsResult.getOrElse(() => const []);
    categoriesResult.fold(
      (failure) => emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: ErrorMapper.displayMessageForFailure(failure),
      )),
      (categories) {
        final moods = loadMoods
            ? moodsResult!.fold((_) => state.moods, (data) => data)
            : const <Mood>[];
        emit(state.copyWith(
          status: HomeStatus.loaded,
          sensors: sensors,
          categories: categories,
          moods: moods,
        ));
      },
    );
  }

  Future<void> syncForSpace(
    String? spaceId, {
    String? storeId,
    bool loadMoods = true,
    bool usePlaybackDeviceScope = false,
  }) async {
    _usePlaybackDeviceScope = usePlaybackDeviceScope;
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
        clearExplainability: true,
        sensors: const [],
      ));
      return;
    }

    emit(state.copyWith(
      activeSpaceId: spaceId,
      clearModeMessage: true,
    ));

    if (loadMoods) {
      await _ensureMoodsLoaded();
    }
    await _refreshSensors(storeId: storeId, spaceId: spaceId);
    await loadSpacePlaybackState(
      spaceId,
      usePlaybackDeviceScope: usePlaybackDeviceScope,
    );
  }

  /// Fetch CAMS playback state for the given space to display mood and mode.
  Future<void> loadSpacePlaybackState(
    String spaceId, {
    bool? usePlaybackDeviceScope,
  }) async {
    final scopedToPlaybackDevice =
        usePlaybackDeviceScope ?? _usePlaybackDeviceScope;
    final result = await _getSpaceState(
      spaceId,
      usePlaybackDeviceScope: scopedToPlaybackDevice,
    );
    result.fold(
      (_) {}, // Non-fatal - fallback UI still works
      (pbState) => _applyPlaybackState(
        pbState,
        closeManualSelection: true,
      ),
    );
  }

  void syncFromRuntimePlaybackState(SpacePlaybackState playbackState) {
    final activeSpaceId = state.activeSpaceId;
    if (activeSpaceId == null || activeSpaceId != playbackState.spaceId) {
      return;
    }

    _applyPlaybackState(
      playbackState,
      closeManualSelection: false,
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

  Future<void> activateManualMode() async {
    final spaceId = state.activeSpaceId;
    if (spaceId == null || state.isApplyingOverride) return;

    if (state.isManualOverride && !state.isManualSelectionOpen) {
      return;
    }

    emit(state.copyWith(
      isApplyingOverride: true,
      isManualSelectionOpen: false,
      clearModeMessage: true,
    ));

    final result = await _overrideSpace(
      spaceId: spaceId,
      isClearManagerSelectedQueues: false,
      isCutOver: false,
      reason: 'Home manual mode request',
      usePlaybackDeviceScope: _usePlaybackDeviceScope,
    );

    await result.fold<Future<void>>(
      (failure) async => emit(state.copyWith(
        isApplyingOverride: false,
        modeMessage:
            'Switch to manual failed: ${ErrorMapper.displayMessageForFailure(failure)}',
      )),
      (_) async {
        emit(state.copyWith(
          isApplyingOverride: false,
          isManualOverride: true,
          isManualSelectionOpen: false,
          isPendingTranscode: false,
          modeMessage: null,
        ));
        await loadSpacePlaybackState(spaceId);
      },
    );
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
      await _refreshAutoPlaybackState(spaceId);
      return;
    }

    emit(state.copyWith(
      isApplyingOverride: true,
      clearModeMessage: true,
    ));

    final result = await _cancelOverride(spaceId);
    await result.fold<Future<void>>(
      (failure) async => emit(state.copyWith(
        isApplyingOverride: false,
        modeMessage:
            'Switch to auto failed: ${ErrorMapper.displayMessageForFailure(failure)}',
      )),
      (_) async {
        emit(state.copyWith(
          isApplyingOverride: false,
          isManualSelectionOpen: false,
          isPendingTranscode: false,
        ));
        await _refreshAutoPlaybackState(spaceId);
      },
    );
  }

  Future<void> applyMoodOverride(
    String moodId, {
    required int manualOverrideTtlSeconds,
    required bool isCutOver,
  }) async {
    final spaceId = state.activeSpaceId;
    if (spaceId == null || state.isApplyingOverride) return;

    emit(state.copyWith(
      isApplyingOverride: true,
      clearModeMessage: true,
    ));

    final result = await _overrideSpace(
      spaceId: spaceId,
      moodId: moodId,
      isCutOver: isCutOver,
      manualOverrideTtlSeconds: manualOverrideTtlSeconds,
      usePlaybackDeviceScope: _usePlaybackDeviceScope,
    );

    await result.fold<Future<void>>(
      (failure) async => emit(state.copyWith(
        isApplyingOverride: false,
        modeMessage:
            'Override failed: ${ErrorMapper.displayMessageForFailure(failure)}',
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

  Future<void> _refreshSensors({
    String? storeId,
    String? spaceId,
  }) async {
    final result = await _repository.getSensorData(
      storeId: storeId,
      spaceId: spaceId,
    );
    result.fold(
      (_) {},
      (sensors) => emit(state.copyWith(sensors: sensors)),
    );
  }

  Future<void> _refreshAutoPlaybackState(String spaceId) async {
    for (var attempt = 0;
        attempt < _autoRefreshRetrySchedule.length;
        attempt++) {
      final delay = _autoRefreshRetrySchedule[attempt];
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }

      await loadSpacePlaybackState(spaceId);
      if (_hasStableAutoExplainability()) {
        return;
      }
    }
  }

  bool _hasStableAutoExplainability() {
    if (state.isManualOverride) {
      return false;
    }

    final moodName = state.currentMoodName?.trim();
    if (moodName != null && moodName.isNotEmpty) {
      return true;
    }

    return state.explainability?.hasAnyData == true;
  }

  void _applyPlaybackState(
    SpacePlaybackState playbackState, {
    required bool closeManualSelection,
  }) {
    final resolvedPlaybackName = playbackState.currentDisplayName;
    final resolvedMoodName = _resolveMoodName(playbackState);
    final resolvedExplainability =
        _resolveExplainability(playbackState, resolvedMoodName);

    emit(state.copyWith(
      activeSpaceId: playbackState.spaceId,
      isManualOverride: playbackState.isManualOverride,
      isManualSelectionOpen:
          closeManualSelection ? false : state.isManualSelectionOpen,
      currentMoodName: resolvedMoodName,
      currentPlaybackName: resolvedPlaybackName,
      isStreaming: playbackState.isStreaming,
      isPendingTranscode: playbackState.hasPendingPlayback,
      explainability: resolvedExplainability,
      clearMood: resolvedMoodName == null,
      clearPlaylist: resolvedPlaybackName == null,
      clearExplainability: resolvedExplainability == null,
    ));
  }

  String? _resolveMoodName(SpacePlaybackState playbackState) {
    final primaryMood = playbackState.moodName?.trim();
    if (primaryMood?.isNotEmpty == true) {
      return primaryMood;
    }

    final explainabilityMood = playbackState.explainability?.moodName?.trim();
    if (explainabilityMood?.isNotEmpty == true) {
      return explainabilityMood;
    }

    return null;
  }

  SpacePlaybackExplainability? _resolveExplainability(
    SpacePlaybackState playbackState,
    String? resolvedMoodName,
  ) {
    final incoming = _ensureExplainabilityMood(
      playbackState.explainability,
      resolvedMoodName,
    );
    final current = _ensureExplainabilityMood(
      state.explainability,
      state.currentMoodName,
    );

    final incomingMood = resolvedMoodName?.trim().toLowerCase();
    final currentMood =
        (current?.moodName ?? state.currentMoodName)?.trim().toLowerCase();
    final moodMatches = incomingMood != null &&
        incomingMood.isNotEmpty &&
        currentMood != null &&
        currentMood.isNotEmpty &&
        incomingMood == currentMood;

    if (incoming?.hasAnyData == true) {
      if (current?.hasAnyData == true && moodMatches) {
        return _mergeExplainability(incoming!, current);
      }
      return incoming;
    }

    if (current?.hasAnyData == true && moodMatches) {
      return current;
    }

    if (resolvedMoodName == null) {
      return null;
    }
    return SpacePlaybackExplainability(moodName: resolvedMoodName);
  }

  SpacePlaybackExplainability? _ensureExplainabilityMood(
    SpacePlaybackExplainability? explainability,
    String? moodName,
  ) {
    final trimmedMood = moodName?.trim();
    if (trimmedMood == null || trimmedMood.isEmpty) {
      return explainability;
    }
    if (explainability == null) {
      return SpacePlaybackExplainability(moodName: trimmedMood);
    }
    if (explainability.moodName?.trim().isNotEmpty == true) {
      return explainability;
    }
    return _mergeExplainability(
      explainability,
      SpacePlaybackExplainability(moodName: trimmedMood),
    );
  }

  SpacePlaybackExplainability? _mergeExplainability(
    SpacePlaybackExplainability? primary,
    SpacePlaybackExplainability? fallback,
  ) {
    if (primary == null) return fallback;
    if (fallback == null) return primary;
    return SpacePlaybackExplainability(
      triggeredRule: primary.triggeredRule ?? fallback.triggeredRule,
      reason: primary.reason ?? fallback.reason,
      moodName: primary.moodName ?? fallback.moodName,
      recommendedBpmMin:
          primary.recommendedBpmMin ?? fallback.recommendedBpmMin,
      recommendedBpmMax:
          primary.recommendedBpmMax ?? fallback.recommendedBpmMax,
      recommendedBpmTarget:
          primary.recommendedBpmTarget ?? fallback.recommendedBpmTarget,
      usedMoodOnlyFallback:
          primary.usedMoodOnlyFallback ?? fallback.usedMoodOnlyFallback,
      moodOnlyCount: primary.moodOnlyCount ?? fallback.moodOnlyCount,
      bpmFilteredCount: primary.bpmFilteredCount ?? fallback.bpmFilteredCount,
      aiGenerationMode: primary.aiGenerationMode ?? fallback.aiGenerationMode,
      fuzzyProfileName: primary.fuzzyProfileName ?? fallback.fuzzyProfileName,
      fuzzyProfileTemplate:
          primary.fuzzyProfileTemplate ?? fallback.fuzzyProfileTemplate,
      restrictedToAllowedPlaylists: primary.restrictedToAllowedPlaylists ??
          fallback.restrictedToAllowedPlaylists,
      allowedPlaylistCount:
          primary.allowedPlaylistCount ?? fallback.allowedPlaylistCount,
    );
  }
}
