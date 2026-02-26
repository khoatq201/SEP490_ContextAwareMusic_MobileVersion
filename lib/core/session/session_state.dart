import 'package:equatable/equatable.dart';

import '../../features/store_dashboard/domain/entities/store.dart';
import '../../features/space_control/domain/entities/space.dart';
import '../enums/app_mode.dart';
import '../enums/user_role.dart';

/// Represents the current authenticated session state of the application.
///
/// This is the single source of truth for:
/// - **Which mode** the app is in ([appMode]).
/// - **Who** is logged in ([currentRole]).
/// - **Which store** they are operating on ([currentStore]).
/// - **Which space** they are viewing / controlling ([currentSpace]).
class SessionState extends Equatable {
  /// The operational mode of the app (e.g., remote control or playback device).
  final AppMode appMode;

  /// Current role of the logged-in user.
  final UserRole currentRole;

  /// The store currently selected / assigned to the user.
  /// `null` before any store is selected or loaded.
  final Store? currentStore;

  /// The space currently selected inside the active store.
  /// `null` before any space is picked.
  final Space? currentSpace;

  /// If in playback device mode, the ID of the paired device.
  final String? pairedDeviceId;

  const SessionState({
    required this.appMode,
    required this.currentRole,
    this.currentStore,
    this.currentSpace,
    this.pairedDeviceId,
  });

  /// Default initial state — defaults to [AppMode.remoteControl] and
  /// [UserRole.storeManager] with no store or space selected.
  const SessionState.initial()
      : appMode = AppMode.remoteControl,
        currentRole = UserRole.storeManager,
        currentStore = null,
        currentSpace = null,
        pairedDeviceId = null;

  // ─────────────────────────── Mode Getters ───────────────────────────────

  /// Whether the app is currently operating as a playback device.
  bool get isPlaybackDevice => appMode == AppMode.playbackDevice;

  // ─────────────────────────── Permission Getters ───────────────────────────

  /// Whether the user can switch between spaces.
  /// Playback devices are locked to a single space.
  bool get canSwitchSpace => !isPlaybackDevice && currentRole != UserRole.playbackDevice;

  /// Whether the user can switch between stores.
  /// Only a brand manager oversees multiple stores.
  bool get canSwitchStore => !isPlaybackDevice && currentRole == UserRole.brandManager;

  /// Whether the user can add / edit / remove devices (hubs, sensors).
  /// Playback devices have no hardware management rights.
  bool get canEditDevices => !isPlaybackDevice && currentRole != UserRole.playbackDevice;

  /// Whether the user can edit music context rules.
  bool get canEditContextRules => !isPlaybackDevice && currentRole != UserRole.playbackDevice;

  /// Whether the user can access brand-level analytics.
  bool get canViewBrandAnalytics => !isPlaybackDevice && currentRole == UserRole.brandManager;

  // ──────────────────────────── copyWith ────────────────────────────────────

  SessionState copyWith({
    AppMode? appMode,
    UserRole? currentRole,
    Store? currentStore,
    Space? currentSpace,
    String? pairedDeviceId,
    bool clearStore = false,
    bool clearSpace = false,
  }) {
    return SessionState(
      appMode: appMode ?? this.appMode,
      currentRole: currentRole ?? this.currentRole,
      currentStore: clearStore ? null : (currentStore ?? this.currentStore),
      currentSpace: clearSpace ? null : (currentSpace ?? this.currentSpace),
      pairedDeviceId: pairedDeviceId ?? this.pairedDeviceId,
    );
  }

  // ──────────────────────────── Equatable ───────────────────────────────────

  @override
  List<Object?> get props => [
        appMode,
        currentRole,
        currentStore,
        currentSpace,
        pairedDeviceId,
      ];

  @override
  String toString() =>
      'SessionState(mode: ${appMode.name}, role: ${currentRole.label}, '
      'store: ${currentStore?.name ?? "none"}, '
      'space: ${currentSpace?.name ?? "none"}, '
      'device: ${pairedDeviceId ?? "none"})';
}
