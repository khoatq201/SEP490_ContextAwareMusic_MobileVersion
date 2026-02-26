import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/store_dashboard/domain/entities/store.dart';
import '../../features/space_control/domain/entities/space.dart';
import '../enums/app_mode.dart';
import '../enums/user_role.dart';
import 'session_state.dart';

/// A global Cubit that manages the current user session.
///
/// Sits above [MaterialApp] so that every screen can read / react to:
/// - The operational **mode** of the app.
/// - The logged-in user's **role**.
/// - The currently selected **store** and **space**.
///
/// Usage in any widget:
/// ```dart
/// final session = context.read<SessionCubit>().state;
/// if (session.canEditDevices) { … }
/// ```
class SessionCubit extends Cubit<SessionState> {
  SessionCubit() : super(const SessionState.initial());

  // ──────────────────────── Mutators ────────────────────────────────────────

  /// Replace the active app mode.
  void changeAppMode(AppMode mode) {
    emit(state.copyWith(appMode: mode));
  }

  /// Replace the active role.
  ///
  /// When switching to [playbackDevice] the selected space is kept,
  /// but the store is still accessible (read-only).
  void changeRole(UserRole role) {
    emit(state.copyWith(currentRole: role));
  }

  /// Maps string roles from JWT/Auth to internal enum.
  void setRoleFromString(String roleStr) {
    switch (roleStr.toLowerCase()) {
      case 'store_manager':
        changeRole(UserRole.storeManager);
        break;
      case 'brand_manager':
      case 'admin':
        changeRole(UserRole.brandManager);
        break;
      default:
        changeRole(UserRole.storeManager);
    }
  }

  /// Set the active store.
  ///
  /// Automatically **clears the current space** because it belonged to the
  /// previous store. Downstream code should pick a new space after this call.
  void changeStore(Store store) {
    emit(state.copyWith(currentStore: store, clearSpace: true));
  }

  /// Set the active space inside the current store.
  void changeSpace(Space space) {
    emit(state.copyWith(currentSpace: space));
  }

  /// Sets up the session for Playback Device mode in one go.
  void setPlaybackMode({
    required Store store,
    required Space space,
    required String deviceId,
  }) {
    emit(state.copyWith(
      appMode: AppMode.playbackDevice,
      currentRole: UserRole.playbackDevice,
      currentStore: store,
      currentSpace: space,
      pairedDeviceId: deviceId,
    ));
  }

  /// Clear the space selection (e.g. when navigating away from space detail).
  void clearSpace() {
    emit(state.copyWith(clearSpace: true));
  }

  /// Full reset — used on logout or unpairing.
  void reset() {
    emit(const SessionState.initial());
  }

  // ──────────────────── Convenience Shortcuts ──────────────────────────────

  /// Quick access to the app mode.
  AppMode get appMode => state.appMode;

  /// Quick access to the current role without going through [state].
  UserRole get currentRole => state.currentRole;

  /// Quick access to whether a store has been selected.
  bool get hasStore => state.currentStore != null;

  /// Quick access to whether a space has been selected.
  bool get hasSpace => state.currentSpace != null;
}
