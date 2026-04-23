import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/error/failures.dart';
import 'package:cams_store_manager/core/models/pagination_result.dart';
import 'package:cams_store_manager/features/config_governance/domain/entities/config_flat_row.dart';
import 'package:cams_store_manager/features/config_governance/domain/entities/config_governance_enums.dart';
import 'package:cams_store_manager/features/config_governance/domain/entities/config_query.dart';
import 'package:cams_store_manager/features/config_governance/domain/entities/config_value_upsert_request.dart';
import 'package:cams_store_manager/features/config_governance/domain/repositories/config_governance_repository.dart';
import 'package:cams_store_manager/features/config_governance/domain/usecases/config_governance_usecases.dart';
import 'package:cams_store_manager/features/config_governance/presentation/bloc/config_governance_cubit.dart';
import 'package:cams_store_manager/features/config_governance/presentation/bloc/config_governance_state.dart';

void main() {
  group('ConfigGovernanceCubit', () {
    late _FakeConfigGovernanceRepository repository;
    late ConfigGovernanceCubit cubit;
    late List<ConfigGovernanceState> emitted;

    setUp(() {
      repository = _FakeConfigGovernanceRepository();
      cubit = ConfigGovernanceCubit(
        getBrandConfig: GetBrandConfig(repository),
        getStoreConfig: GetStoreConfig(repository),
        getSpaceConfig: GetSpaceConfig(repository),
        upsertBrandConfigValue: UpsertBrandConfigValue(repository),
        upsertStoreConfigValue: UpsertStoreConfigValue(repository),
        upsertSpaceConfigValue: UpsertSpaceConfigValue(repository),
        setStoreGovernanceMode: SetStoreGovernanceMode(repository),
      );
      emitted = [];
      cubit.stream.listen(emitted.add);
    });

    tearDown(() async {
      await cubit.close();
    });

    test('loadBrand emits loaded rows for brand scope', () async {
      repository.brandPages = [
        _page(
          items: [
            _row(
              'playback.baseVolume',
              scopeType: ConfigScopeType.brand,
            ),
          ],
          totalItems: 1,
        ),
      ];

      await cubit.loadBrand();
      await _flushStream();

      expect(
        emitted.map((state) => state.status),
        [
          ConfigGovernanceStatus.loading,
          ConfigGovernanceStatus.loaded,
        ],
      );
      expect(cubit.state.scope, ConfigGovernanceScope.brand);
      expect(cubit.state.rows.single.scopeType, ConfigScopeType.brand);
      expect(repository.lastBrandQuery?.pageSize, 50);
    });

    test('loadStore emits loaded rows for selected store scope', () async {
      repository.storePages = [
        _page(
          items: [_row('playback.baseVolume')],
          totalItems: 1,
        ),
      ];

      await cubit.loadStore(storeId: 'store-1');
      await _flushStream();

      expect(
        emitted.map((state) => state.status),
        [
          ConfigGovernanceStatus.loading,
          ConfigGovernanceStatus.loaded,
        ],
      );
      expect(cubit.state.scope, ConfigGovernanceScope.store);
      expect(cubit.state.scopeId, 'store-1');
      expect(cubit.state.rows.single.key, 'playback.baseVolume');
      expect(repository.lastStoreQuery?.pageSize, 50);
    });

    test('setDomain reloads first page with selected domain filter', () async {
      repository.storePages = [
        _page(items: [_row('playback.baseVolume')]),
        _page(items: [_row('fuzzy.energyBoost', domain: ConfigDomain.fuzzy)]),
      ];

      await cubit.loadStore(storeId: 'store-1');
      await cubit.setDomain(ConfigDomain.fuzzy);
      await _flushStream();

      expect(cubit.state.query.domain, ConfigDomain.fuzzy);
      expect(cubit.state.query.page, 1);
      expect(cubit.state.rows.single.key, 'fuzzy.energyBoost');
      expect(repository.storeQueries.last.domain, ConfigDomain.fuzzy);
    });

    test('loadNextPage appends rows when backend has another page', () async {
      repository.storePages = [
        _page(
          items: [_row('playback.baseVolume')],
          currentPage: 1,
          totalItems: 2,
          totalPages: 2,
          hasNext: true,
        ),
        _page(
          items: [_row('playback.maxVolume')],
          currentPage: 2,
          totalItems: 2,
          totalPages: 2,
        ),
      ];

      await cubit.loadStore(storeId: 'store-1');
      await cubit.loadNextPage();
      await _flushStream();

      expect(cubit.state.rows.map((row) => row.key), [
        'playback.baseVolume',
        'playback.maxVolume',
      ]);
      expect(repository.storeQueries.last.page, 2);
    });

    test('upsertValue saves store value and refreshes config', () async {
      repository.storePages = [
        _page(items: [_row('playback.baseVolume')]),
        _page(
          items: [
            _row('playback.baseVolume', value: '66'),
          ],
        ),
      ];

      await cubit.loadStore(storeId: 'store-1');
      await cubit.upsertValue(
        row: cubit.state.rows.single,
        valueType: ConfigValueType.number,
        value: '66',
      );
      await _flushStream();

      expect(repository.lastStoreUpsertRequest?.key, 'playback.baseVolume');
      expect(repository.lastStoreUpsertRequest?.value, '66');
      expect(
        repository.lastStoreUpsertRequest?.storeOverrideIntent,
        StoreOverrideIntent.none,
      );
      expect(cubit.state.rows.single.value, '66');
      expect(
        emitted.any(
          (state) =>
              state.isRefreshing &&
              state.rows.length == 1 &&
              state.rows.single.value == '66',
        ),
        isTrue,
      );
    });

    test('upsertValue forwards selected store override intent', () async {
      repository.storePages = [
        _page(items: [_row('playback.baseVolume')]),
        _page(items: [_row('playback.baseVolume', value: '70')]),
      ];

      await cubit.loadStore(storeId: 'store-1');
      await cubit.upsertValue(
        row: cubit.state.rows.single,
        valueType: ConfigValueType.number,
        value: '70',
        storeOverrideIntent: StoreOverrideIntent.forceInheritToAllSpaces,
        overrideReason: 'Campaign reset',
        targetSpaceIds: const ['space-1', 'space-2'],
      );
      await _flushStream();

      expect(
        repository.lastStoreUpsertRequest?.storeOverrideIntent,
        StoreOverrideIntent.forceInheritToAllSpaces,
      );
      expect(
        repository.lastStoreUpsertRequest?.overrideReason,
        'Campaign reset',
      );
      expect(repository.lastStoreUpsertRequest?.targetSpaceIds, [
        'space-1',
        'space-2',
      ]);
    });

    test('upsertValue forwards selected brand override intent', () async {
      repository.brandPages = [
        _page(
          items: [
            _row(
              'playback.baseVolume',
              scopeType: ConfigScopeType.brand,
            ),
          ],
        ),
        _page(
          items: [
            _row(
              'playback.baseVolume',
              scopeType: ConfigScopeType.brand,
              value: '68',
            ),
          ],
        ),
      ];

      await cubit.loadBrand();
      await cubit.upsertValue(
        row: cubit.state.rows.single,
        valueType: ConfigValueType.number,
        value: '68',
        brandOverrideIntent: BrandOverrideIntent.allowStoreOverride,
        overrideReason: 'Pilot stores',
        targetStoreIds: const ['store-1', 'store-2'],
      );
      await _flushStream();

      expect(
        repository.lastBrandUpsertRequest?.brandOverrideIntent,
        BrandOverrideIntent.allowStoreOverride,
      );
      expect(repository.lastBrandUpsertRequest?.targetStoreIds, [
        'store-1',
        'store-2',
      ]);
      expect(
        repository.lastBrandUpsertRequest?.overrideReason,
        'Pilot stores',
      );
    });

    test('inheritFromStore forwards space inherit intent', () async {
      repository.spacePages = [
        _page(
          items: [
            _row(
              'playback.baseVolume',
              scopeType: ConfigScopeType.space,
              value: '55',
            ),
          ],
        ),
        _page(
          items: [
            _row(
              'playback.baseVolume',
              scopeType: ConfigScopeType.space,
              value: '55',
            ),
          ],
        ),
      ];

      await cubit.loadSpace(spaceId: 'space-1');
      await cubit.inheritFromStore(row: cubit.state.rows.single);
      await _flushStream();

      expect(
        repository.lastSpaceUpsertRequest?.spaceOverrideIntent,
        SpaceOverrideIntent.inheritFromStore,
      );
      expect(repository.lastSpaceId, 'space-1');
    });

    test('setGovernanceMode uses dedicated endpoint and refreshes config',
        () async {
      repository.storePages = [
        _page(
          items: [
            _row(
              'governance.mode',
              domain: ConfigDomain.governance,
              value: '3',
            ),
          ],
        ),
        _page(
          items: [
            _row(
              'governance.mode',
              domain: ConfigDomain.governance,
              value: '1',
            ),
          ],
        ),
      ];

      await cubit.loadStore(storeId: 'store-1');
      await cubit.setGovernanceMode(
        storeId: 'store-1',
        mode: StoreGovernanceMode.strictSync,
      );
      await _flushStream();

      expect(repository.lastStoreUpsertRequest, isNull);
      expect(
        repository.lastGovernanceModeRequest,
        const SetStoreGovernanceModeRequest(
          storeIds: ['store-1'],
          mode: StoreGovernanceMode.strictSync,
        ),
      );
      expect(cubit.state.rows.single.value, '1');
    });

    test('upsertValue blocks space write for space-blocked domains', () async {
      repository.spacePages = [
        _page(
          items: [
            _row(
              'scheduling.slots',
              domain: ConfigDomain.scheduling,
              scopeType: ConfigScopeType.space,
            ),
          ],
        ),
      ];

      await cubit.loadSpace(spaceId: 'space-1');
      await cubit.upsertValue(
        row: cubit.state.rows.single,
        valueType: ConfigValueType.string,
        value: '[]',
      );
      await _flushStream();

      expect(repository.lastSpaceUpsertRequest, isNull);
      expect(
        cubit.state.errorMessage,
        'This key cannot be edited at space scope.',
      );
    });
  });
}

