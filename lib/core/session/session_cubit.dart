import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/store_dashboard/domain/entities/store.dart';
import '../../features/space_control/domain/entities/space.dart';
import '../enums/app_mode.dart';
import '../enums/entity_status_enum.dart';
import '../enums/space_type_enum.dart';
import '../enums/user_role.dart';
import '../services/local_storage_service.dart';
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
/// if (session.canEditDevices) { ... }
/// ```
class SessionCubit extends Cubit<SessionState> {
  static const String _selectionSnapshotKey = 'session_selection_snapshot';

  final LocalStorageService _localStorage;

  SessionCubit({required LocalStorageService localStorage})
      : _localStorage = localStorage,
        super(const SessionState.initial());

  // ------------------------ Mutators ------------------------

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
  /// Supports both PascalCase from backend (e.g. "StoreManager") and
  /// legacy snake_case (e.g. "store_manager").
  void setRoleFromString(String roleStr) {
    switch (roleStr.toLowerCase()) {
      case 'storemanager':
      case 'store_manager':
        changeRole(UserRole.storeManager);
        break;
      case 'brandmanager':
      case 'brand_manager':
      case 'admin':
        changeRole(UserRole.brandManager);
        break;
      case 'systemadmin':
      case 'system_admin':
        changeRole(
            UserRole.brandManager); // SystemAdmin maps to brandManager in app
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
    _persistSelectionSnapshot();
  }

  /// Set the active space inside the current store.
  void changeSpace(Space space) {
    emit(state.copyWith(currentSpace: space));
    _persistSelectionSnapshot();
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
    _persistSelectionSnapshot();
  }

  /// Clear the space selection (e.g. when navigating away from space detail).
  void clearSpace() {
    emit(state.copyWith(clearSpace: true));
    _persistSelectionSnapshot();
  }

  /// Full reset - used on logout or unpairing.
  void reset() {
    emit(const SessionState.initial());
    unawaited(clearSelectionSnapshot());
  }

  // ------------------------ Persistence ------------------------

  /// Restore selected store/space from local storage.
  ///
  /// If data is missing or malformed, restore is ignored and snapshot is cleared.
  Future<void> restoreSelectionFromStorage() async {
    try {
      final raw = _localStorage.getSetting(_selectionSnapshotKey);
      if (raw is! Map) return;

      final snapshot = Map<String, dynamic>.from(raw);
      final restoredStore = _storeFromSnapshot(snapshot['store']);
      if (restoredStore == null) {
        await clearSelectionSnapshot();
        return;
      }

      final restoredSpace = _spaceFromSnapshot(
        snapshot['space'],
        expectedStoreId: restoredStore.id,
      );

      emit(state.copyWith(
        currentStore: restoredStore,
        currentSpace: restoredSpace,
        clearSpace: restoredSpace == null,
      ));
    } catch (_) {
      await clearSelectionSnapshot();
    }
  }

  Future<void> clearSelectionSnapshot() async {
    try {
      await _localStorage.removeSetting(_selectionSnapshotKey);
    } catch (_) {
      // Best effort only.
    }
  }

  Future<void> _saveSelectionSnapshot() async {
    final selectedStore = state.currentStore;
    if (selectedStore == null) {
      await clearSelectionSnapshot();
      return;
    }

    final selectedSpace = state.currentSpace;
    final snapshot = <String, dynamic>{
      'store': <String, dynamic>{
        'id': selectedStore.id,
        'name': selectedStore.name,
        'brandId': selectedStore.brandId,
        'status': selectedStore.status.value,
      },
      if (selectedSpace != null)
        'space': <String, dynamic>{
          'id': selectedSpace.id,
          'name': selectedSpace.name,
          'storeId': selectedSpace.storeId,
          'type': selectedSpace.type.value,
          'status': selectedSpace.status.value,
          'currentMood': selectedSpace.currentMood,
        },
    };

    try {
      await _localStorage.saveSetting(_selectionSnapshotKey, snapshot);
    } catch (_) {
      // Best effort only.
    }
  }

  Store? _storeFromSnapshot(dynamic rawStore) {
    if (rawStore is! Map) return null;
    final map = Map<String, dynamic>.from(rawStore);

    final id = map['id']?.toString();
    final name = map['name']?.toString();
    if (id == null || id.isEmpty || name == null || name.isEmpty) {
      return null;
    }

    return Store(
      id: id,
      name: name,
      brandId: map['brandId']?.toString() ?? '',
      status: EntityStatusEnum.fromJson(map['status'] ?? 1),
    );
  }

  Space? _spaceFromSnapshot(
    dynamic rawSpace, {
    required String expectedStoreId,
  }) {
    if (rawSpace is! Map) return null;
    final map = Map<String, dynamic>.from(rawSpace);

    final id = map['id']?.toString();
    final name = map['name']?.toString();
    final storeId = map['storeId']?.toString();
    if (id == null ||
        id.isEmpty ||
        name == null ||
        name.isEmpty ||
        storeId == null ||
        storeId != expectedStoreId) {
      return null;
    }

    return Space(
      id: id,
      name: name,
      storeId: storeId,
      type: SpaceTypeEnum.fromValue(_parseInt(map['type'])),
      status: EntityStatusEnum.fromJson(map['status'] ?? 1),
      currentMood: map['currentMood']?.toString(),
    );
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  void _persistSelectionSnapshot() {
    unawaited(_saveSelectionSnapshot());
  }

  // -------------------- Convenience Shortcuts --------------------

  /// Quick access to the app mode.
  AppMode get appMode => state.appMode;

  /// Quick access to the current role without going through [state].
  UserRole get currentRole => state.currentRole;

  /// Quick access to whether a store has been selected.
  bool get hasStore => state.currentStore != null;

  /// Quick access to whether a space has been selected.
  bool get hasSpace => state.currentSpace != null;
}
