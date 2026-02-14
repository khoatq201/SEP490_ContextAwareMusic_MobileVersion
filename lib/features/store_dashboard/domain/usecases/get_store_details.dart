import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/store.dart';
import '../repositories/store_repository.dart';

class GetStoreDetails {
  final StoreRepository repository;

  GetStoreDetails(this.repository);

  Future<Either<Failure, Store>> call(String storeId) async {
    return await repository.getStoreDetails(storeId);
  }
}
