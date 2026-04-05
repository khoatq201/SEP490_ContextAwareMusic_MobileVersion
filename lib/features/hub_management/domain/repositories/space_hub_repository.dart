import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/space_hub_binding.dart';

abstract class SpaceHubRepository {
  Future<Either<Failure, SpaceHubBinding?>> getBinding(String spaceId);

  Future<Either<Failure, SpaceHubBinding>> upsertBinding(
    SpaceHubBinding binding,
  );

  Future<Either<Failure, void>> deleteBinding(String spaceId);

  Future<Either<Failure, void>> restartHub(String spaceId);
}
