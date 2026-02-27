import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/store_summary.dart';

abstract class StoreSelectionRepository {
  /// Get list of stores the current user has access to (based on JWT token).
  Future<Either<Failure, List<StoreSummary>>> getUserStores();
}
