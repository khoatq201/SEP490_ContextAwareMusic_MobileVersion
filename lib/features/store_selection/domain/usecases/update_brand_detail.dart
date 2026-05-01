import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/brand_update_request.dart';
import '../repositories/store_selection_repository.dart';

class UpdateBrandDetail {
  const UpdateBrandDetail(this.repository);

  final StoreSelectionRepository repository;

  Future<Either<Failure, String>> call({
    required String brandId,
    required BrandUpdateRequest request,
  }) {
    return repository.updateBrandDetail(
      brandId: brandId,
      request: request,
    );
  }
}
