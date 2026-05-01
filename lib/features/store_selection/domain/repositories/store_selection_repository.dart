import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/brand_detail.dart';
import '../entities/brand_update_request.dart';
import '../entities/store_summary.dart';

abstract class StoreSelectionRepository {
  /// Get list of stores the current user has access to (based on JWT token).
  Future<Either<Failure, List<StoreSummary>>> getUserStores();

  /// Get brand profile detail used by the store selection header.
  Future<Either<Failure, BrandDetail>> getBrandDetail(String brandId);

  /// Partially update the current brand profile.
  Future<Either<Failure, String>> updateBrandDetail({
    required String brandId,
    required BrandUpdateRequest request,
  });
}
