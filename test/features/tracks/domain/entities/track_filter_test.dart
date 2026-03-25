import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/enums/entity_status_enum.dart';
import 'package:cams_store_manager/core/enums/music_provider_enum.dart';
import 'package:cams_store_manager/features/tracks/domain/entities/track_filter.dart';

void main() {
  group('TrackFilter', () {
    test('serializes optional query params without empty values', () {
      final filter = TrackFilter(
        page: 2,
        pageSize: 25,
        search: '  morning vibe  ',
        moodId: '   ',
        genre: ' lounge ',
        provider: MusicProviderEnum.suno,
        isAiGenerated: true,
        status: EntityStatusEnum.active,
        createdFrom: DateTime.parse('2026-03-01T00:00:00Z'),
        createdTo: DateTime.parse('2026-03-31T23:59:59Z'),
      );

      expect(filter.toQueryParameters(), {
        'page': 2,
        'pageSize': 25,
        'search': 'morning vibe',
        'genre': 'lounge',
        'provider': 1,
        'isAiGenerated': true,
        'status': 1,
        'createdFrom': '2026-03-01T00:00:00.000Z',
        'createdTo': '2026-03-31T23:59:59.000Z',
      });
    });
  });
}
