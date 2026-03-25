import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/pagination_result.dart';
import '../../data/datasources/location_remote_datasource.dart';
import '../entities/location_space.dart';

abstract class LocationRepository {
  /// Fetches a specific space by ID (used for Playback Device)
  Future<Either<Failure, LocationSpace>> getPairedSpace(
      String spaceId, String storeId);

  /// Fetches all spaces within a specific store (used for Store Manager)
  Future<Either<Failure, PaginationResult<LocationSpace>>> getSpacesForStore(
      String storeId,
      {int page = 1,
      int pageSize = 10});

  /// Fetches all spaces across multiple stores (used for Brand Manager)
  Future<Either<Failure, Map<String, PaginationResult<LocationSpace>>>>
      getSpacesForBrand(List<String> storeIds,
          {int page = 1, int pageSize = 10});

  Future<Either<Failure, SpaceMutationResult>> createSpace(
    SpaceMutationRequest request,
  );

  Future<Either<Failure, SpaceMutationResult>> updateSpace(
    String spaceId,
    SpaceMutationRequest request,
  );

  Future<Either<Failure, SpaceMutationResult>> deleteSpace(String spaceId);

  Future<Either<Failure, SpaceMutationResult>> toggleSpaceStatus(
    String spaceId,
  );
}
