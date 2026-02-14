import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/space_summary.dart';
import '../repositories/store_repository.dart';

class GetSpaceSummaries {
  final StoreRepository repository;

  GetSpaceSummaries(this.repository);

  Future<Either<Failure, List<SpaceSummary>>> call(String storeId) async {
    return await repository.getSpaceSummaries(storeId);
  }
}
