import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/error/exceptions.dart';
import 'package:cams_store_manager/core/error/failures.dart';
import 'package:cams_store_manager/core/models/pagination_result.dart';
import 'package:cams_store_manager/features/config_governance/data/datasources/config_governance_remote_datasource.dart';
import 'package:cams_store_manager/features/config_governance/data/models/config_flat_row_model.dart';
import 'package:cams_store_manager/features/config_governance/data/repositories/config_governance_repository_impl.dart';
import 'package:cams_store_manager/features/config_governance/domain/entities/config_governance_enums.dart';
import 'package:cams_store_manager/features/config_governance/domain/entities/config_query.dart';
import 'package:cams_store_manager/features/config_governance/domain/entities/config_value_upsert_request.dart';

void main() {
  group('ConfigGovernanceRepositoryImpl', () {
    late _FakeConfigGovernanceRemoteDataSource remoteDataSource;
    late ConfigGovernanceRepositoryImpl repository;

    setUp(() {
      remoteDataSource = _FakeConfigGovernanceRemoteDataSource();
      repository = ConfigGovernanceRepositoryImpl(
        remoteDataSource: remoteDataSource,
      );
    });

    test('getBrandConfig forwards success from datasource', () async {
      remoteDataSource.brandResult = _page(const [
        ConfigFlatRowModel(
          key: 'playback.baseVolume',
          domain: ConfigDomain.playback,
          scopeType: ConfigScopeType.brand,
          valueType: ConfigValueType.number,
          value: '65',
          policyTier: ConfigTier.tenant,
        ),
      ]);

      final result = await repository.getBrandConfig(
        query: const ConfigQuery(domain: ConfigDomain.playback),
      );

      expect(result, isA<Right<Failure, PaginationResult>>());
      result.fold(
        (_) => fail('Expected success'),
        (page) {
          expect(page.items, hasLength(1));
          expect(page.items.first.scopeType, ConfigScopeType.brand);
        },
      );
      expect(remoteDataSource.lastBrandQuery?.domain, ConfigDomain.playback);
    });

    test('getStoreConfig forwards success from datasource', () async {
      remoteDataSource.storeResult = _page(const [
        ConfigFlatRowModel(
          key: 'playback.baseVolume',
          domain: ConfigDomain.playback,
          scopeType: ConfigScopeType.store,
          valueType: ConfigValueType.number,
          value: '65',
          policyTier: ConfigTier.tenant,
        ),
      ]);

      final result = await repository.getStoreConfig(
        storeId: 'store-1',
        query: const ConfigQuery(domain: ConfigDomain.playback),
      );

      expect(result, isA<Right<Failure, PaginationResult>>());
      result.fold(
        (_) => fail('Expected success'),
        (page) {
          expect(page.items, hasLength(1));
          expect(page.items.first.key, 'playback.baseVolume');
        },
      );
      expect(remoteDataSource.lastStoreId, 'store-1');
      expect(remoteDataSource.lastStoreQuery?.domain, ConfigDomain.playback);
    });

    test('getSpaceConfig maps ServerException to ServerFailure', () async {
      remoteDataSource.spaceError = const ServerException('Config locked');

      final result = await repository.getSpaceConfig(spaceId: 'space-1');

      expect(result, isA<Left<Failure, PaginationResult>>());
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Config locked');
        },
        (_) => fail('Expected failure'),
      );
    });

    test('upsertStoreValue forwards request to datasource', () async {
      const request = ConfigValueUpsertRequest(
        key: 'playback.baseVolume',
        domain: ConfigDomain.playback,
        valueType: ConfigValueType.number,
        value: '65',
        storeOverrideIntent: StoreOverrideIntent.none,
      );

      final result = await repository.upsertStoreValue(
        storeId: 'store-1',
        request: request,
      );

      expect(result, isA<Right<Failure, String>>());
      result.fold(
        (_) => fail('Expected success'),
        (message) => expect(message, 'Store config value updated.'),
      );
      expect(remoteDataSource.lastStoreId, 'store-1');
      expect(remoteDataSource.lastStoreUpsertRequest, request);
    });

    test('setStoreGovernanceMode forwards request to datasource', () async {
      const request = SetStoreGovernanceModeRequest(
        storeIds: ['store-1'],
        mode: StoreGovernanceMode.strictSync,
      );

      final result = await repository.setStoreGovernanceMode(request: request);

      expect(result, isA<Right<Failure, String>>());
      result.fold(
        (_) => fail('Expected success'),
        (message) => expect(message, 'Store governance mode updated.'),
      );
      expect(remoteDataSource.lastGovernanceModeRequest, request);
    });
  });
}

