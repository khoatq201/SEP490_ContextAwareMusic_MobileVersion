import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/constants/api_constants.dart';
import 'package:cams_store_manager/core/network/dio_client.dart';
import 'package:cams_store_manager/core/services/local_storage_service.dart';
import 'package:cams_store_manager/features/space_schedule/data/datasources/space_schedule_remote_datasource.dart';
import 'package:cams_store_manager/features/space_schedule/data/models/schedule_slot_model.dart';

void main() {
  group('CMS schedule API contract', () {
    test('builds space schedule endpoints', () {
      expect(
        ApiConstants.cmsScheduleSpaceBootstrap('space-1'),
        '/api/cms/schedule/spaces/space-1/bootstrap',
      );
      expect(
        ApiConstants.cmsScheduleSpaceSlot('space-1', 'slot-1'),
        '/api/cms/schedule/spaces/space-1/slots/slot-1',
      );
      expect(
        ApiConstants.cmsScheduleSpaceApplySource('space-1'),
        '/api/cms/schedule/spaces/space-1/apply-source',
      );
      expect(
        ApiConstants.cmsScheduleSpaceSaveToLibrary('space-1'),
        '/api/cms/schedule/spaces/space-1/save-to-library',
      );
      expect(
        ApiConstants.cmsScheduleSpaceToggle('space-1'),
        '/api/cms/schedule/spaces/space-1/toggle',
      );
      expect(
        ApiConstants.cmsScheduleBrandLibrary('brand-1'),
        '/api/cms/schedule/brands/brand-1/library',
      );
      expect(
        ApiConstants.cmsScheduleBrandSource('source-1'),
        '/api/cms/schedule/brands/sources/source-1',
      );
      expect(
        ApiConstants.cmsScheduleBrandSourceSlot('source-1', 'slot-1'),
        '/api/cms/schedule/brands/sources/source-1/slots/slot-1',
      );
    });
  });

  group('SpaceScheduleRemoteDataSourceImpl', () {
    late _RecordingAdapter adapter;
    late SpaceScheduleRemoteDataSourceImpl dataSource;

    setUp(() {
      adapter = _RecordingAdapter();
      final dioClient = DioClient(localStorage: LocalStorageService());
      dioClient.dio.interceptors.clear();
      dioClient.dio.httpClientAdapter = adapter;
      dataSource = SpaceScheduleRemoteDataSourceImpl(dioClient: dioClient);
    });

    test('loads bootstrap and normalizes API musicId fields', () async {
      adapter.responsePayload = _bootstrapPayload();

      final result = await dataSource.getBootstrap(' space-1 ');

      expect(adapter.lastMethod, 'GET');
      expect(adapter.lastPath, '/api/cms/schedule/spaces/space-1/bootstrap');
      expect(result.draftSchedule?.slots.single.musicId, 'playlist-1');
      expect(result.draftSchedule?.slots.single.daysOfWeek, [0, 1]);
      expect(result.librarySources.single.id, 'library-1');
      expect(result.templateSources.single.id, 'template-1');
      expect(result.templateSources.single.type.name, 'template');
      expect(result.musicCatalog.single.title, 'Lunch Mix');
    });

    test('normalizes web and legacy Sunday day values', () {
      final slot = ScheduleSlotModel.fromJson(const {
        'id': 'slot-1',
        'daysOfWeek': [0, 7, 1, 9],
        'startTime': '09:00',
        'endTime': '11:00',
        'musicId': 'playlist-1',
      });

      expect(slot.daysOfWeek, [0, 1]);
    });

    test('upserts slot with playlistId body', () async {
      adapter.responsePayload = _successPayload('slot-1');

      final message = await dataSource.upsertSlot(
        spaceId: ' space-1 ',
        slot: const ScheduleSlotModel(
          id: ' slot-1 ',
          daysOfWeek: [1, 2],
          startTime: '09:00',
          endTime: '11:00',
          musicId: 'playlist-1',
        ),
      );

      expect(message, 'slot-1');
      expect(adapter.lastMethod, 'PUT');
      expect(adapter.lastPath, '/api/cms/schedule/spaces/space-1/slots/slot-1');
      expect(adapter.lastBody, {
        'daysOfWeek': [1, 2],
        'startTime': '09:00',
        'endTime': '11:00',
        'playlistId': 'playlist-1',
      });
    });

    test('sends apply, save-to-library, toggle, and delete routes', () async {
      adapter.responsePayload = _successPayload('ok');

      await dataSource.applySource(spaceId: 'space-1', sourceId: 'source-1');
      expect(adapter.lastMethod, 'POST');
      expect(adapter.lastPath, '/api/cms/schedule/spaces/space-1/apply-source');
      expect(adapter.lastBody, {'sourceId': 'source-1'});

      await dataSource.saveToLibrary(
        spaceId: 'space-1',
        title: 'Weekend',
        subtitle: 'Warm afternoons',
      );
      expect(adapter.lastMethod, 'POST');
      expect(
        adapter.lastPath,
        '/api/cms/schedule/spaces/space-1/save-to-library',
      );
      expect(adapter.lastBody, {
        'title': 'Weekend',
        'subtitle': 'Warm afternoons',
      });

      await dataSource.toggle(spaceId: 'space-1', enabled: false);
      expect(adapter.lastMethod, 'PATCH');
      expect(adapter.lastPath, '/api/cms/schedule/spaces/space-1/toggle');
      expect(adapter.lastBody, {'enabled': false});

      await dataSource.deleteSlot(spaceId: 'space-1', slotId: 'slot-1');
      expect(adapter.lastMethod, 'DELETE');
      expect(adapter.lastPath, '/api/cms/schedule/spaces/space-1/slots/slot-1');
    });

    test('loads and mutates brand schedule sources and slots', () async {
      adapter.responsePayload = _brandLibraryPayload();

      final sources = await dataSource.getBrandLibrary('brand-1');
      expect(adapter.lastMethod, 'GET');
      expect(adapter.lastPath, '/api/cms/schedule/brands/brand-1/library');
      expect(sources.single.title, 'Brand dayparts');

      adapter.responsePayload = _brandTemplatesPayload();
      final templates = await dataSource.getBrandTemplates('brand-1');
      expect(adapter.lastMethod, 'GET');
      expect(adapter.lastPath, '/api/cms/schedule/brands/brand-1/templates');
      expect(templates.single.title, 'Strict Sync dayparts');
      expect(templates.single.type.name, 'template');

      adapter.responsePayload = _successPayload('source-1');
      await dataSource.createBrandSource(
        title: 'Brand dayparts',
        subtitle: 'Required schedule',
      );
      expect(adapter.lastMethod, 'POST');
      expect(adapter.lastPath, '/api/cms/schedule/brands/sources');
      expect(adapter.lastBody, {
        'title': 'Brand dayparts',
        'subtitle': 'Required schedule',
        'isTemplate': false,
      });

      await dataSource.createBrandSource(
        title: 'Strict Sync dayparts',
        subtitle: 'Brand template',
        isTemplate: true,
      );
      expect(adapter.lastMethod, 'POST');
      expect(adapter.lastPath, '/api/cms/schedule/brands/sources');
      expect(adapter.lastBody, {
        'title': 'Strict Sync dayparts',
        'subtitle': 'Brand template',
        'isTemplate': true,
      });

      await dataSource.updateBrandSource(
        sourceId: 'source-1',
        title: 'Updated brand dayparts',
      );
      expect(adapter.lastMethod, 'PATCH');
      expect(adapter.lastPath, '/api/cms/schedule/brands/sources/source-1');

      await dataSource.upsertBrandSlot(
        sourceId: 'source-1',
        slot: const ScheduleSlotModel(
          id: 'slot-1',
          daysOfWeek: [0, 1],
          startTime: '09:00',
          endTime: '12:00',
          musicId: 'playlist-1',
        ),
      );
      expect(adapter.lastMethod, 'PUT');
      expect(
        adapter.lastPath,
        '/api/cms/schedule/brands/sources/source-1/slots/slot-1',
      );
      expect(adapter.lastBody, {
        'daysOfWeek': [0, 1],
        'startTime': '09:00',
        'endTime': '12:00',
        'playlistId': 'playlist-1',
      });

      await dataSource.deleteBrandSlot(sourceId: 'source-1', slotId: 'slot-1');
      expect(adapter.lastMethod, 'DELETE');
      expect(
        adapter.lastPath,
        '/api/cms/schedule/brands/sources/source-1/slots/slot-1',
      );

      await dataSource.deleteBrandSource(sourceId: 'source-1');
      expect(adapter.lastMethod, 'DELETE');
      expect(adapter.lastPath, '/api/cms/schedule/brands/sources/source-1');
    });
  });
}

