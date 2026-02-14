import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/store.dart';
import '../entities/space_summary.dart';

abstract class StoreRepository {
  Future<Either<Failure, Store>> getStoreDetails(String storeId);
  Future<Either<Failure, List<SpaceSummary>>> getSpaceSummaries(String storeId);
}
