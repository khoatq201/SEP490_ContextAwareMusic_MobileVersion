import 'package:dartz/dartz.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../music_policy/data/models/fuzzy_override_profile_request.dart';
import '../../domain/entities/space_summary.dart';
import '../../domain/entities/store.dart';
import '../../domain/repositories/store_repository.dart';
import '../datasources/store_remote_datasource.dart';

class StoreRepositoryImpl implements StoreRepository {
  StoreRepositoryImpl({required this.remoteDataSource});

  final StoreRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, Store>> getStoreDetails(String storeId) async {
    try {
      final storeModel = await remoteDataSource.getStoreDetails(storeId);
      return Right(storeModel.toEntity());
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not load this store right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<SpaceSummary>>> getSpaceSummaries(
    String storeId,
  ) async {
    try {
      final spaceModels = await remoteDataSource.getSpaceSummaries(storeId);
      return Right(spaceModels.map((model) => model.toEntity()).toList());
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not load spaces for this store.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, StoreMutationResult>> createStore(
    StoreMutationRequest request,
  ) async {
    try {
      final result = await remoteDataSource.createStore(request);
      return Right(result);
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not create this store right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, StoreMutationResult>> updateStore(
    String storeId,
    StoreMutationRequest request,
  ) async {
    try {
      final result = await remoteDataSource.updateStore(storeId, request);
      return Right(result);
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not update this store right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, StoreMutationResult>> deleteStore(
    String storeId,
  ) async {
    try {
      final result = await remoteDataSource.deleteStore(storeId);
      return Right(result);
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not delete this store right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, StoreMutationResult>> toggleStoreStatus(
    String storeId,
  ) async {
    try {
      final result = await remoteDataSource.toggleStoreStatus(storeId);
      return Right(result);
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not update this store right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, StoreMutationResult>> createFuzzyOverrideProfile(
    String storeId,
    FuzzyOverrideProfileRequest request,
  ) async {
    try {
      final result = await remoteDataSource.createFuzzyOverrideProfile(
        storeId,
        request,
      );
      return Right(result);
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not save the store music policy right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
