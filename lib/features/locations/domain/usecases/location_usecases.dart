import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/pagination_result.dart';
import '../../data/datasources/location_remote_datasource.dart';
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

  Future<Either<Failure, PaginationResult<LocationSpace>>> call(String storeId,
      {int page = 1, int pageSize = 10}) {
    return repository.getSpacesForStore(storeId,
        page: page, pageSize: pageSize);
  }
}

class GetSpacesForBrand {
  final LocationRepository repository;

  GetSpacesForBrand(this.repository);

  Future<Either<Failure, Map<String, PaginationResult<LocationSpace>>>> call(
      List<String> storeIds,
      {int page = 1,
      int pageSize = 10}) {
    return repository.getSpacesForBrand(storeIds,
        page: page, pageSize: pageSize);
  }
}

class CreateSpace {
  final LocationRepository repository;

  CreateSpace(this.repository);

  Future<Either<Failure, SpaceMutationResult>> call(
    SpaceMutationRequest request,
  ) {
    return repository.createSpace(request);
  }
}

class UpdateSpace {
  final LocationRepository repository;

  UpdateSpace(this.repository);

  Future<Either<Failure, SpaceMutationResult>> call(
    String spaceId,
    SpaceMutationRequest request,
  ) {
    return repository.updateSpace(spaceId, request);
  }
}

class DeleteSpace {
  final LocationRepository repository;

  DeleteSpace(this.repository);

  Future<Either<Failure, SpaceMutationResult>> call(String spaceId) {
    return repository.deleteSpace(spaceId);
  }
}

class ToggleSpaceStatus {
  final LocationRepository repository;

  ToggleSpaceStatus(this.repository);

  Future<Either<Failure, SpaceMutationResult>> call(String spaceId) {
    return repository.toggleSpaceStatus(spaceId);
  }
}
