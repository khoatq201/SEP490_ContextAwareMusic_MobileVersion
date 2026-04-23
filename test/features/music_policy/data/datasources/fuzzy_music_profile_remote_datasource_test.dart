import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/network/dio_client.dart';
import 'package:cams_store_manager/core/services/local_storage_service.dart';
import 'package:cams_store_manager/features/music_policy/data/datasources/fuzzy_music_profile_remote_datasource.dart';

void main() {
  group('FuzzyMusicProfileRemoteDataSourceImpl', () {
    late _RecordingAdapter adapter;
    late FuzzyMusicProfileRemoteDataSourceImpl dataSource;

    setUp(() {
      adapter = _RecordingAdapter();
      final dioClient = DioClient(localStorage: LocalStorageService());
      dioClient.dio.httpClientAdapter = adapter;
      dataSource = FuzzyMusicProfileRemoteDataSourceImpl(dioClient: dioClient);
    });

    test('loads space profile from fuzzy music profile endpoint', () async {
      adapter.responsePayload = {
        'isSuccess': true,
        'data': _profilePayload(id: 'profile-space', storeId: 'store-1'),
      };

      final profile = await dataSource.getSpaceProfile(' space-1 ');

      expect(adapter.lastMethod, 'GET');
      expect(adapter.lastPath, '/api/fuzzy-music-profiles/space/space-1');
      expect(profile.id, 'profile-space');
      expect(profile.autoVolumeEnabled, isTrue);
      expect(profile.autoVolumeModeratePercent, 65);
    });

    test('toggles store auto volume with expected PATCH body', () async {
      adapter.responsePayload = {
        'isSuccess': true,
        'message': 'Auto volume updated.',
      };

      final message = await dataSource.setStoreAutoVolume(
        storeId: ' store-1 ',
        enabled: false,
      );

      expect(message, 'Auto volume updated.');
      expect(adapter.lastMethod, 'PATCH');
      expect(
        adapter.lastPath,
        '/api/fuzzy-music-profiles/store/store-1/auto-volume',
      );
      expect(adapter.lastBody, {'enabled': false});
    });

    test('loads brand profiles from list payload', () async {
      adapter.responsePayload = {
        'isSuccess': true,
        'data': [
          _profilePayload(id: 'brand-profile-1'),
          _profilePayload(id: 'brand-profile-2'),
        ],
      };

      final profiles = await dataSource.getBrandProfiles();

      expect(adapter.lastMethod, 'GET');
      expect(adapter.lastPath, '/api/fuzzy-music-profiles/brand');
      expect(profiles.map((profile) => profile.id), [
        'brand-profile-1',
        'brand-profile-2',
      ]);
    });
  });
}

Map<String, dynamic> _profilePayload({
  required String id,
  String? storeId,
}) {
  return {
    'id': id,
    'brandId': 'brand-1',
    'storeId': storeId,
    'name': 'Lunch Rush',
    'templateKey': 'coffee-house',
    'chillBpmMin': 70,
    'chillBpmMax': 90,
    'focusBpmMin': 91,
    'focusBpmMax': 115,
    'energeticBpmMin': 116,
    'energeticBpmMax': 140,
    'noiseQuietMaxDb': 45.5,
    'noiseLoudMinDb': 72.0,
    'defaultDecibelWhenNull': 58.0,
    'autoVolumeEnabled': true,
    'autoVolumeQuietPercent': 45,
    'autoVolumeModeratePercent': 65,
    'autoVolumeLoudPercent': 82,
    'autoVolumeMinPercent': 30,
    'autoVolumeMaxPercent': 90,
    'autoVolumeDeadbandPercent': 5,
  };
}

class _RecordingAdapter implements HttpClientAdapter {
  Map<String, dynamic> responsePayload = const {
    'isSuccess': true,
    'message': 'OK',
  };
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastMethod = options.method;
    lastPath = options.path;

    final bodyBytes = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bodyBytes.addAll(chunk);
      }
    }

    if (bodyBytes.isNotEmpty) {
      lastBody = Map<String, dynamic>.from(
        jsonDecode(utf8.decode(bodyBytes)) as Map,
      );
    } else {
      lastBody = null;
    }

    return ResponseBody.fromString(
      jsonEncode(responsePayload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
