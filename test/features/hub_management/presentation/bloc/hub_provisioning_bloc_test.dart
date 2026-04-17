import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/error/failures.dart';
import 'package:cams_store_manager/core/models/pagination_result.dart';
import 'package:cams_store_manager/features/hub_management/data/services/ble_permission_service.dart';
import 'package:cams_store_manager/features/hub_management/data/services/ble_provisioning_service.dart';
import 'package:cams_store_manager/features/hub_management/data/services/location_capture_service.dart';
import 'package:cams_store_manager/features/hub_management/data/services/provisioning_identity_resolver.dart';
import 'package:cams_store_manager/features/hub_management/domain/entities/ble_candidate.dart';
import 'package:cams_store_manager/features/hub_management/domain/entities/esp_provisioning_identity.dart';
import 'package:cams_store_manager/features/hub_management/domain/entities/hub_device_location.dart';
import 'package:cams_store_manager/features/hub_management/domain/entities/space_hub_binding.dart';
import 'package:cams_store_manager/features/hub_management/domain/entities/wifi_candidate.dart';
import 'package:cams_store_manager/features/hub_management/domain/repositories/space_hub_repository.dart';
import 'package:cams_store_manager/features/hub_management/domain/usecases/space_hub_usecases.dart';
import 'package:cams_store_manager/features/hub_management/presentation/bloc/hub_provisioning_bloc.dart';
import 'package:cams_store_manager/features/hub_management/presentation/bloc/hub_provisioning_event.dart';
import 'package:cams_store_manager/features/hub_management/presentation/bloc/hub_provisioning_state.dart';
import 'package:cams_store_manager/features/locations/data/datasources/location_remote_datasource.dart';
import 'package:cams_store_manager/features/locations/domain/entities/location_space.dart';
import 'package:cams_store_manager/features/locations/domain/repositories/location_repository.dart';
import 'package:cams_store_manager/features/locations/domain/usecases/location_usecases.dart';
import 'package:cams_store_manager/features/music_policy/data/models/fuzzy_override_profile_request.dart';

