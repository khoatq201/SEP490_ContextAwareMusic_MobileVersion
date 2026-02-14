import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/store_summary.dart';

abstract class StoreSelectionRepository {
  /// Get list of stores by their IDs
  Future<Either<Failure, List<StoreSummary>>> getStoresByIds(
      List<String> storeIds);
}