Map<String, dynamic> _bootstrapPayload() {
  final schedule = {
    'id': 'schedule-1',
    'name': 'Main schedule',
    'spaceId': 'space-1',
    'enabled': true,
    'updatedAt': '2026-04-17T08:00:00Z',
    'slots': [
      {
        'id': 'slot-1',
        'daysOfWeek': [0, 1],
        'startTime': '09:00',
        'endTime': '11:00',
        'musicId': 'playlist-1',
      },
    ],
  };

  return {
    'isSuccess': true,
    'data': {
      'draftSchedule': schedule,
      'librarySources': [
        {
          'id': 'library-1',
          'title': 'Saved lunch',
          'subtitle': 'Local favorite',
          'type': 'library',
          'schedule': schedule,
          'isUserCreated': true,
        },
      ],
      'templateSources': [
        {
          'id': 'template-1',
          'title': 'Strict template',
          'subtitle': 'Brand source',
          'type': 'template',
          'schedule': schedule,
          'isUserCreated': false,
        },
      ],
      'musicCatalog': [
        {
          'id': 'playlist-1',
          'title': 'Lunch Mix',
          'artist': 'Brand',
          'collection': 'Templates',
          'artworkLabel': 'Lunch',
          'primaryHex': '#123456',
          'secondaryHex': '#654321',
        },
      ],
    },
  };
}