Future<void> _flushStream() => Future<void>.delayed(Duration.zero);

ConfigFlatRow _row(
  String key, {
  ConfigDomain domain = ConfigDomain.playback,
  ConfigScopeType scopeType = ConfigScopeType.store,
  String value = '60',
}) {
  return ConfigFlatRow(
    key: key,
    domain: domain,
    scopeType: scopeType,
    valueType: ConfigValueType.number,
    value: value,
    policyTier: ConfigTier.tenant,
    allowStoreOverride: true,
    allowSpaceOverride: true,
  );
}

PaginationResult<ConfigFlatRow> _page({
  required List<ConfigFlatRow> items,
  int currentPage = 1,
  int pageSize = 50,
  int? totalItems,
  int totalPages = 1,
  bool hasNext = false,
}) {
  return PaginationResult<ConfigFlatRow>(
    currentPage: currentPage,
    pageSize: pageSize,
    totalItems: totalItems ?? items.length,
    totalPages: totalPages,
    hasPrevious: currentPage > 1,
    hasNext: hasNext,
    items: items,
  );
}

class _FakeConfigGovernanceRepository implements ConfigGovernanceRepository {
  List<PaginationResult<ConfigFlatRow>> brandPages = [_page(items: const [])];
  List<PaginationResult<ConfigFlatRow>> storePages = [_page(items: const [])];
  List<PaginationResult<ConfigFlatRow>> spacePages = [_page(items: const [])];
  final brandQueries = <ConfigQuery>[];
  final storeQueries = <ConfigQuery>[];
  final spaceQueries = <ConfigQuery>[];
  String? lastStoreId;
  String? lastSpaceId;
  ConfigValueUpsertRequest? lastBrandUpsertRequest;
  ConfigValueUpsertRequest? lastStoreUpsertRequest;
  ConfigValueUpsertRequest? lastSpaceUpsertRequest;
  SetStoreGovernanceModeRequest? lastGovernanceModeRequest;