PaginationResult<ConfigFlatRowModel> _page(
  List<ConfigFlatRowModel> items,
) {
  return PaginationResult<ConfigFlatRowModel>(
    currentPage: 1,
    pageSize: 20,
    totalItems: items.length,
    totalPages: 1,
    hasPrevious: false,
    hasNext: false,
    items: items,
  );
}

class _FakeConfigGovernanceRemoteDataSource
    implements ConfigGovernanceRemoteDataSource {
  PaginationResult<ConfigFlatRowModel> brandResult = _page(const []);
  PaginationResult<ConfigFlatRowModel> storeResult = _page(const []);
  PaginationResult<ConfigFlatRowModel> spaceResult = _page(const []);
  Exception? brandError;
  Exception? storeError;
  Exception? spaceError;
  Exception? brandUpsertError;
  Exception? storeUpsertError;
  Exception? spaceUpsertError;
  String? lastBrandId;
  String? lastStoreId;
  String? lastSpaceId;
  ConfigQuery? lastBrandQuery;
  ConfigQuery? lastStoreQuery;
  ConfigQuery? lastSpaceQuery;
  ConfigValueUpsertRequest? lastBrandUpsertRequest;
  ConfigValueUpsertRequest? lastStoreUpsertRequest;
  ConfigValueUpsertRequest? lastSpaceUpsertRequest;
  SetStoreGovernanceModeRequest? lastGovernanceModeRequest;
  PublishConfigVersionRequest? lastPublishConfigVersionRequest;
  RollbackConfigVersionRequest? lastRollbackConfigVersionRequest;

  @override
  Future<PaginationResult<ConfigFlatRowModel>> getBrandConfig({
    ConfigQuery query = const ConfigQuery(),
  }) async {
    lastBrandQuery = query;
    if (brandError != null) throw brandError!;
    return brandResult;
  }

  @override
  Future<PaginationResult<ConfigFlatRowModel>> getStoreConfig({
    String? storeId,
    ConfigQuery query = const ConfigQuery(),
  }) async {
    lastStoreId = storeId;
    lastStoreQuery = query;
    if (storeError != null) throw storeError!;
    return storeResult;
  }

  @override
  Future<PaginationResult<ConfigFlatRowModel>> getSpaceConfig({
    required String spaceId,
    ConfigQuery query = const ConfigQuery(),
  }) async {
    lastSpaceId = spaceId;
    lastSpaceQuery = query;
    if (spaceError != null) throw spaceError!;
    return spaceResult;
  }

  @override
  Future<String> upsertBrandValue({
    required ConfigValueUpsertRequest request,
  }) async {
    lastBrandUpsertRequest = request;
    if (brandUpsertError != null) throw brandUpsertError!;
    return 'Brand config value updated.';
  }

  @override
  Future<String> upsertStoreValue({
    String? storeId,
    required ConfigValueUpsertRequest request,
  }) async {
    lastStoreId = storeId;
    lastStoreUpsertRequest = request;
    if (storeUpsertError != null) throw storeUpsertError!;
    return 'Store config value updated.';
  }

  @override
  Future<String> upsertSpaceValue({
    required String spaceId,
    required ConfigValueUpsertRequest request,
  }) async {
    lastSpaceId = spaceId;
    lastSpaceUpsertRequest = request;
    if (spaceUpsertError != null) throw spaceUpsertError!;
    return 'Space config value updated.';
  }

  @override
  Future<String> setStoreGovernanceMode({
    required SetStoreGovernanceModeRequest request,
  }) async {
    lastGovernanceModeRequest = request;
    return 'Store governance mode updated.';
  }

  @override
  Future<String> publishConfigVersion({
    required PublishConfigVersionRequest request,
  }) async {
    lastPublishConfigVersionRequest = request;
    return 'Config version published.';
  }

  @override
  Future<String> rollbackConfigVersion({
    required RollbackConfigVersionRequest request,
  }) async {
    lastRollbackConfigVersionRequest = request;
    return 'Config version rolled back.';
  }
}
