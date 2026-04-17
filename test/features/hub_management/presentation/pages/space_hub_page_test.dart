import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:cams_store_manager/features/hub_management/presentation/bloc/hub_provisioning_state.dart';
import 'package:cams_store_manager/features/hub_management/presentation/pages/space_hub_page.dart';
import 'package:cams_store_manager/features/locations/data/datasources/location_remote_datasource.dart';
import 'package:cams_store_manager/features/locations/domain/entities/location_space.dart';
import 'package:cams_store_manager/features/locations/domain/repositories/location_repository.dart';
import 'package:cams_store_manager/features/locations/domain/usecases/location_usecases.dart';
import 'package:cams_store_manager/features/music_policy/data/models/fuzzy_override_profile_request.dart';

void main() {
  group('SpaceHubPage', () {
    late _TestHubProvisioningBloc bloc;

    setUp(() {
      bloc = _TestHubProvisioningBloc();
    });

    tearDown(() async {
      await bloc.close();
    });

    testWidgets('renders start provisioning CTA when no binding exists', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(bloc));
      bloc.push(
        const HubProvisioningState(
          phase: HubProvisioningPhase.success,
          spaceId: 'space-1',
          storeId: 'store-1',
          spaceName: 'Main Hall',
        ),
      );
      await tester.pump();

      expect(find.text('No hub configured yet'), findsOneWidget);
      expect(find.text('Scan CAM devices'), findsOneWidget);
      expect(find.text('Unbind'), findsNothing);
    });

    testWidgets('renders binding actions for a bound hub', (tester) async {
      await tester.pumpWidget(_buildTestApp(bloc));
      bloc.push(
        HubProvisioningState(
          phase: HubProvisioningPhase.success,
          spaceId: 'space-1',
          storeId: 'store-1',
          spaceName: 'Main Hall',
          binding: _binding(),
        ),
      );
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Reconfigure Wi-Fi'),
        250,
      );

      expect(find.text('Current hub binding'), findsOneWidget);
      expect(find.text('Reconfigure Wi-Fi'), findsOneWidget);
      expect(find.text('Restart hub'), findsOneWidget);
      expect(find.text('Unbind'), findsOneWidget);
      expect(find.text('Retry sync'), findsNothing);
    });

    testWidgets('renders retry sync when binding is pending backend sync', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(bloc));
      bloc.push(
        HubProvisioningState(
          phase: HubProvisioningPhase.success,
          spaceId: 'space-1',
          storeId: 'store-1',
          spaceName: 'Main Hall',
          binding: _binding(status: SpaceHubBindingStatus.syncPending),
        ),
      );
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Retry sync'),
        250,
      );

      expect(find.text('Retry sync'), findsOneWidget);
      expect(find.text('Sync pending'), findsWidgets);
    });

    testWidgets('renders secret code form after selecting a device', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(bloc));
      bloc.push(
        const HubProvisioningState(
          phase: HubProvisioningPhase.enterSecretCode,
          spaceId: 'space-1',
          storeId: 'store-1',
          spaceName: 'Main Hall',
          selectedBleCandidate: BleCandidate(bleDeviceName: 'CAM-ESP32-01'),
        ),
      );
      await tester.pump();

      expect(find.text('Enter secret code'), findsOneWidget);
      expect(find.text('Read Wi-Fi from ESP32'), findsOneWidget);
      expect(find.textContaining('Selected device:'), findsOneWidget);
    });
  });
}

Widget _buildTestApp(HubProvisioningBloc bloc) {
  return MaterialApp(
    home: BlocProvider<HubProvisioningBloc>.value(
      value: bloc,
      child: const SpaceHubPage(
        spaceId: 'space-1',
        storeId: 'store-1',
        spaceName: 'Main Hall',
      ),
    ),
  );
}

