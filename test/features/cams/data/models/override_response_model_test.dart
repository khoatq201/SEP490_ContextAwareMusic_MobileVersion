import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/enums/transition_type_enum.dart';
import 'package:cams_store_manager/features/cams/data/models/override_response_model.dart';

void main() {
  group('OverrideResponseModel', () {
    test('parses ACK-first response with string data payload', () {
      final model = OverrideResponseModel.fromApiResponse({
        'isSuccess': true,
        'message': 'Override applied',
        'data': 'space-123',
      });

      expect(model, isNotNull);
      expect(model!.spaceId, 'space-123');
      expect(model.isAckOnly, true);
    });

    test('still parses legacy override payload for compatibility', () {
      final model = OverrideResponseModel.fromApiResponse({
        'isSuccess': true,
        'data': {
          'spaceId': 'space-legacy',
          'playlistId': 'playlist-1',
          'hlsUrl': 'https://example.com/stream.m3u8',
          'transitionType': 1,
        },
      });

      expect(model, isNotNull);
      expect(model!.spaceId, 'space-legacy');
      expect(model.playlistId, 'playlist-1');
      expect(model.transitionType, TransitionTypeEnum.immediate);
      expect(model.isStreamReady, true);
    });
  });
}
