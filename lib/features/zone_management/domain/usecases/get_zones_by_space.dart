import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/zone.dart';
import '../repositories/zone_repository.dart';

/// Use case to get all zones for a specific space
class GetZonesBySpace {
  final ZoneRepository repository;

  GetZonesBySpace(this.repository);

  Future<Either<Failure, List<Zone>>> call(String spaceId) async {
    return await repository.getZonesBySpace(spaceId);
  }
}
