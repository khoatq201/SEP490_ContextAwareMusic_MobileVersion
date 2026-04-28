import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/error_mapper.dart';
import '../../domain/entities/config_flat_row.dart';
import '../../domain/entities/config_governance_enums.dart';
import '../../domain/entities/config_key_metadata.dart';
import '../../domain/entities/config_query.dart';
import '../../domain/entities/config_value_upsert_request.dart';
import '../../domain/usecases/config_governance_usecases.dart';
import 'config_governance_state.dart';

class ConfigGovernanceCubit extends Cubit<ConfigGovernanceState> {
  final GetBrandConfig _getBrandConfig;
  final GetStoreConfig _getStoreConfig;
  final GetSpaceConfig _getSpaceConfig;
  final UpsertBrandConfigValue _upsertBrandConfigValue;
  final UpsertStoreConfigValue _upsertStoreConfigValue;
  final UpsertSpaceConfigValue _upsertSpaceConfigValue;
  final SetStoreGovernanceMode _setStoreGovernanceMode;

  ConfigGovernanceCubit({
    required GetBrandConfig getBrandConfig,
    required GetStoreConfig getStoreConfig,
    required GetSpaceConfig getSpaceConfig,
    required UpsertBrandConfigValue upsertBrandConfigValue,
    required UpsertStoreConfigValue upsertStoreConfigValue,
    required UpsertSpaceConfigValue upsertSpaceConfigValue,
    required SetStoreGovernanceMode setStoreGovernanceMode,
  })  : _getBrandConfig = getBrandConfig,
        _getStoreConfig = getStoreConfig,
        _getSpaceConfig = getSpaceConfig,
        _upsertBrandConfigValue = upsertBrandConfigValue,
        _upsertStoreConfigValue = upsertStoreConfigValue,
        _upsertSpaceConfigValue = upsertSpaceConfigValue,
        _setStoreGovernanceMode = setStoreGovernanceMode,
        super(const ConfigGovernanceState());

  Future<void> loadBrand({
    ConfigQuery query = const ConfigQuery(pageSize: 50),
  }) {
    return _load(
      scope: ConfigGovernanceScope.brand,
      scopeId: null,
      query: query,
      append: false,
    );
  }

  Future<void> loadStore({
    String? storeId,
    ConfigQuery query = const ConfigQuery(pageSize: 50),
  }) {
    return _load(
      scope: ConfigGovernanceScope.store,
      scopeId: storeId,
      query: query,
      append: false,
    );
  }

  Future<void> loadSpace({
    required String spaceId,
    ConfigQuery query = const ConfigQuery(pageSize: 50),
  }) {
    return _load(
      scope: ConfigGovernanceScope.space,
      scopeId: spaceId,
      query: query,
      append: false,
    );
  }

  Future<void> refresh({bool keepRows = false}) {
    final scope = state.scope;
    if (scope == null) return Future.value();

    return _load(
      scope: scope,
      scopeId: state.scopeId,
      query: ConfigQuery(
        page: 1,
        pageSize: state.query.pageSize,
        domain: state.query.domain,
        keyPrefix: state.query.keyPrefix,
      ),
      append: false,
      keepRows: keepRows,
    );
  }

  Future<void> setDomain(ConfigDomain? domain) {
    final scope = state.scope;
    if (scope == null) return Future.value();

    return _load(
      scope: scope,
      scopeId: state.scopeId,
      query: ConfigQuery(
        page: 1,
        pageSize: state.query.pageSize,
        domain: domain == ConfigDomain.unknown ? null : domain,
        keyPrefix: state.query.keyPrefix,
      ),
      append: false,
    );
  }

  Future<void> setKeyPrefix(String? keyPrefix) {
    final scope = state.scope;
    if (scope == null) return Future.value();
    final normalized = keyPrefix?.trim();

    return _load(
      scope: scope,
      scopeId: state.scopeId,
      query: ConfigQuery(
        page: 1,
        pageSize: state.query.pageSize,
        domain: state.query.domain,
        keyPrefix: normalized == null || normalized.isEmpty ? null : normalized,
      ),
      append: false,
    );
  }

