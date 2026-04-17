import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/error/exceptions.dart';
import 'package:cams_store_manager/core/error/failures.dart';
import 'package:cams_store_manager/core/network/network_info.dart';
import 'package:cams_store_manager/core/services/local_storage_service.dart';
import 'package:cams_store_manager/features/hub_management/data/datasources/space_hub_remote_datasource.dart';
import 'package:cams_store_manager/features/hub_management/data/datasources/space_hub_stub_datasource.dart';
import 'package:cams_store_manager/features/hub_management/data/models/space_hub_binding_model.dart';
import 'package:cams_store_manager/features/hub_management/data/repositories/space_hub_repository_impl.dart';
import 'package:cams_store_manager/features/hub_management/domain/entities/space_hub_binding.dart';

void main() {
  group('SpaceHubRepositoryImpl', () {
    late _FakeSpaceHubRemoteDataSource remoteDataSource;
    late SpaceHubStubDataSource stubDataSource;
    late _FakeNetworkInfo networkInfo;
    late SpaceHubRepositoryImpl repository;

    setUp(() {
      remoteDataSource = _FakeSpaceHubRemoteDataSource();
      stubDataSource = SpaceHubStubDataSource(
        localStorage: _InMemoryLocalStorageService(),
      );
      networkInfo = _FakeNetworkInfo();
      repository = SpaceHubRepositoryImpl(
        remoteDataSource: remoteDataSource,
        stubDataSource: stubDataSource,
        networkInfo: networkInfo,
      );
    });

    test('stores syncPending locally when offline', () async {
      networkInfo.connected = false;

      final result = await repository.upsertBinding(_sampleBinding());

      expect(
        result,
        Right<Failure, SpaceHubBinding>(
          _sampleBinding(status: SpaceHubBindingStatus.syncPending),
        ),
      );
      final cached = await stubDataSource.getBinding('space-1');
      expect(cached?.status, SpaceHubBindingStatus.syncPending);
      expect(remoteDataSource.upsertCallCount, 0);
    });

    test('normalizes cached binding to bound when remote save succeeds',
        () async {
      networkInfo.connected = true;
      remoteDataSource.upsertResponse =
          SpaceHubBindingModel.fromEntity(_sampleBinding());

      final result = await repository.upsertBinding(_sampleBinding());

      expect(
        result,
        Right<Failure, SpaceHubBinding>(_sampleBinding()),
      );
      final cached = await stubDataSource.getBinding('space-1');
      expect(cached?.status, SpaceHubBindingStatus.bound);
      expect(cached?.lastError, isNull);
      expect(remoteDataSource.upsertCallCount, 1);
    });

    test('keeps syncPending when remote save fails', () async {
      networkInfo.connected = true;
      remoteDataSource.upsertError =
          const ServerException('backend sync still unavailable');

      final result = await repository.upsertBinding(_sampleBinding());

      expect(result.isRight(), isTrue);
      final savedBinding = result.getOrElse(() => throw StateError('missing'));
      expect(savedBinding.status, SpaceHubBindingStatus.syncPending);
      expect(savedBinding.lastError, 'backend sync still unavailable');

      final cached = await stubDataSource.getBinding('space-1');
      expect(cached?.status, SpaceHubBindingStatus.syncPending);
      expect(cached?.lastError, 'backend sync still unavailable');
    });

    test('deleteBinding clears local cache even if remote delete fails',
        () async {
      networkInfo.connected = true;
      await stubDataSource.upsertBinding(
        SpaceHubBindingModel.fromEntity(_sampleBinding()),
      );
      remoteDataSource.deleteError = const ServerException('delete failed');

      final result = await repository.deleteBinding('space-1');

      expect(result, const Right<Failure, void>(null));
      expect(await stubDataSource.getBinding('space-1'), isNull);
      expect(remoteDataSource.deleteCallCount, 1);
    });

    test('restartHub falls back to local stub when offline', () async {
      networkInfo.connected = false;
      await stubDataSource.upsertBinding(
        SpaceHubBindingModel.fromEntity(_sampleBinding()),
      );

      final result = await repository.restartHub('space-1');

      expect(result, const Right<Failure, void>(null));
    });
  });
}

SpaceHubBinding _sampleBinding({
  SpaceHubBindingStatus status = SpaceHubBindingStatus.bound,
  String? lastError,
}) {
  return SpaceHubBinding(
    spaceId: 'space-1',
    bleDeviceName: 'CAM-ESP32-01',
    wifiSsid: 'Store WiFi',
    provisioningMethod: HubProvisioningMethod.blePrefixScan,
    provisionedAtUtc: DateTime.parse('2026-04-04T10:00:00.000Z'),
    status: status,
    lastError: lastError,
  );
}

class _FakeNetworkInfo implements NetworkInfo {
  bool connected = true;

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get onConnectivityChanged => const Stream<bool>.empty();
}

class _FakeSpaceHubRemoteDataSource implements SpaceHubRemoteDataSource {
  int upsertCallCount = 0;
  int deleteCallCount = 0;
  SpaceHubBindingModel? upsertResponse;
  ServerException? upsertError;
  ServerException? deleteError;

  @override
  Future<SpaceHubBindingModel?> getBinding(String spaceId) async => null;

  @override
  Future<SpaceHubBindingModel> upsertBinding(
      SpaceHubBindingModel binding) async {
    upsertCallCount += 1;
    if (upsertError != null) throw upsertError!;
    return upsertResponse ?? binding;
  }

  @override
  Future<void> deleteBinding(String spaceId) async {
    deleteCallCount += 1;
    if (deleteError != null) throw deleteError!;
  }

  @override
  Future<void> restartHub(String spaceId) async {}
}

class _InMemoryLocalStorageService extends LocalStorageService {
  final Map<String, dynamic> _settings = {};

  @override
  dynamic getSetting(String key) => _settings[key];

  @override
  Future<void> saveSetting(String key, dynamic value) async {
    _settings[key] = value;
  }

  @override
  Future<void> removeSetting(String key) async {
    _settings.remove(key);
  }
}
