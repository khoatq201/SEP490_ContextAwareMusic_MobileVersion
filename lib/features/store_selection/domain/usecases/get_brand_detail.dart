import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/brand_detail.dart';
import '../repositories/store_selection_repository.dart';

class GetBrandDetail {
  const GetBrandDetail(this.repository);

  final StoreSelectionRepository repository;

  Future<Either<Failure, BrandDetail>> call(String brandId) {
    return repository.getBrandDetail(brandId);
  }
}
