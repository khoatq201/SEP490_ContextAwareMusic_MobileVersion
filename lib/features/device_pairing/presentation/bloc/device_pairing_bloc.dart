import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/pair_device.dart';
import 'device_pairing_event.dart';
import 'device_pairing_state.dart';

class DevicePairingBloc extends Bloc<DevicePairingEvent, DevicePairingState> {
  final PairDevice pairDeviceUseCase;

  DevicePairingBloc({required this.pairDeviceUseCase})
      : super(const DevicePairingState()) {
    on<PairDeviceRequested>(_onPairDeviceRequested);
  }

  Future<void> _onPairDeviceRequested(
    PairDeviceRequested event,
    Emitter<DevicePairingState> emit,
  ) async {
    emit(state.copyWith(status: DevicePairingStatus.loading));

    final result = await pairDeviceUseCase(
      code: event.code,
      manufacturer: event.manufacturer,
      model: event.model,
      osVersion: event.osVersion,
      appVersion: event.appVersion,
      deviceId: event.deviceId,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: DevicePairingStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (pairingResult) {
        emit(state.copyWith(
          status: DevicePairingStatus.success,
          pairingResult: pairingResult,
        ));
      },
    );
  }
}
