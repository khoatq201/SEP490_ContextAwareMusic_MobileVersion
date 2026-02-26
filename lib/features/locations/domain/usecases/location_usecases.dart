import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/location_space.dart';
import '../repositories/location_repository.dart';

class GetPairedSpace {
  final LocationRepository repository;

  GetPairedSpace(this.repository);

  Future<Either<Failure, LocationSpace>> call(String spaceId, String storeId) {
    return repository.getPairedSpace(spaceId, storeId);
  }
}

class GetSpacesForStore {
  final LocationRepository repository;

  GetSpacesForStore(this.repository);

  Future<Either<Failure, List<LocationSpace>>> call(String storeId) {
    return repository.getSpacesForStore(storeId);
  }
}

class GetSpacesForBrand {
  final LocationRepository repository;

  GetSpacesForBrand(this.repository);

  Future<Either<Failure, Map<String, List<LocationSpace>>>> call(List<String> storeIds) {
    return repository.getSpacesForBrand(storeIds);
  }
}
