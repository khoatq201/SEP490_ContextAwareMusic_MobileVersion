import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/pagination_result.dart';
import '../entities/config_flat_row.dart';
import '../entities/config_query.dart';
import '../entities/config_value_upsert_request.dart';
import '../repositories/config_governance_repository.dart';

class GetStoreConfig {
  final ConfigGovernanceRepository repository;

  GetStoreConfig(this.repository);

  Future<Either<Failure, PaginationResult<ConfigFlatRow>>> call({
    String? storeId,
    ConfigQuery query = const ConfigQuery(),
  }) {
    return repository.getStoreConfig(storeId: storeId, query: query);
  }
}

class GetBrandConfig {
  final ConfigGovernanceRepository repository;

  GetBrandConfig(this.repository);

  Future<Either<Failure, PaginationResult<ConfigFlatRow>>> call({
    ConfigQuery query = const ConfigQuery(),
  }) {
    return repository.getBrandConfig(query: query);
  }
}

class GetSpaceConfig {
  final ConfigGovernanceRepository repository;

  GetSpaceConfig(this.repository);

  Future<Either<Failure, PaginationResult<ConfigFlatRow>>> call({
    required String spaceId,
    ConfigQuery query = const ConfigQuery(),
  }) {
    return repository.getSpaceConfig(spaceId: spaceId, query: query);
  }
}

class UpsertStoreConfigValue {
  final ConfigGovernanceRepository repository;

  UpsertStoreConfigValue(this.repository);

  Future<Either<Failure, String>> call({
    String? storeId,
    required ConfigValueUpsertRequest request,
  }) {
    return repository.upsertStoreValue(storeId: storeId, request: request);
  }
}

class UpsertBrandConfigValue {
  final ConfigGovernanceRepository repository;

  UpsertBrandConfigValue(this.repository);

  Future<Either<Failure, String>> call({
    required ConfigValueUpsertRequest request,
  }) {
    return repository.upsertBrandValue(request: request);
  }
}

class UpsertSpaceConfigValue {
  final ConfigGovernanceRepository repository;

  UpsertSpaceConfigValue(this.repository);

  Future<Either<Failure, String>> call({
    required String spaceId,
    required ConfigValueUpsertRequest request,
  }) {
    return repository.upsertSpaceValue(spaceId: spaceId, request: request);
  }
}

class SetStoreGovernanceMode {
  final ConfigGovernanceRepository repository;

  SetStoreGovernanceMode(this.repository);

  Future<Either<Failure, String>> call({
    required SetStoreGovernanceModeRequest request,
  }) {
    return repository.setStoreGovernanceMode(request: request);
  }
}

class PublishConfigVersion {
  final ConfigGovernanceRepository repository;

  PublishConfigVersion(this.repository);

  Future<Either<Failure, String>> call({
    required PublishConfigVersionRequest request,
  }) {
    return repository.publishConfigVersion(request: request);
  }
}

class RollbackConfigVersion {
  final ConfigGovernanceRepository repository;

  RollbackConfigVersion(this.repository);

  Future<Either<Failure, String>> call({
    required RollbackConfigVersionRequest request,
  }) {
    return repository.rollbackConfigVersion(request: request);
  }
}
