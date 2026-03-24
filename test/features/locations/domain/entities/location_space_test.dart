import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/enums/entity_status_enum.dart';
import 'package:cams_store_manager/core/enums/space_type_enum.dart';
import 'package:cams_store_manager/features/locations/domain/entities/location_space.dart';

void main() {
  group('LocationSpace queue-first compatibility', () {
    test(
        'currentPlaybackName prefers currentTrackName over currentPlaylistName',
        () {
      const space = LocationSpace(
        id: 'space-1',
        name: 'Main Hall',
        storeId: 'store-1',
        type: SpaceTypeEnum.hall,
        status: EntityStatusEnum.active,
        currentTrackName: 'Track A',
        currentPlaylistName: 'Legacy Playlist',
      );

      expect(space.currentPlaybackName, 'Track A');
    });

    test('hasLivePlayback is true when hasActivePlayback is true', () {
      const space = LocationSpace(
        id: 'space-1',
        name: 'Main Hall',
        storeId: 'store-1',
        type: SpaceTypeEnum.hall,
        status: EntityStatusEnum.active,
        hasActivePlayback: true,
      );

      expect(space.hasLivePlayback, isTrue);
    });

    test('hasLivePlayback keeps legacy fallback from currentPlaylistId', () {
      const space = LocationSpace(
        id: 'space-1',
        name: 'Main Hall',
        storeId: 'store-1',
        type: SpaceTypeEnum.hall,
        status: EntityStatusEnum.active,
        currentPlaylistId: 'playlist-legacy',
      );

      expect(space.hasLivePlayback, isTrue);
    });
  });
}