SpaceHubBinding _binding({
  SpaceHubBindingStatus status = SpaceHubBindingStatus.bound,
}) {
  return SpaceHubBinding(
    spaceId: 'space-1',
    bleDeviceName: 'CAM-ESP32-01',
    wifiSsid: 'Store WiFi',
    provisioningMethod: HubProvisioningMethod.blePrefixScan,
    provisionedAtUtc: DateTime.parse('2026-04-04T10:00:00.000Z'),
    status: status,
  );
}

class _TestHubProvisioningBloc extends HubProvisioningBloc {
  _TestHubProvisioningBloc()
      : super(
          getSpaceHubBinding: GetSpaceHubBinding(_NoopSpaceHubRepository()),
          upsertSpaceHubBinding:
              UpsertSpaceHubBinding(_NoopSpaceHubRepository()),
          deleteSpaceHubBinding:
              DeleteSpaceHubBinding(_NoopSpaceHubRepository()),
          restartSpaceHub: RestartSpaceHub(_NoopSpaceHubRepository()),
          updateSpace: UpdateSpace(_NoopLocationRepository()),
          bleProvisioningService: _NoopBleProvisioningService(),
          blePermissionService: _NoopBlePermissionService(),
          locationCaptureService: _NoopLocationCaptureService(),
          identityResolver: _NoopProvisioningIdentityResolver(),
          isAndroid: () => true,
        );

  void push(HubProvisioningState nextState) => emit(nextState);
}

class _NoopSpaceHubRepository implements SpaceHubRepository {
  @override
  Future<Either<Failure, SpaceHubBinding?>> getBinding(String spaceId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, SpaceHubBinding>> upsertBinding(
    SpaceHubBinding binding,
  ) async {
    return Right(binding);
  }

  @override
  Future<Either<Failure, void>> deleteBinding(String spaceId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> restartHub(String spaceId) async {
    return const Right(null);
  }
}

class _NoopLocationRepository implements LocationRepository {
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

class _NoopBleProvisioningService implements BleProvisioningService {
  @override
  Future<List<BleCandidate>> scanDevices(String prefix) async => const [];

  @override
  Future<List<WifiCandidate>> scanWifiNetworks(
    EspProvisioningIdentity identity,
  ) async {
    return const [];
  }

  @override
  Future<bool> provisionWifi(
    EspProvisioningIdentity identity, {
    required String ssid,
    required String passphrase,
  }) async {
    return true;
  }

  @override
  Future<Uint8List> sendCustomData(
    EspProvisioningIdentity identity, {
    required String endpoint,
    required Uint8List payload,
  }) async {
    return Uint8List(0);
  }
}

class _NoopBlePermissionService implements BlePermissionService {
  @override
  Future<BlePermissionRequirementStatus> checkStatus() async {
    return BlePermissionRequirementStatus.granted;
  }

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<BlePermissionRequirementStatus> requestPermissions() async {
    return BlePermissionRequirementStatus.granted;
  }
}

class _NoopLocationCaptureService implements LocationCaptureService {
  @override
  Future<HubDeviceLocation> captureCurrentLocation() async {
    return HubDeviceLocation(
      latitude: 10.7769,
      longitude: 106.7009,
      city: 'Ho Chi Minh City',
      source: HubDeviceLocationSource.phoneGps,
      capturedAtUtc: DateTime.utc(2026, 4, 4, 10, 5),
    );
  }

  @override
  Future<String> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    return 'Ho Chi Minh City';
  }
}

class _NoopProvisioningIdentityResolver
    implements ProvisioningIdentityResolver {
  @override
  String get blePrefix => 'CAM';

  @override
  Future<EspProvisioningIdentity> resolve(
    BleCandidate candidate, {
    required String proofOfPossession,
  }) async {
    return EspProvisioningIdentity(
      blePrefix: blePrefix,
      bleDeviceName: candidate.bleDeviceName,
      deviceId: 'cams_xbgqvj',
      proofOfPossession: proofOfPossession,
      source: EspProvisioningIdentitySource.blePrefixScan,
    );
  }
}
