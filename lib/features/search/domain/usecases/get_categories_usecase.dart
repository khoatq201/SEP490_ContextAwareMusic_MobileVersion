import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/search_category.dart';
import '../repositories/search_repository.dart';

class GetCategoriesUseCase {
  GetCategoriesUseCase(this.repository);

  final SearchRepository repository;

  Future<Either<Failure, List<SearchCategory>>> call() =>
      repository.getCategories();
}
