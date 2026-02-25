import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/store_dashboard/domain/entities/store.dart';
import '../../features/space_control/domain/entities/space.dart';
import '../enums/user_role.dart';
import 'session_state.dart';

/// A global Cubit that manages the current user session.
///
/// Sits above [MaterialApp] so that every screen can read / react to:
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

  /// Replace the active role.
  ///
  /// When switching to [playbackDevice] the selected space is kept,
  /// but the store is still accessible (read-only).
  void changeRole(UserRole role) {
    emit(state.copyWith(currentRole: role));
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

  /// Clear the space selection (e.g. when navigating away from space detail).
  void clearSpace() {
    emit(state.copyWith(clearSpace: true));
  }

  /// Full reset — used on logout.
  void reset() {
    emit(const SessionState.initial());
  }

  // ──────────────────── Convenience Shortcuts ──────────────────────────────

  /// Quick access to the current role without going through [state].
  UserRole get currentRole => state.currentRole;

  /// Quick access to whether a store has been selected.
  bool get hasStore => state.currentStore != null;

  /// Quick access to whether a space has been selected.
  bool get hasSpace => state.currentSpace != null;
}