  Future<void> loadNextPage() {
    if (!state.canLoadMore) return Future.value();
    final scope = state.scope;
    if (scope == null) return Future.value();

    return _load(
      scope: scope,
      scopeId: state.scopeId,
      query: ConfigQuery(
        page: state.currentPage + 1,
        pageSize: state.query.pageSize,
        domain: state.query.domain,
        keyPrefix: state.query.keyPrefix,
      ),
      append: true,
    );
  }

  Future<void> upsertValue({
    required ConfigFlatRow row,
    required ConfigValueType valueType,
    required String value,
    BrandOverrideIntent? brandOverrideIntent,
    StoreOverrideIntent? storeOverrideIntent,
    SpaceOverrideIntent? spaceOverrideIntent,
    String? overrideReason,
    List<String>? targetStoreIds,
    List<String>? targetSpaceIds,
  }) async {
    final scope = state.scope;
    if (scope == null) {
      emit(
        state.copyWith(
          status: ConfigGovernanceStatus.error,
          errorMessage: 'Config scope is unavailable.',
          clearSuccessMessage: true,
        ),
      );
      return;
    }

    final blockReason = _editBlockReason(row, scope);
    if (blockReason != null) {
      emit(
        state.copyWith(
          status: ConfigGovernanceStatus.loaded,
          errorMessage: blockReason,
          clearSuccessMessage: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ConfigGovernanceStatus.saving,
        savingKey: row.key,
        clearErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final request = ConfigValueUpsertRequest(
      key: row.key,
      domain: row.domain,
      valueType: valueType,
      value: value,
      brandOverrideIntent: scope == ConfigGovernanceScope.brand
          ? (brandOverrideIntent ?? BrandOverrideIntent.none)
          : null,
      storeOverrideIntent: scope == ConfigGovernanceScope.store
          ? (storeOverrideIntent ?? StoreOverrideIntent.none)
          : null,
      spaceOverrideIntent: scope == ConfigGovernanceScope.space
          ? (spaceOverrideIntent ?? SpaceOverrideIntent.overrideAtSpace)
          : null,
      overrideReason: overrideReason,
      targetStoreIds:
          scope == ConfigGovernanceScope.brand ? targetStoreIds : null,
      targetSpaceIds:
          scope == ConfigGovernanceScope.store ? targetSpaceIds : null,
    );

    final result = await switch (scope) {
      ConfigGovernanceScope.brand =>
        _upsertBrandConfigValue(request: request),
      ConfigGovernanceScope.store => _upsertStoreConfigValue(
          storeId: state.scopeId,
          request: request,
        ),
      ConfigGovernanceScope.space => _upsertSpaceConfigValue(
          spaceId: state.scopeId ?? '',
          request: request,
        ),
    };

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: state.rows.isEmpty
                ? ConfigGovernanceStatus.error
                : ConfigGovernanceStatus.loaded,
            errorMessage: ErrorMapper.displayMessageForFailure(failure),
            clearSavingKey: true,
            clearSuccessMessage: true,
          ),
        );
      },
      (message) async {
        final optimisticRows = _applySavedValue(
          row: row,
          valueType: valueType,
          value: value,
        );
        emit(
          state.copyWith(
            status: ConfigGovernanceStatus.loaded,
            rows: optimisticRows,
            successMessage: message,
            clearSavingKey: true,
            clearErrorMessage: true,
          ),
        );
        await refresh(keepRows: true);
      },
    );
  }

  Future<void> inheritFromStore({
    required ConfigFlatRow row,
  }) async {
    if (state.scope != ConfigGovernanceScope.space) {
      return;
    }

    final currentValue = row.value?.trim();
    if (currentValue == null || currentValue.isEmpty) {
      emit(
        state.copyWith(
          status: ConfigGovernanceStatus.loaded,
          errorMessage: 'Only existing space overrides can inherit from store.',
          clearSuccessMessage: true,
        ),
      );
      return;
    }

    await upsertValue(
      row: row,
      valueType: row.valueType,
      value: currentValue,
      spaceOverrideIntent: SpaceOverrideIntent.inheritFromStore,
    );
  }

  Future<void> setGovernanceMode({
    required String storeId,
    required StoreGovernanceMode mode,
  }) async {
    emit(
      state.copyWith(
        status: ConfigGovernanceStatus.saving,
        savingKey: 'governance.mode',
        clearErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final result = await _setStoreGovernanceMode(
      request: SetStoreGovernanceModeRequest(
        storeIds: [storeId],
        mode: mode,
      ),
    );

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: state.rows.isEmpty
                ? ConfigGovernanceStatus.error
                : ConfigGovernanceStatus.loaded,
            errorMessage: ErrorMapper.displayMessageForFailure(failure),
            clearSavingKey: true,
            clearSuccessMessage: true,
          ),
        );
      },
      (message) async {
        emit(
          state.copyWith(
            status: ConfigGovernanceStatus.loaded,
            rows: _applyGovernanceMode(mode),
            successMessage: message,
            clearSavingKey: true,
            clearErrorMessage: true,
          ),
        );
        await refresh(keepRows: true);
      },
    );
  }

  Future<void> _load({
    required ConfigGovernanceScope scope,
    required String? scopeId,
    required ConfigQuery query,
    required bool append,
    bool keepRows = false,
  }) async {
    emit(
      state.copyWith(
        status: append
            ? ConfigGovernanceStatus.loadingMore
            : ConfigGovernanceStatus.loading,
        scope: scope,
        scopeId: scopeId,
        query: query,
        rows: append || keepRows ? state.rows : const [],
        clearErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final result = await switch (scope) {
      ConfigGovernanceScope.brand => _getBrandConfig(query: query),
      ConfigGovernanceScope.store =>
        _getStoreConfig(storeId: scopeId, query: query),
      ConfigGovernanceScope.space =>
        _getSpaceConfig(spaceId: scopeId ?? '', query: query),
    };

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: append && state.rows.isNotEmpty
                ? ConfigGovernanceStatus.loaded
                : ConfigGovernanceStatus.error,
            errorMessage: ErrorMapper.displayMessageForFailure(failure),
            clearSavingKey: true,
            clearSuccessMessage: true,
          ),
        );
      },
      (page) {
        emit(
          state.withPage(
            page,
            scope: scope,
            scopeId: scopeId,
            query: query,
            append: append,
          ),
        );
      },
    );
  }

  String? _editBlockReason(
    ConfigFlatRow row,
    ConfigGovernanceScope scope,
  ) {
    if (row.policyTier == ConfigTier.system) {
      return 'System-tier config cannot be edited here.';
    }

    if (scope == ConfigGovernanceScope.brand) {
      if (isConfigKeyBrandBlocked(row.key)) {
        return 'This key cannot be edited at brand scope.';
      }
      return null;
    }

    if (scope == ConfigGovernanceScope.store) {
      if (isConfigKeyStoreBlocked(row.key)) {
        return 'Use the dedicated governance mode action for this key.';
      }
      if (!row.isStoreOverrideAllowed) {
        return row.brandLockReason?.trim().isNotEmpty == true
            ? row.brandLockReason
            : 'Brand governance has not allowed store override for this key.';
      }
      return null;
    }

    if (_isSpaceWriteBlocked(row)) {
      return 'This key cannot be edited at space scope.';
    }
    if (!row.isSpaceOverrideAllowed) {
      return row.brandLockReason?.trim().isNotEmpty == true
          ? row.brandLockReason
          : 'Brand governance has not allowed space override for this key.';
    }

    return null;
  }

  bool _isSpaceWriteBlocked(ConfigFlatRow row) {
    return isConfigKeySpaceBlocked(row.key, row.domain);
  }

  List<ConfigFlatRow> _applySavedValue({
    required ConfigFlatRow row,
    required ConfigValueType valueType,
    required String value,
  }) {
    return state.rows
        .map(
          (candidate) => candidate.key == row.key &&
                  candidate.domain == row.domain &&
                  candidate.scopeType == row.scopeType
              ? candidate.copyWith(valueType: valueType, value: value)
              : candidate,
        )
        .toList(growable: false);
  }

  List<ConfigFlatRow> _applyGovernanceMode(StoreGovernanceMode mode) {
    return state.rows
        .map(
          (row) => row.key == 'governance.mode'
              ? row.copyWith(
                  valueType: ConfigValueType.number,
                  value: mode.value.toString(),
                )
              : row,
        )
        .toList(growable: false);
  }
}
