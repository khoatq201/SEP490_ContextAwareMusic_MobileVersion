import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/usecases/location_usecases.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final SessionCubit sessionCubit;
  final AuthBloc authBloc;
  final GetPairedSpace getPairedSpace;
  final GetSpacesForStore getSpacesForStore;
  final GetSpacesForBrand getSpacesForBrand;

  LocationBloc({
    required this.sessionCubit,
    required this.authBloc,
    required this.getPairedSpace,
    required this.getSpacesForStore,
    required this.getSpacesForBrand,
  }) : super(const LocationState()) {
    on<LoadLocationsRequested>(_onLoadLocationsRequested);
  }

  /// Derives the effective role from AuthBloc user data (source of truth),
  /// bypassing SessionCubit which may be stale.
  String get _effectiveRole =>
      authBloc.state.user?.role.toLowerCase() ?? 'store_manager';

  Future<void> _onLoadLocationsRequested(
    LoadLocationsRequested event,
    Emitter<LocationState> emit,
  ) async {
    emit(state.copyWith(status: LocationStatus.loading));

    final session = sessionCubit.state;
    final role = _effectiveRole;
    debugPrint('[LocationBloc] effectiveRole=$role, isPlaybackDevice=${session.isPlaybackDevice}');

    // 1. Playback Device Mode
    if (session.isPlaybackDevice) {
      if (session.currentSpace == null || session.currentStore == null) {
        emit(state.copyWith(status: LocationStatus.failure, errorMessage: 'Device not properly paired'));
        return;
      }
      final result = await getPairedSpace(session.currentSpace!.id, session.currentStore!.id);
      result.fold(
        (failure) => emit(state.copyWith(status: LocationStatus.failure, errorMessage: failure.message)),
        (space) => emit(state.copyWith(status: LocationStatus.success, pairedSpace: space)),
      );
      return;
    }

    // 2. Brand Manager / Admin → show ALL stores with spaces
    if (role == 'brand_manager' || role == 'admin') {
      final user = authBloc.state.user;
      final storeIds = user?.storeIds ?? [];
      debugPrint('[LocationBloc] brandManager branch: storeIds=$storeIds');
      if (storeIds.isEmpty) {
        emit(state.copyWith(status: LocationStatus.failure, errorMessage: 'No stores assigned'));
        return;
      }
      final result = await getSpacesForBrand(storeIds);
      result.fold(
        (failure) => emit(state.copyWith(status: LocationStatus.failure, errorMessage: failure.message)),
        (brandSpaces) => emit(state.copyWith(status: LocationStatus.success, brandSpaces: brandSpaces)),
      );
      return;
    }

    // 3. Store Manager → show spaces for the selected store
    if (session.currentStore == null) {
      emit(state.copyWith(status: LocationStatus.failure, errorMessage: 'No store selected'));
      return;
    }
    final result = await getSpacesForStore(session.currentStore!.id);
    result.fold(
      (failure) => emit(state.copyWith(status: LocationStatus.failure, errorMessage: failure.message)),
      (spaces) => emit(state.copyWith(status: LocationStatus.success, storeSpaces: spaces)),
    );
  }
}
