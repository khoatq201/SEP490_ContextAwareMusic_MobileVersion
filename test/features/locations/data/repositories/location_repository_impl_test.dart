import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/error/exceptions.dart';
import 'package:cams_store_manager/core/error/failures.dart';
import 'package:cams_store_manager/core/models/pagination_result.dart';
import 'package:cams_store_manager/core/network/network_info.dart';
import 'package:cams_store_manager/features/locations/data/datasources/location_remote_datasource.dart';
import 'package:cams_store_manager/features/locations/data/models/location_space_model.dart';
import 'package:cams_store_manager/features/locations/data/repositories/location_repository_impl.dart';

void main() {
  group('LocationRepositoryImpl write path', () {
    late _FakeLocationRemoteDataSource remoteDataSource;
    late _FakeNetworkInfo networkInfo;
    late LocationRepositoryImpl repository;

    setUp(() {
      remoteDataSource = _FakeLocationRemoteDataSource();
      networkInfo = _FakeNetworkInfo();
      repository = LocationRepositoryImpl(
        remoteDataSource: remoteDataSource,
        networkInfo: networkInfo,
      );
    });

    test('createSpace returns success when online', () async {
      networkInfo.connected = true;
      remoteDataSource.createSpaceResult = const SpaceMutationResult(
        isSuccess: true,
        message: 'Created',
      );

      final result = await repository.createSpace(
        const SpaceMutationRequest(storeId: 'store-1', name: 'Counter'),
      );

      expect(result, isA<Right<Failure, SpaceMutationResult>>());
      expect(remoteDataSource.createSpaceCallCount, 1);
    });

    test('createSpace returns NetworkFailure when offline', () async {
      networkInfo.connected = false;

      final result = await repository.createSpace(
        const SpaceMutationRequest(storeId: 'store-1', name: 'Counter'),
      );

      expect(result, isA<Left<Failure, SpaceMutationResult>>());
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Expected failure'),
      );
      expect(remoteDataSource.createSpaceCallCount, 0);
    });

    test('updateSpace maps ServerException to ServerFailure', () async {
      networkInfo.connected = true;
      remoteDataSource.updateSpaceError = ServerException('Space locked');

      final result = await repository.updateSpace(
        'space-1',
        const SpaceMutationRequest(name: 'New name'),
      );

      expect(result, isA<Left<Failure, SpaceMutationResult>>());
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Space locked');
        },
        (_) => fail('Expected failure'),
      );
    });

    test('toggleSpaceStatus forwards success payload', () async {
      networkInfo.connected = true;
      remoteDataSource.toggleSpaceStatusResult = const SpaceMutationResult(
        isSuccess: true,
        message: 'Toggled',
      );

      final result = await repository.toggleSpaceStatus('space-1');

      result.fold(
        (_) => fail('Expected success'),
        (success) => expect(success.message, 'Toggled'),
      );
      expect(remoteDataSource.lastToggledSpaceId, 'space-1');
    });
  });
}

class _FakeNetworkInfo implements NetworkInfo {
  bool connected = true;

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(connected);
}

class _FakeLocationRemoteDataSource implements LocationRemoteDataSource {
  int createSpaceCallCount = 0;
  SpaceMutationResult createSpaceResult =
      const SpaceMutationResult(isSuccess: true);

  SpaceMutationResult updateSpaceResult =
      const SpaceMutationResult(isSuccess: true);
  Exception? updateSpaceError;

  SpaceMutationResult toggleSpaceStatusResult =
      const SpaceMutationResult(isSuccess: true);
  String? lastToggledSpaceId;

  @override
  Future<SpaceMutationResult> createSpace(SpaceMutationRequest request) async {
    createSpaceCallCount += 1;
    return createSpaceResult;
  }

  @override
  Future<SpaceMutationResult> updateSpace(
    String spaceId,
    SpaceMutationRequest request,
  ) async {
    if (updateSpaceError != null) {
      throw updateSpaceError!;
    }
    return updateSpaceResult;
  }

  @override
  Future<SpaceMutationResult> toggleSpaceStatus(String spaceId) async {
    lastToggledSpaceId = spaceId;
    return toggleSpaceStatusResult;
  }

  @override
  Future<SpaceMutationResult> deleteSpace(String spaceId) async {
    return const SpaceMutationResult(isSuccess: true);
  }

  @override
  Future<LocationSpaceModel> getSpace(String spaceId, String storeId) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, PaginationResult<LocationSpaceModel>>> getSpacesForBrand(
    List<String> storeIds, {
    int page = 1,
    int pageSize = 10,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<PaginationResult<LocationSpaceModel>> getSpacesForStore(
    String storeId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    throw UnimplementedError();
  }
}
