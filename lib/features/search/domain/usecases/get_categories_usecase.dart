import '../entities/search_category.dart';
import '../repositories/search_repository.dart';

class GetCategoriesUseCase {
  final SearchRepository repository;
  GetCategoriesUseCase(this.repository);

  Future<List<SearchCategory>> call() => repository.getCategories();
}
