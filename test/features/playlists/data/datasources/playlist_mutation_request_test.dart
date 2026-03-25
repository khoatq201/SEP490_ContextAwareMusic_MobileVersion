import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/playlists/data/datasources/playlist_remote_datasource.dart';

void main() {
  group('PlaylistMutationRequest', () {
    test('serializes optional fields without empty strings', () {
      const request = PlaylistMutationRequest(
        name: '  Morning Flow ',
        storeId: 'store-1',
        moodId: ' ',
        description: '  Start the day right  ',
        isDynamic: false,
        isDefault: true,
      );

      expect(request.toJson(), {
        'name': 'Morning Flow',
        'storeId': 'store-1',
        'description': '  Start the day right  ',
        'isDynamic': false,
        'isDefault': true,
      });
    });

    test('keeps trackIds when empty to support clear-all semantics', () {
      const request = PlaylistMutationRequest(trackIds: []);

      expect(request.toJson(), {
        'trackIds': <String>[],
      });
    });
  });

  group('PlaylistMutationResult', () {
    test('parses id from nested data object', () {
      final result = PlaylistMutationResult.fromJson(const {
        'isSuccess': true,
        'message': 'ok',
        'data': {'id': 'playlist-123'},
      });

      expect(result.isSuccess, isTrue);
      expect(result.id, 'playlist-123');
    });

    test('parses id from direct string data', () {
      final result = PlaylistMutationResult.fromJson(const {
        'isSuccess': true,
        'data': 'playlist-456',
      });

      expect(result.id, 'playlist-456');
    });
  });
}
