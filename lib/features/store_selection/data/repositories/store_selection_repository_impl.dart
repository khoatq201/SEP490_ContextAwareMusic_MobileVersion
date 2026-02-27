import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/store_summary.dart';
import '../../domain/repositories/store_selection_repository.dart';
import '../datasources/store_selection_remote_datasource.dart';

class StoreSelectionRepositoryImpl implements StoreSelectionRepository {
  final StoreSelectionRemoteDataSource remoteDataSource;

  StoreSelectionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<StoreSummary>>> getUserStores() async {
    try {
      final stores = await remoteDataSource.getUserStores();
      return Right(stores);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
