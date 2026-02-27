import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/home_repository.dart';
import 'home_state.dart';

/// Cubit for the Home Dashboard tab.
/// Loads [SensorEntity] and [CategoryEntity] from [HomeRepository].
class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repository;

  HomeCubit(this._repository) : super(const HomeState());

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

  void toggleAutoMode() {
    emit(state.copyWith(autoModeEnabled: !state.autoModeEnabled));
  }
}
