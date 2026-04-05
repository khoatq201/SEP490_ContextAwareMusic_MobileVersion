import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/error/failures.dart';
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

      expect(find.text('Current hub binding'), findsOneWidget);
      expect(find.text('Reconfigure Wi-Fi'), findsOneWidget);
      expect(find.text('Update location'), findsOneWidget);
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

      expect(find.text('Retry sync'), findsOneWidget);
      expect(find.text('Sync pending'), findsWidgets);
    });

    testWidgets('renders location summary and retry location sync action', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(bloc));
      bloc.push(
        HubProvisioningState(
          phase: HubProvisioningPhase.success,
          spaceId: 'space-1',
          storeId: 'store-1',
          spaceName: 'Main Hall',
          binding: _binding(
            deviceLocationStatus: HubDeviceLocationStatus.deviceSyncPending,
            deviceLocationLastError: 'custom-location failed',
            deviceLocation: HubDeviceLocation(
              latitude: 10.7769,
              longitude: 106.7009,
              city: 'Ho Chi Minh City',
              source: HubDeviceLocationSource.phoneGps,
              capturedAtUtc: DateTime.utc(2026, 4, 4, 10, 5),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Location sync'), findsOneWidget);
      expect(find.text('Ho Chi Minh City'), findsOneWidget);
      expect(find.text('10.77690, 106.70090'), findsOneWidget);
      expect(find.text('Retry location sync'), findsOneWidget);
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

    testWidgets('renders location review card', (tester) async {
      await tester.pumpWidget(_buildTestApp(bloc));
      bloc.push(
        HubProvisioningState(
          phase: HubProvisioningPhase.reviewLocation,
          flowMode: HubProvisioningFlowMode.fullProvisioning,
          spaceId: 'space-1',
          storeId: 'store-1',
          spaceName: 'Main Hall',
          draftLocation: HubDeviceLocation(
            latitude: 10.7769,
            longitude: 106.7009,
            city: 'Ho Chi Minh City',
            source: HubDeviceLocationSource.phoneGps,
            capturedAtUtc: DateTime.utc(2026, 4, 4, 10, 5),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Device location'), findsOneWidget);
      expect(find.text('Use current location'), findsOneWidget);
      expect(find.text('Save to ESP'), findsOneWidget);
      expect(find.text('Current source: Phone GPS'), findsOneWidget);
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
  HubDeviceLocationStatus deviceLocationStatus =
      HubDeviceLocationStatus.unknown,
  HubDeviceLocation? deviceLocation,
  String? deviceLocationLastError,
}) {
  return SpaceHubBinding(
    spaceId: 'space-1',
    bleDeviceName: 'CAM-ESP32-01',
    wifiSsid: 'Store WiFi',
    provisioningMethod: HubProvisioningMethod.blePrefixScan,
    provisionedAtUtc: DateTime.parse('2026-04-04T10:00:00.000Z'),
    status: status,
    deviceLocation: deviceLocation,
    deviceLocationStatus: deviceLocationStatus,
    deviceLocationLastError: deviceLocationLastError,
    deviceLocationUpdatedAtUtc: deviceLocation?.capturedAtUtc,
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
      proofOfPossession: proofOfPossession,
      source: EspProvisioningIdentitySource.blePrefixScan,
    );
  }
}
