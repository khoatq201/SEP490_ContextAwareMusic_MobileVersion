import 'package:equatable/equatable.dart';

import '../../../../core/models/pagination_result.dart';
import '../../domain/entities/config_flat_row.dart';
import '../../domain/entities/config_query.dart';

enum ConfigGovernanceStatus {
  initial,
  loading,
  loaded,
  loadingMore,
  saving,
  error,
}

enum ConfigGovernanceScope { brand, store, space }

class ConfigGovernanceState extends Equatable {
  final ConfigGovernanceStatus status;
  final ConfigGovernanceScope? scope;
  final String? scopeId;
  final ConfigQuery query;
  final List<ConfigFlatRow> rows;
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNext;
  final String? savingKey;
  final String? errorMessage;
  final String? successMessage;

  const ConfigGovernanceState({
    this.status = ConfigGovernanceStatus.initial,
    this.scope,
    this.scopeId,
    this.query = const ConfigQuery(pageSize: 50),
    this.rows = const [],
    this.currentPage = 1,
    this.pageSize = 50,
    this.totalItems = 0,
    this.totalPages = 0,
    this.hasNext = false,
    this.savingKey,
    this.errorMessage,
    this.successMessage,
  });

  bool get isInitialLoading =>
      status == ConfigGovernanceStatus.initial ||
      (status == ConfigGovernanceStatus.loading && rows.isEmpty);

  bool get isLoadingMore => status == ConfigGovernanceStatus.loadingMore;

  bool get isRefreshing =>
      status == ConfigGovernanceStatus.loading && rows.isNotEmpty;

  bool get isSaving => status == ConfigGovernanceStatus.saving;

  bool get canLoadMore =>
      hasNext &&
      status != ConfigGovernanceStatus.loading &&
      status != ConfigGovernanceStatus.loadingMore &&
      status != ConfigGovernanceStatus.saving;

  ConfigGovernanceState copyWith({
    ConfigGovernanceStatus? status,
    ConfigGovernanceScope? scope,
    String? scopeId,
    ConfigQuery? query,
    List<ConfigFlatRow>? rows,
    int? currentPage,
    int? pageSize,
    int? totalItems,
    int? totalPages,
    bool? hasNext,
    String? savingKey,
    String? errorMessage,
    String? successMessage,
    bool clearSavingKey = false,
    bool clearErrorMessage = false,
    bool clearSuccessMessage = false,
  }) {
    return ConfigGovernanceState(
      status: status ?? this.status,
      scope: scope ?? this.scope,
      scopeId: scopeId ?? this.scopeId,
      query: query ?? this.query,
      rows: rows ?? this.rows,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      totalItems: totalItems ?? this.totalItems,
      totalPages: totalPages ?? this.totalPages,
      hasNext: hasNext ?? this.hasNext,
      savingKey: clearSavingKey ? null : (savingKey ?? this.savingKey),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }

  ConfigGovernanceState withPage(
    PaginationResult<ConfigFlatRow> page, {
    required ConfigGovernanceScope scope,
    required String? scopeId,
    required ConfigQuery query,
    required bool append,
  }) {
    return copyWith(
      status: ConfigGovernanceStatus.loaded,
      scope: scope,
      scopeId: scopeId,
      query: query,
      rows: append ? [...rows, ...page.items] : page.items,
      currentPage: page.currentPage,
      pageSize: page.pageSize,
      totalItems: page.totalItems,
      totalPages: page.totalPages,
      hasNext: page.hasNext,
      clearSavingKey: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );
  }

  @override
  List<Object?> get props => [
        status,
        scope,
        scopeId,
        query,
        rows,
        currentPage,
        pageSize,
        totalItems,
        totalPages,
        hasNext,
        savingKey,
        errorMessage,
        successMessage,
      ];
}
