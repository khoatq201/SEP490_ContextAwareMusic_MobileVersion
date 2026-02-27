import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_settings_snapshot.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final GetSettingsSnapshot _getSettingsSnapshot;

  SettingsCubit(this._getSettingsSnapshot) : super(const SettingsState());

  Future<void> load() async {
    emit(state.copyWith(status: SettingsStatus.loading, clearErrorMessage: true));

    final result = await _getSettingsSnapshot();

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: SettingsStatus.error,
          errorMessage: failure.message,
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
