import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/store_remote_datasource.dart';
import '../entities/store.dart';
import '../entities/space_summary.dart';

abstract class StoreRepository {
  Future<Either<Failure, Store>> getStoreDetails(String storeId);
  Future<Either<Failure, List<SpaceSummary>>> getSpaceSummaries(String storeId);
  Future<Either<Failure, StoreMutationResult>> createStore(
    StoreMutationRequest request,
  );
  Future<Either<Failure, StoreMutationResult>> updateStore(
    String storeId,
    StoreMutationRequest request,
  );
  Future<Either<Failure, StoreMutationResult>> deleteStore(String storeId);
  Future<Either<Failure, StoreMutationResult>> toggleStoreStatus(
    String storeId,
  );
}
