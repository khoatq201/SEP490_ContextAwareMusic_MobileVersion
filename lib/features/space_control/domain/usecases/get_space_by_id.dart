import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/space.dart';
import '../repositories/space_repository.dart';

class GetSpaceById {
  final SpaceRepository repository;

  GetSpaceById(this.repository);

  Future<Either<Failure, Space>> call(String spaceId) async {
    return await repository.getSpaceById(spaceId);
  }
}
