import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/pagination_result.dart';
import '../entities/config_flat_row.dart';
import '../entities/config_query.dart';
import '../entities/config_value_upsert_request.dart';

abstract class ConfigGovernanceRepository {
  Future<Either<Failure, PaginationResult<ConfigFlatRow>>> getBrandConfig({
    ConfigQuery query = const ConfigQuery(),
  });

  Future<Either<Failure, PaginationResult<ConfigFlatRow>>> getStoreConfig({
    String? storeId,
    ConfigQuery query = const ConfigQuery(),
  });

  Future<Either<Failure, PaginationResult<ConfigFlatRow>>> getSpaceConfig({
    required String spaceId,
    ConfigQuery query = const ConfigQuery(),
  });

  Future<Either<Failure, String>> upsertStoreValue({
    String? storeId,
    required ConfigValueUpsertRequest request,
  });

  Future<Either<Failure, String>> upsertBrandValue({
    required ConfigValueUpsertRequest request,
  });

  Future<Either<Failure, String>> upsertSpaceValue({
    required String spaceId,
    required ConfigValueUpsertRequest request,
  });

  Future<Either<Failure, String>> setStoreGovernanceMode({
    required SetStoreGovernanceModeRequest request,
  });
}
