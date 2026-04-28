import '../../../core/enums/user_role.dart';

enum PlaylistCreationGuardResult {
  allowed,
  playbackDeviceBlocked,
  roleBlocked,
  missingStore,
}

extension PlaylistCreationGuardResultMessage on PlaylistCreationGuardResult {
  bool get isAllowed => this == PlaylistCreationGuardResult.allowed;

  String? get errorMessage {
    switch (this) {
      case PlaylistCreationGuardResult.allowed:
        return null;
      case PlaylistCreationGuardResult.playbackDeviceBlocked:
        return 'Playback device cannot create playlists.';
      case PlaylistCreationGuardResult.roleBlocked:
        return 'Your role cannot create playlists.';
      case PlaylistCreationGuardResult.missingStore:
        return 'Select a store before creating a playlist.';
    }
  }
}

PlaylistCreationGuardResult evaluatePlaylistCreationGuard({
  required bool isPlaybackDevice,
  required UserRole currentRole,
  required String? currentStoreId,
}) {
  if (isPlaybackDevice) {
    return PlaylistCreationGuardResult.playbackDeviceBlocked;
  }

  final canCreateByRole = currentRole == UserRole.brandManager ||
      currentRole == UserRole.storeManager;
  if (!canCreateByRole) {
    return PlaylistCreationGuardResult.roleBlocked;
  }

  if (currentStoreId == null || currentStoreId.trim().isEmpty) {
    return PlaylistCreationGuardResult.missingStore;
  }

  return PlaylistCreationGuardResult.allowed;
}