  ConfigQuery? get lastBrandQuery =>
      brandQueries.isEmpty ? null : brandQueries.last;

  ConfigQuery? get lastStoreQuery =>
      storeQueries.isEmpty ? null : storeQueries.last;

  @override
  Future<Either<Failure, PaginationResult<ConfigFlatRow>>> getBrandConfig({
    ConfigQuery query = const ConfigQuery(),
  }) async {
    brandQueries.add(query);
    return Right(brandPages.removeAt(0));
  }

  @override
  Future<Either<Failure, PaginationResult<ConfigFlatRow>>> getStoreConfig({
    String? storeId,
    ConfigQuery query = const ConfigQuery(),
  }) async {
    lastStoreId = storeId;
    storeQueries.add(query);
    return Right(storePages.removeAt(0));
  }

  @override
  Future<Either<Failure, PaginationResult<ConfigFlatRow>>> getSpaceConfig({
    required String spaceId,
    ConfigQuery query = const ConfigQuery(),
  }) async {
    lastSpaceId = spaceId;
    spaceQueries.add(query);
    return Right(spacePages.removeAt(0));
  }

  @override
  Future<Either<Failure, String>> upsertBrandValue({
    required ConfigValueUpsertRequest request,
  }) async {
    lastBrandUpsertRequest = request;
    return const Right('Brand config value updated.');
  }

  @override
  Future<Either<Failure, String>> upsertStoreValue({
    String? storeId,
    required ConfigValueUpsertRequest request,
  }) async {
    lastStoreId = storeId;
    lastStoreUpsertRequest = request;
    return const Right('Store config value updated.');
  }

  @override
  Future<Either<Failure, String>> upsertSpaceValue({
    required String spaceId,
    required ConfigValueUpsertRequest request,
  }) async {
    lastSpaceId = spaceId;
    lastSpaceUpsertRequest = request;
    return const Right('Space config value updated.');
  }

  @override
  Future<Either<Failure, String>> setStoreGovernanceMode({
    required SetStoreGovernanceModeRequest request,
  }) async {
    lastGovernanceModeRequest = request;
    return const Right('Store governance mode updated.');
  }
}
