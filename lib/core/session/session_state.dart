import 'package:equatable/equatable.dart';

import '../../features/store_dashboard/domain/entities/store.dart';
import '../../features/space_control/domain/entities/space.dart';
import '../enums/user_role.dart';

/// Represents the current authenticated session state of the application.
///
/// This is the single source of truth for:
/// - **Who** is logged in ([currentRole]).
/// - **Which store** they are operating on ([currentStore]).
/// - **Which space** they are viewing / controlling ([currentSpace]).
class SessionState extends Equatable {
  /// Current role of the logged-in user.
  final UserRole currentRole;

  /// The store currently selected / assigned to the user.
  /// `null` before any store is selected or loaded.
  final Store? currentStore;

  /// The space currently selected inside the active store.
  /// `null` before any space is picked.
  final Space? currentSpace;

  const SessionState({
    required this.currentRole,
    this.currentStore,
    this.currentSpace,
  });

  /// Default initial state — defaults to [UserRole.storeManager] with no
  /// store or space selected.
  const SessionState.initial()
      : currentRole = UserRole.storeManager,
        currentStore = null,
        currentSpace = null;

  // ─────────────────────────── Permission Getters ───────────────────────────

  /// Whether the user can switch between spaces.
  /// Playback devices are locked to a single space.
  bool get canSwitchSpace => currentRole != UserRole.playbackDevice;

  /// Whether the user can switch between stores.
  /// Only a brand manager oversees multiple stores.
  bool get canSwitchStore => currentRole == UserRole.brandManager;

  /// Whether the user can add / edit / remove devices (hubs, sensors).
  /// Playback devices have no hardware management rights.
  bool get canEditDevices => currentRole != UserRole.playbackDevice;

  /// Whether the user can edit music context rules.
  bool get canEditContextRules => currentRole != UserRole.playbackDevice;

  /// Whether the user can access brand-level analytics.
  bool get canViewBrandAnalytics => currentRole == UserRole.brandManager;

  // ──────────────────────────── copyWith ────────────────────────────────────

  SessionState copyWith({
    UserRole? currentRole,
    Store? currentStore,
    Space? currentSpace,
    bool clearStore = false,
    bool clearSpace = false,
  }) {
    return SessionState(
      currentRole: currentRole ?? this.currentRole,
      currentStore: clearStore ? null : (currentStore ?? this.currentStore),
      currentSpace: clearSpace ? null : (currentSpace ?? this.currentSpace),
    );
  }

  // ──────────────────────────── Equatable ───────────────────────────────────

  @override
  List<Object?> get props => [currentRole, currentStore, currentSpace];

  @override
  String toString() =>
      'SessionState(role: ${currentRole.label}, '
      'store: ${currentStore?.name ?? "none"}, '
      'space: ${currentSpace?.name ?? "none"})';
}
