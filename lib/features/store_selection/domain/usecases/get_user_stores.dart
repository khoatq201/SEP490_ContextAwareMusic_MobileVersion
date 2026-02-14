import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/store_summary.dart';
import '../repositories/store_selection_repository.dart';

class GetUserStores {
  final StoreSelectionRepository repository;

  GetUserStores(this.repository);

  Future<Either<Failure, List<StoreSummary>>> call(
      List<String> storeIds) async {
    return await repository.getStoresByIds(storeIds);
  }
}
