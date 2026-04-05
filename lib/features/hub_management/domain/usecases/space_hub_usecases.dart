import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/space_hub_binding.dart';
import '../repositories/space_hub_repository.dart';

class GetSpaceHubBinding {
  const GetSpaceHubBinding(this.repository);

  final SpaceHubRepository repository;

  Future<Either<Failure, SpaceHubBinding?>> call(String spaceId) {
    return repository.getBinding(spaceId);
  }
}

class UpsertSpaceHubBinding {
  const UpsertSpaceHubBinding(this.repository);

  final SpaceHubRepository repository;

  Future<Either<Failure, SpaceHubBinding>> call(SpaceHubBinding binding) {
    return repository.upsertBinding(binding);
  }
}

class DeleteSpaceHubBinding {
  const DeleteSpaceHubBinding(this.repository);

  final SpaceHubRepository repository;

  Future<Either<Failure, void>> call(String spaceId) {
    return repository.deleteBinding(spaceId);
  }
}

class RestartSpaceHub {
  const RestartSpaceHub(this.repository);

  final SpaceHubRepository repository;

  Future<Either<Failure, void>> call(String spaceId) {
    return repository.restartHub(spaceId);
  }
}
