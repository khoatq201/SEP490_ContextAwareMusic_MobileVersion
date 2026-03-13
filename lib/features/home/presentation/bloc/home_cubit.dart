import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cams/domain/usecases/get_space_state.dart';
import '../../domain/repositories/home_repository.dart';
import 'home_state.dart';

/// Cubit for the Home Dashboard tab.
/// Loads [SensorEntity] and [CategoryEntity] from [HomeRepository].
/// Optionally fetches CAMS space playback state for mood display.
class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repository;
  final GetSpaceState _getSpaceState;

  HomeCubit(this._repository, {required GetSpaceState getSpaceState})
      : _getSpaceState = getSpaceState,
        super(const HomeState());

  Future<void> load() async {
    emit(state.copyWith(status: HomeStatus.loading));

    final sensorsResult = await _repository.getSensorData();
    final categoriesResult = await _repository.getCategories();

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
          (categories) => emit(state.copyWith(
            status: HomeStatus.loaded,
            sensors: sensors,
            categories: categories,
          )),
        );
      },
    );
  }

  /// Fetch CAMS playback state for the given space to display mood info.
  Future<void> loadSpacePlaybackState(String spaceId) async {
    final result = await _getSpaceState(spaceId);
    result.fold(
      (_) {}, // Non-fatal — mood display is optional
      (pbState) {
        emit(state.copyWith(
          currentMoodName: pbState.moodName,
          currentPlaylistName: pbState.currentPlaylistName,
          isStreaming: pbState.isStreaming,
          clearMood: pbState.moodName == null,
          clearPlaylist: pbState.currentPlaylistName == null,
        ));
      },
    );
  }

  void toggleAutoMode() {
    emit(state.copyWith(autoModeEnabled: !state.autoModeEnabled));
  }
}