void main() {
  group('HubProvisioningBloc', () {
    late _FakeSpaceHubRepository repository;
    late _FakeBleProvisioningService bleProvisioningService;
    late _FakeBlePermissionService blePermissionService;
    late _FakeLocationCaptureService locationCaptureService;
    late _FakeProvisioningIdentityResolver identityResolver;
    late HubProvisioningBloc bloc;

    setUp(() {
      repository = _FakeSpaceHubRepository();
      bleProvisioningService = _FakeBleProvisioningService();
      blePermissionService = _FakeBlePermissionService();
      locationCaptureService = _FakeLocationCaptureService();
      identityResolver = _FakeProvisioningIdentityResolver();
      bloc = HubProvisioningBloc(
        getSpaceHubBinding: GetSpaceHubBinding(repository),
        upsertSpaceHubBinding: UpsertSpaceHubBinding(repository),
        deleteSpaceHubBinding: DeleteSpaceHubBinding(repository),
        restartSpaceHub: RestartSpaceHub(repository),
        updateSpace: UpdateSpace(_FakeLocationRepository()),
        bleProvisioningService: bleProvisioningService,
        blePermissionService: blePermissionService,
        locationCaptureService: locationCaptureService,
        identityResolver: identityResolver,
        isAndroid: () => true,
      );
    });

    tearDown(() async {
      await bloc.close();
    });

    test('emits permissionRequired when bluetooth permissions are denied',
        () async {
      blePermissionService.checkStatusValue =
          BlePermissionRequirementStatus.denied;

      bloc.add(
        const HubProvisioningStarted(
          spaceId: 'space-1',
          storeId: 'store-1',
          spaceName: 'Main Hall',
        ),
      );

      await _waitUntil(
        () => bloc.state.phase == HubProvisioningPhase.permissionRequired,
      );

      expect(bloc.state.binding, isNull);
      expect(bloc.state.isPermissionPermanentlyDenied, isFalse);
      expect(bloc.state.message, contains('Bluetooth permissions'));
    });

    test('emits selectDevice with empty candidates when no CAM device is found',
        () async {
      blePermissionService.checkStatusValue =
          BlePermissionRequirementStatus.granted;
      bleProvisioningService.scanDevicesResult = const [];

      bloc.add(
        const HubProvisioningStarted(
          spaceId: 'space-1',
          storeId: 'store-1',
          spaceName: 'Main Hall',
        ),
      );

      await _waitUntil(
        () => bloc.state.phase == HubProvisioningPhase.selectDevice,
      );

      expect(bloc.state.bleCandidates, isEmpty);
      expect(bloc.state.message, contains('No CAM devices found'));
    });

    test('returns to secret code entry when Wi-Fi scan fails', () async {
      blePermissionService.checkStatusValue =
          BlePermissionRequirementStatus.granted;
      bleProvisioningService.scanDevicesResult = const [
        BleCandidate(bleDeviceName: 'CAM-ESP32-01'),
      ];
      bleProvisioningService.scanWifiError =
          BleProvisioningException('wifi scan failed');

      bloc.add(
        const HubProvisioningStarted(
          spaceId: 'space-1',
          storeId: 'store-1',
          spaceName: 'Main Hall',
        ),
      );
      await _waitUntil(
        () => bloc.state.phase == HubProvisioningPhase.selectDevice,
      );

      bloc.add(
        const HubProvisioningBleCandidateSelected(
          BleCandidate(bleDeviceName: 'CAM-ESP32-01'),
        ),
      );
      await _waitUntil(
        () => bloc.state.phase == HubProvisioningPhase.enterSecretCode,
      );
      bloc.add(
        const HubProvisioningSecretCodeSubmitted(
          secretCode: 'secret-123',
        ),
      );

      await _waitUntil(
        () =>
            bloc.state.phase == HubProvisioningPhase.enterSecretCode &&
            bloc.state.message != null,
      );

      expect(bloc.state.message, contains('Unable to read Wi-Fi networks'));
      expect(bloc.state.message, contains('Check the secret code'));
    });

    test('emits failure when ESP32 rejects Wi-Fi credentials', () async {
      blePermissionService.checkStatusValue =
          BlePermissionRequirementStatus.granted;
      bleProvisioningService.scanDevicesResult = const [
        BleCandidate(bleDeviceName: 'CAM-ESP32-01'),
      ];
      bleProvisioningService.scanWifiResult = const [
        WifiCandidate(ssid: 'Store WiFi'),
      ];
      bleProvisioningService.provisionResult = false;

      bloc.add(
        const HubProvisioningStarted(
          spaceId: 'space-1',
          storeId: 'store-1',
          spaceName: 'Main Hall',
        ),
      );
      await _waitUntil(
        () => bloc.state.phase == HubProvisioningPhase.selectDevice,
      );

      bloc.add(
        const HubProvisioningBleCandidateSelected(
          BleCandidate(bleDeviceName: 'CAM-ESP32-01'),
        ),
      );
      await _waitUntil(
        () => bloc.state.phase == HubProvisioningPhase.enterSecretCode,
      );
      bloc.add(
        const HubProvisioningSecretCodeSubmitted(
          secretCode: 'secret-123',
        ),
      );
      await _waitUntil(
        () => bloc.state.phase == HubProvisioningPhase.enterWifi,
      );

      bloc.add(
        const HubProvisioningCredentialsSubmitted(
          ssid: 'Store WiFi',
          passphrase: 'super-secret',
        ),
      );

      await _waitUntil(() => bloc.state.phase == HubProvisioningPhase.failure);

      expect(bloc.state.message, contains('did not confirm'));
    });

    test(
        'supports full provisioning success followed by backend retry without resending Wi-Fi',
        () async {
      blePermissionService.checkStatusValue =
          BlePermissionRequirementStatus.granted;
      bleProvisioningService.scanDevicesResult = const [
        BleCandidate(bleDeviceName: 'CAM-ESP32-01'),
      ];
      bleProvisioningService.scanWifiResult = const [
        WifiCandidate(ssid: 'Store WiFi'),
      ];
      bleProvisioningService.provisionResult = true;
      repository.upsertResults = [
        Right(
          _binding(status: SpaceHubBindingStatus.syncPending),
        ),
        Right(_binding()),
      ];

      bloc.add(
        const HubProvisioningStarted(
          spaceId: 'space-1',
          storeId: 'store-1',
          spaceName: 'Main Hall',
        ),
      );
      await _waitUntil(
        () => bloc.state.phase == HubProvisioningPhase.selectDevice,
      );

      bloc.add(
        const HubProvisioningBleCandidateSelected(
          BleCandidate(bleDeviceName: 'CAM-ESP32-01'),
        ),
      );
      await _waitUntil(
        () => bloc.state.phase == HubProvisioningPhase.enterSecretCode,
      );
      bloc.add(
        const HubProvisioningSecretCodeSubmitted(
          secretCode: 'secret-123',
        ),
      );
      await _waitUntil(
        () => bloc.state.phase == HubProvisioningPhase.enterWifi,
      );

      bloc.add(
        const HubProvisioningCredentialsSubmitted(
          ssid: 'Store WiFi',
          passphrase: 'super-secret',
        ),
      );
      await _waitUntil(() => bloc.state.phase == HubProvisioningPhase.success);

      expect(bloc.state.binding?.isSyncPending, isTrue);
      expect(repository.upsertCallCount, 1);

      bloc.add(const HubProvisioningRetrySyncRequested());
      await _waitUntil(() {
        return bloc.state.phase == HubProvisioningPhase.success &&
            (bloc.state.binding?.isBound ?? false) &&
            !(bloc.state.binding?.isSyncPending ?? true);
      });

      expect(repository.upsertCallCount, 2);
      expect(bleProvisioningService.provisionCallCount, 1);
      expect(bleProvisioningService.sendCustomDataCallCount, 0);
      expect(bloc.state.message, contains('synced successfully'));
    });

    test('can delete an existing hub binding', () async {
      repository.bindingForGet = _binding();

      bloc.add(
        const HubProvisioningStarted(
          spaceId: 'space-1',
          storeId: 'store-1',
          spaceName: 'Main Hall',
        ),
      );
      await _waitUntil(() => bloc.state.phase == HubProvisioningPhase.success);

      bloc.add(const HubProvisioningDeleteBindingRequested());
      await _waitUntil(() {
        return bloc.state.phase == HubProvisioningPhase.success &&
            bloc.state.binding == null;
      });

      expect(repository.deleteCallCount, 1);
      expect(bloc.state.didMutateBinding, isTrue);
      expect(bloc.state.message, contains('removed'));
    });
  });
}

