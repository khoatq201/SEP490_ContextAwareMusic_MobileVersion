import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../music_policy/data/models/fuzzy_override_profile_request.dart';
import '../../data/datasources/store_remote_datasource.dart';
import '../repositories/store_repository.dart';

class CreateStore {
  final StoreRepository repository;

  CreateStore(this.repository);

  Future<Either<Failure, StoreMutationResult>> call(
    StoreMutationRequest request,
  ) {
    return repository.createStore(request);
  }
}

class UpdateStore {
  final StoreRepository repository;

  UpdateStore(this.repository);

  Future<Either<Failure, StoreMutationResult>> call(
    String storeId,
    StoreMutationRequest request,
  ) {
    return repository.updateStore(storeId, request);
  }
}

class DeleteStore {
  final StoreRepository repository;

  DeleteStore(this.repository);

  Future<Either<Failure, StoreMutationResult>> call(String storeId) {
    return repository.deleteStore(storeId);
  }
}

class ToggleStoreStatus {
  final StoreRepository repository;

  ToggleStoreStatus(this.repository);

  Future<Either<Failure, StoreMutationResult>> call(String storeId) {
    return repository.toggleStoreStatus(storeId);
  }
}

class CreateStoreFuzzyOverrideProfile {
  final StoreRepository repository;

  CreateStoreFuzzyOverrideProfile(this.repository);

  Future<Either<Failure, StoreMutationResult>> call(
    String storeId,
    FuzzyOverrideProfileRequest request,
  ) {
    return repository.createFuzzyOverrideProfile(storeId, request);
  }
}
