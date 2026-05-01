import 'package:dartz/dartz.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/brand_detail.dart';
import '../../domain/entities/brand_update_request.dart';
import '../../domain/entities/store_summary.dart';
import '../../domain/repositories/store_selection_repository.dart';
import '../datasources/store_selection_remote_datasource.dart';

class StoreSelectionRepositoryImpl implements StoreSelectionRepository {
  StoreSelectionRepositoryImpl({required this.remoteDataSource});

  final StoreSelectionRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, List<StoreSummary>>> getUserStores() async {
    try {
      final stores = await remoteDataSource.getUserStores();
      return Right(stores);
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not load your stores right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, BrandDetail>> getBrandDetail(String brandId) async {
    try {
      final brand = await remoteDataSource.getBrandDetail(brandId);
      return Right(brand);
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not load the brand profile right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, String>> updateBrandDetail({
    required String brandId,
    required BrandUpdateRequest request,
  }) async {
    try {
      final message = await remoteDataSource.updateBrandDetail(
        brandId: brandId,
        request: request,
      );
      return Right(message);
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not update the brand profile right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
