import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/constants/api_constants.dart';
import 'package:cams_store_manager/core/network/dio_client.dart';
import 'package:cams_store_manager/core/services/local_storage_service.dart';
import 'package:cams_store_manager/features/config_governance/data/datasources/config_governance_remote_datasource.dart';
import 'package:cams_store_manager/features/config_governance/domain/entities/config_governance_enums.dart';
import 'package:cams_store_manager/features/config_governance/domain/entities/config_query.dart';
import 'package:cams_store_manager/features/config_governance/domain/entities/config_value_upsert_request.dart';

void main() {
  group('Config governance query contract', () {
    test('builds session brand and store routes with default query params', () {
      const query = ConfigQuery();

      expect(ApiConstants.cmsConfigBrand, '/api/cms/config/brand');
      expect(ApiConstants.cmsConfigStore, '/api/cms/config/store');
      expect(query.toQueryParameters(), {
        'page': 1,
        'pageSize': 20,
      });
    });

    test('builds selected store and selected space routes', () {
      expect(
        ApiConstants.cmsConfigStoreById('store-1'),
        '/api/cms/config/store/store-1',
      );
      expect(
        ApiConstants.cmsConfigSpace('space-1'),
        '/api/cms/config/space/space-1',
      );
      expect(
        ApiConstants.cmsConfigStoreValue,
        '/api/cms/config/store-value',
      );
      expect(
        ApiConstants.cmsConfigBrandValue,
        '/api/cms/config/brand-value',
      );
      expect(
        ApiConstants.cmsConfigStoreValueById('store-1'),
        '/api/cms/config/store/store-1/value',
      );
      expect(
        ApiConstants.cmsConfigSpaceValue('space-1'),
        '/api/cms/config/space/space-1/value',
      );
      expect(
        ApiConstants.cmsConfigStoresGovernanceMode,
        '/api/cms/config/stores/governance-mode',
      );
    });

    test('includes optional domain and keyPrefix filters', () {
      const query = ConfigQuery(
        page: 2,
        pageSize: 50,
        domain: ConfigDomain.playback,
        keyPrefix: ' playback. ',
      );

      expect(query.toQueryParameters(), {
        'page': 2,
        'pageSize': 50,
        'domain': 2,
        'keyPrefix': 'playback.',
      });
    });
  });

  group('ConfigGovernanceRemoteDataSourceImpl', () {
    late _RecordingAdapter adapter;
    late ConfigGovernanceRemoteDataSourceImpl dataSource;

    setUp(() {
      adapter = _RecordingAdapter();
      final dioClient = DioClient(localStorage: LocalStorageService());
      dioClient.dio.interceptors.clear();
      dioClient.dio.httpClientAdapter = adapter;
      dataSource = ConfigGovernanceRemoteDataSourceImpl(dioClient: dioClient);
    });

    test('uses session store route when store id is absent', () async {
      adapter.responsePayload = _paginationPayload();

      final result = await dataSource.getStoreConfig();

      expect(adapter.lastPath, '/api/cms/config/store');
      expect(adapter.lastQueryParameters, {
        'page': 1,
        'pageSize': 20,
      });
      expect(result.items.single.key, 'playback.baseVolume');
    });

    test('uses brand session route', () async {
      adapter.responsePayload = _paginationPayload();

      await dataSource.getBrandConfig(
        query: const ConfigQuery(domain: ConfigDomain.playback),
      );

      expect(adapter.lastPath, '/api/cms/config/brand');
      expect(adapter.lastQueryParameters, {
        'page': 1,
        'pageSize': 20,
        'domain': 2,
      });
    });

    test('uses selected store route and forwards query filters', () async {
      adapter.responsePayload = _paginationPayload();

      await dataSource.getStoreConfig(
        storeId: ' store-1 ',
        query: const ConfigQuery(
          page: 2,
          pageSize: 50,
          domain: ConfigDomain.cams,
          keyPrefix: 'cams.',
        ),
      );

      expect(adapter.lastPath, '/api/cms/config/store/store-1');
      expect(adapter.lastQueryParameters, {
        'page': 2,
        'pageSize': 50,
        'domain': 7,
        'keyPrefix': 'cams.',
      });
    });

    test('uses selected space route', () async {
      adapter.responsePayload = _paginationPayload();

      await dataSource.getSpaceConfig(spaceId: ' space-1 ');

      expect(adapter.lastPath, '/api/cms/config/space/space-1');
    });

    test('upserts store value on StoreManager session route', () async {
      adapter.responsePayload = _successPayload('Store config updated.');

      final message = await dataSource.upsertStoreValue(
        request: const ConfigValueUpsertRequest(
          key: 'playback.baseVolume',
          domain: ConfigDomain.playback,
          valueType: ConfigValueType.number,
          value: '65',
          storeOverrideIntent: StoreOverrideIntent.allowSpaceOverride,
          overrideReason: 'Enable pilot spaces',
          targetSpaceIds: [' space-1 ', '', 'space-2'],
        ),
      );

      expect(message, 'Store config updated.');
      expect(adapter.lastMethod, 'PUT');
      expect(adapter.lastPath, '/api/cms/config/store-value');
      expect(adapter.lastBody, {
        'key': 'playback.baseVolume',
        'domain': 2,
        'valueType': 2,
        'value': '65',
        'overrideIntent': 1,
        'overrideReason': 'Enable pilot spaces',
        'targetSpaceIds': ['space-1', 'space-2'],
      });
    });

    test('upserts brand value with selected child stores', () async {
      adapter.responsePayload = _successPayload('Brand config updated.');

      final message = await dataSource.upsertBrandValue(
        request: const ConfigValueUpsertRequest(
          key: 'playback.baseVolume',
          domain: ConfigDomain.playback,
          valueType: ConfigValueType.number,
          value: '70',
          brandOverrideIntent: BrandOverrideIntent.allowStoreOverride,
          overrideReason: 'Pilot rollout',
          targetStoreIds: [' store-1 ', '', 'store-2 '],
        ),
      );

      expect(message, 'Brand config updated.');
      expect(adapter.lastMethod, 'PUT');
      expect(adapter.lastPath, '/api/cms/config/brand-value');
      expect(adapter.lastBody, {
        'key': 'playback.baseVolume',
        'domain': 2,
        'valueType': 2,
        'value': '70',
        'overrideIntent': 1,
        'overrideReason': 'Pilot rollout',
        'targetStoreIds': ['store-1', 'store-2'],
      });
    });

    test('upserts selected store and selected space value routes', () async {
      adapter.responsePayload = _successPayload('Config updated.');

      await dataSource.upsertStoreValue(
        storeId: ' store-1 ',
        request: const ConfigValueUpsertRequest(
          key: 'cams.aiQueueTrackLimit',
          domain: ConfigDomain.cams,
          valueType: ConfigValueType.number,
          value: '12',
        ),
      );

      expect(adapter.lastPath, '/api/cms/config/store/store-1/value');

      await dataSource.upsertSpaceValue(
        spaceId: ' space-1 ',
        request: const ConfigValueUpsertRequest(
          key: 'playback.baseVolume',
          domain: ConfigDomain.playback,
          valueType: ConfigValueType.number,
          value: '60',
          spaceOverrideIntent: SpaceOverrideIntent.inheritFromStore,
        ),
      );

      expect(adapter.lastPath, '/api/cms/config/space/space-1/value');
      expect(adapter.lastBody, {
        'spaceId': 'space-1',
        'key': 'playback.baseVolume',
        'domain': 2,
        'valueType': 2,
        'value': '60',
        'overrideIntent': 1,
      });
    });

    test('patches governance mode for selected stores', () async {
      adapter.responsePayload = _successPayload('Governance mode updated.');

      final message = await dataSource.setStoreGovernanceMode(
        request: const SetStoreGovernanceModeRequest(
          storeIds: [' store-1 ', '', 'store-2'],
          mode: StoreGovernanceMode.aiMode,
          sourceId: ' source-template-1 ',
        ),
      );

      expect(message, 'Governance mode updated.');
      expect(adapter.lastMethod, 'PATCH');
      expect(adapter.lastPath, '/api/cms/config/stores/governance-mode');
      expect(adapter.lastBody, {
        'storeIds': ['store-1', 'store-2'],
        'mode': 2,
        'sourceId': 'source-template-1',
      });
    });
  });
}

Map<String, dynamic> _paginationPayload() {
  return {
    'isSuccess': true,
    'data': {
      'currentPage': 1,
      'pageSize': 20,
      'totalItems': 1,
      'totalPages': 1,
      'hasPrevious': false,
      'hasNext': false,
      'items': [
        {
          'key': 'playback.baseVolume',
          'domain': 2,
          'scopeType': 2,
          'scopeId': 'store-1',
          'valueType': 2,
          'value': '65',
          'policyTier': 1,
        },
      ],
    },
  };
}

Map<String, dynamic> _successPayload(String message) {
  return {
    'isSuccess': true,
    'message': message,
    'data': 'config-value-id',
  };
}

class _RecordingAdapter implements HttpClientAdapter {
  Map<String, dynamic> responsePayload = _paginationPayload();
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastQueryParameters;
  Map<String, dynamic>? lastBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastMethod = options.method;
    lastPath = options.path;
    lastQueryParameters = Map<String, dynamic>.from(options.queryParameters);
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