Map<String, dynamic> _successPayload(String data) {
  return {
    'isSuccess': true,
    'message': 'Saved.',
    'data': data,
  };
}

Map<String, dynamic> _brandLibraryPayload() {
  final schedule = {
    'id': 'schedule-brand-1',
    'name': 'Brand dayparts',
    'spaceId': null,
    'enabled': true,
    'updatedAt': '2026-04-17T08:00:00Z',
    'slots': [
      {
        'id': 'slot-1',
        'daysOfWeek': [0, 1],
        'startTime': '09:00',
        'endTime': '12:00',
        'playlistId': 'playlist-1',
      },
    ],
  };

  return {
    'isSuccess': true,
    'data': [
      {
        'id': 'source-1',
        'title': 'Brand dayparts',
        'subtitle': 'Required schedule',
        'type': 'library',
        'schedule': schedule,
        'isUserCreated': true,
      },
    ],
  };
}

Map<String, dynamic> _brandTemplatesPayload() {
  final schedule = {
    'id': 'schedule-template-1',
    'name': 'Strict Sync dayparts',
    'spaceId': null,
    'enabled': true,
    'updatedAt': '2026-04-17T08:00:00Z',
    'slots': [
      {
        'id': 'slot-template-1',
        'daysOfWeek': [0, 1],
        'startTime': '09:00',
        'endTime': '12:00',
        'playlistId': 'playlist-1',
      },
    ],
  };

  return {
    'isSuccess': true,
    'data': [
      {
        'id': 'template-source-1',
        'title': 'Strict Sync dayparts',
        'subtitle': 'Brand template',
        'type': 'template',
        'schedule': schedule,
        'isUserCreated': false,
      },
    ],
  };
}

class _RecordingAdapter implements HttpClientAdapter {
  Map<String, dynamic> responsePayload = _bootstrapPayload();
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
