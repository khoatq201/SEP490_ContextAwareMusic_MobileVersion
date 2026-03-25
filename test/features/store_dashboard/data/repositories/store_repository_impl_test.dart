import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/error/exceptions.dart';
import 'package:cams_store_manager/core/error/failures.dart';
import 'package:cams_store_manager/features/store_dashboard/data/datasources/store_remote_datasource.dart';
import 'package:cams_store_manager/features/store_dashboard/data/models/space_summary_model.dart';
import 'package:cams_store_manager/features/store_dashboard/data/models/store_model.dart';
import 'package:cams_store_manager/features/store_dashboard/data/repositories/store_repository_impl.dart';

void main() {
  group('StoreRepositoryImpl write path', () {
    late _FakeStoreRemoteDataSource remoteDataSource;
    late StoreRepositoryImpl repository;

    setUp(() {
      remoteDataSource = _FakeStoreRemoteDataSource();
      repository = StoreRepositoryImpl(remoteDataSource: remoteDataSource);
    });

    test('createStore returns mutation result on success', () async {
      remoteDataSource.createStoreResult = const StoreMutationResult(
        isSuccess: true,
        message: 'Created',
      );

      final result = await repository.createStore(
        const StoreMutationRequest(name: 'Store A'),
      );

      expect(result, isA<Right<Failure, StoreMutationResult>>());
      result.fold(
        (_) => fail('Expected success'),
        (success) => expect(success.message, 'Created'),
      );
    });

    test('updateStore maps ServerException to ServerFailure', () async {
      remoteDataSource.updateStoreError = ServerException('Store locked');

      final result = await repository.updateStore(
        'store-1',
        const StoreMutationRequest(name: 'Store B'),
      );

      expect(result, isA<Left<Failure, StoreMutationResult>>());
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Store locked');
        },
        (_) => fail('Expected failure'),
      );
    });

    test('deleteStore maps unknown exception to ServerFailure', () async {
      remoteDataSource.deleteStoreError = Exception('Delete failed');

      final result = await repository.deleteStore('store-2');

      expect(result, isA<Left<Failure, StoreMutationResult>>());
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('Failed to delete store:'));
        },
        (_) => fail('Expected failure'),
      );
    });

    test('toggleStoreStatus forwards store id to datasource', () async {
      await repository.toggleStoreStatus('store-3');

      expect(remoteDataSource.lastToggledStoreId, 'store-3');
    });
  });
}

class _FakeStoreRemoteDataSource implements StoreRemoteDataSource {
  StoreMutationResult createStoreResult =
      const StoreMutationResult(isSuccess: true);
  Exception? updateStoreError;
  Exception? deleteStoreError;
  String? lastToggledStoreId;

  @override
  Future<StoreMutationResult> createStore(StoreMutationRequest request) async {
    return createStoreResult;
  }

  @override
  Future<StoreMutationResult> updateStore(
    String storeId,
    StoreMutationRequest request,
  ) async {
    if (updateStoreError != null) {
      throw updateStoreError!;
    }
    return const StoreMutationResult(isSuccess: true);
  }

  @override
  Future<StoreMutationResult> deleteStore(String storeId) async {
    if (deleteStoreError != null) {
      throw deleteStoreError!;
    }
    return const StoreMutationResult(isSuccess: true);
  }

  @override
  Future<StoreMutationResult> toggleStoreStatus(String storeId) async {
    lastToggledStoreId = storeId;
    return const StoreMutationResult(isSuccess: true);
  }

  @override
  Future<StoreModel> getStoreDetails(String storeId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<SpaceSummaryModel>> getSpaceSummaries(String storeId) async {
    throw UnimplementedError();
  }
}
