import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/location_space.dart';

abstract class LocationRepository {
  /// Fetches a specific space by ID (used for Playback Device)
  Future<Either<Failure, LocationSpace>> getPairedSpace(String spaceId, String storeId);

  /// Fetches all spaces within a specific store (used for Store Manager)
  Future<Either<Failure, List<LocationSpace>>> getSpacesForStore(String storeId);

  /// Fetches all spaces across multiple stores (used for Brand Manager)
  Future<Either<Failure, Map<String, List<LocationSpace>>>> getSpacesForBrand(List<String> storeIds);
}
