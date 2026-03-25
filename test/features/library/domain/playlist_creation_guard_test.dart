import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/enums/user_role.dart';
import 'package:cams_store_manager/features/library/domain/playlist_creation_guard.dart';

void main() {
  group('evaluatePlaylistCreationGuard', () {
    test('blocks playback device mode', () {
      final result = evaluatePlaylistCreationGuard(
        isPlaybackDevice: true,
        currentRole: UserRole.storeManager,
        currentStoreId: 'store-1',
      );

      expect(result, PlaylistCreationGuardResult.playbackDeviceBlocked);
      expect(result.errorMessage, 'Playback device cannot create playlists.');
    });

    test('blocks unsupported role', () {
      final result = evaluatePlaylistCreationGuard(
        isPlaybackDevice: false,
        currentRole: UserRole.playbackDevice,
        currentStoreId: 'store-1',
      );

      expect(result, PlaylistCreationGuardResult.roleBlocked);
      expect(result.errorMessage, 'Your role cannot create playlists.');
    });

    test('blocks when store is missing', () {
      final result = evaluatePlaylistCreationGuard(
        isPlaybackDevice: false,
        currentRole: UserRole.brandManager,
        currentStoreId: ' ',
      );

      expect(result, PlaylistCreationGuardResult.missingStore);
      expect(result.errorMessage, 'Select a store before creating a playlist.');
    });

    test('allows brand manager with selected store', () {
      final result = evaluatePlaylistCreationGuard(
        isPlaybackDevice: false,
        currentRole: UserRole.brandManager,
        currentStoreId: 'store-1',
      );

      expect(result, PlaylistCreationGuardResult.allowed);
      expect(result.isAllowed, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('allows store manager with selected store', () {
      final result = evaluatePlaylistCreationGuard(
        isPlaybackDevice: false,
        currentRole: UserRole.storeManager,
        currentStoreId: 'store-2',
      );

      expect(result, PlaylistCreationGuardResult.allowed);
    });
  });
}