SpaceHubBinding _binding({
  SpaceHubBindingStatus status = SpaceHubBindingStatus.bound,
  HubDeviceLocationStatus deviceLocationStatus =
      HubDeviceLocationStatus.unknown,
  HubDeviceLocation? deviceLocation,
  String? lastError,
  String? deviceLocationLastError,
}) {
  return SpaceHubBinding(
    spaceId: 'space-1',
    bleDeviceName: 'CAM-ESP32-01',
    wifiSsid: 'Store WiFi',
    provisioningMethod: HubProvisioningMethod.blePrefixScan,
    provisionedAtUtc: DateTime.parse('2026-04-04T10:00:00.000Z'),
    status: status,
    lastError: lastError,
    deviceLocation: deviceLocation,
    deviceLocationStatus: deviceLocationStatus,
    deviceLocationLastError: deviceLocationLastError,
    deviceLocationUpdatedAtUtc: deviceLocation?.capturedAtUtc,
  );
}

HubDeviceLocation _sampleLocation({
  String city = 'Ho Chi Minh City',
  double latitude = 10.7769,
  double longitude = 106.7009,
  HubDeviceLocationSource source = HubDeviceLocationSource.phoneGps,
}) {
  return HubDeviceLocation(
    latitude: latitude,
    longitude: longitude,
    city: city,
    source: source,
    capturedAtUtc: DateTime.parse('2026-04-04T10:05:00.000Z'),
  );
}

Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for condition');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

class _FakeSpaceHubRepository implements SpaceHubRepository {
  SpaceHubBinding? bindingForGet;
  List<Either<Failure, SpaceHubBinding>> upsertResults = [];
  int upsertCallCount = 0;
  int deleteCallCount = 0;

  @override
  Future<Either<Failure, SpaceHubBinding?>> getBinding(String spaceId) async {
    return Right(bindingForGet);
  }

  @override
  Future<Either<Failure, SpaceHubBinding>> upsertBinding(
    SpaceHubBinding binding,
  ) async {
    upsertCallCount += 1;
    if (upsertResults.isNotEmpty) {
      final next = upsertResults.removeAt(0);
      next.fold((_) {}, (savedBinding) => bindingForGet = savedBinding);
      return next;
    }
    bindingForGet = binding;
    return Right(binding);
  }

  @override
  Future<Either<Failure, void>> deleteBinding(String spaceId) async {
    deleteCallCount += 1;
    bindingForGet = null;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> restartHub(String spaceId) async {
    return const Right(null);
  }
}

class _FakeLocationRepository implements LocationRepository {
  @override
  Future<Either<Failure, SpaceMutationResult>> createSpace(
    SpaceMutationRequest request,
  ) async {
    return const Right(SpaceMutationResult(isSuccess: true));
  }

