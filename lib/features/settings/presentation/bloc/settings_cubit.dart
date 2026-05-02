import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/error_mapper.dart';
import '../../domain/entities/settings_snapshot.dart';
import '../../domain/usecases/get_settings_snapshot.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final GetSettingsSnapshot _getSettingsSnapshot;

  SettingsCubit(this._getSettingsSnapshot) : super(const SettingsState());

  void loadPlaybackDevice() {
    emit(
      state.copyWith(
        status: SettingsStatus.loaded,
        snapshot: const SettingsSnapshot(
          companyName: 'Playback device',
          businessType: 'Paired playback space',
          planName: 'Device session',
          explicitMusicAllowed: false,
          blockingSongsAllowed: false,
        ),
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> load() async {
    emit(state.copyWith(
        status: SettingsStatus.loading, clearErrorMessage: true));

    final result = await _getSettingsSnapshot();

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: SettingsStatus.error,
          errorMessage: ErrorMapper.displayMessageForFailure(failure),
        ));
      },
      (snapshot) {
        emit(state.copyWith(
          status: SettingsStatus.loaded,
          snapshot: snapshot,
          clearErrorMessage: true,
        ));
      },
    );
  }
}