  @override
  Future<Either<Failure, SpaceMutationResult>> createFuzzyOverrideProfile(
    String spaceId,
    FuzzyOverrideProfileRequest request,
  ) async {
    return const Right(SpaceMutationResult(isSuccess: true));
  }

  @override
  Future<Either<Failure, SpaceMutationResult>> deleteSpace(
      String spaceId) async {
    return const Right(SpaceMutationResult(isSuccess: true));
  }

  @override
  Future<Either<Failure, LocationSpace>> getPairedSpace(
    String spaceId,
    String storeId,
  ) async {
    return Left(ServerFailure('Not implemented in test fake'));
  }

  @override
  Future<Either<Failure, Map<String, PaginationResult<LocationSpace>>>>
      getSpacesForBrand(
    List<String> storeIds, {
    int page = 1,
    int pageSize = 10,
  }) async {
    return const Right({});
  }

  @override
  Future<Either<Failure, PaginationResult<LocationSpace>>> getSpacesForStore(
    String storeId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    return const Right(
      PaginationResult<LocationSpace>(
        currentPage: 1,
        pageSize: 10,
        totalItems: 0,
        totalPages: 0,
        hasPrevious: false,
        hasNext: false,
        items: [],
      ),
    );
  }

  @override
  Future<Either<Failure, SpaceMutationResult>> toggleSpaceStatus(
    String spaceId,
  ) async {
    return const Right(SpaceMutationResult(isSuccess: true));
  }

  @override
  Future<Either<Failure, SpaceMutationResult>> updateSpace(
    String spaceId,
    SpaceMutationRequest request,
  ) async {
    return const Right(SpaceMutationResult(isSuccess: true));
  }
}

class _FakeBleProvisioningService implements BleProvisioningService {
  List<BleCandidate> scanDevicesResult = const [];
  List<WifiCandidate> scanWifiResult = const [];
  bool provisionResult = true;
  Uint8List customDataResult = Uint8List(0);
  BleProvisioningException? scanWifiError;
  BleProvisioningException? sendCustomDataError;
  int provisionCallCount = 0;
  int sendCustomDataCallCount = 0;

  @override
  Future<List<BleCandidate>> scanDevices(String prefix) async {
    return scanDevicesResult;
  }

  @override
  Future<List<WifiCandidate>> scanWifiNetworks(
    EspProvisioningIdentity identity,
  ) async {
    if (scanWifiError != null) {
      throw scanWifiError!;
    }
    return scanWifiResult;
  }

  @override
  Future<bool> provisionWifi(
    EspProvisioningIdentity identity, {
    required String ssid,
    required String passphrase,
  }) async {
    provisionCallCount += 1;
    return provisionResult;
  }

  @override
  Future<Uint8List> sendCustomData(
    EspProvisioningIdentity identity, {
    required String endpoint,
    required Uint8List payload,
  }) async {
    sendCustomDataCallCount += 1;
    if (sendCustomDataError != null) {
      throw sendCustomDataError!;
    }
    return customDataResult;
  }
}

class _FakeBlePermissionService implements BlePermissionService {
  BlePermissionRequirementStatus checkStatusValue =
      BlePermissionRequirementStatus.granted;
  BlePermissionRequirementStatus requestPermissionsValue =
      BlePermissionRequirementStatus.granted;

  @override
  Future<BlePermissionRequirementStatus> checkStatus() async {
    return checkStatusValue;
  }

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<BlePermissionRequirementStatus> requestPermissions() async {
    return requestPermissionsValue;
  }
}

class _FakeLocationCaptureService implements LocationCaptureService {
  HubDeviceLocation captureResult = _sampleLocation();
  LocationCaptureException? captureError;

  @override
  Future<HubDeviceLocation> captureCurrentLocation() async {
    if (captureError != null) {
      throw captureError!;
    }
    return captureResult;
  }

  @override
  Future<String> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    return captureResult.city;
  }
}

class _FakeProvisioningIdentityResolver
    implements ProvisioningIdentityResolver {
  String? lastProofOfPossession;

  @override
  String get blePrefix => 'CAM';

  @override
  Future<EspProvisioningIdentity> resolve(
    BleCandidate candidate, {
    required String proofOfPossession,
  }) async {
    lastProofOfPossession = proofOfPossession;
    return EspProvisioningIdentity(
      blePrefix: blePrefix,
      bleDeviceName: candidate.bleDeviceName,
      deviceId: 'cams_xbgqvj',
      proofOfPossession: proofOfPossession,
      source: EspProvisioningIdentitySource.blePrefixScan,
    );
  }
}
