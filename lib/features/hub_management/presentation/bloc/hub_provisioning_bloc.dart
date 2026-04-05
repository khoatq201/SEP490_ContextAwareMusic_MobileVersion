import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/ble_permission_service.dart';
import '../../data/services/ble_provisioning_service.dart';
import '../../data/services/location_capture_service.dart';
import '../../data/services/provisioning_identity_resolver.dart';
import '../../domain/entities/ble_candidate.dart';
import '../../domain/entities/hub_device_location.dart';
import '../../domain/entities/space_hub_binding.dart';
import '../../domain/entities/wifi_candidate.dart';
import '../../domain/usecases/space_hub_usecases.dart';
import 'hub_provisioning_event.dart';
import 'hub_provisioning_state.dart';

class HubProvisioningBloc
    extends Bloc<HubProvisioningEvent, HubProvisioningState> {
  HubProvisioningBloc({
    required this.getSpaceHubBinding,
    required this.upsertSpaceHubBinding,
    required this.deleteSpaceHubBinding,
    required this.restartSpaceHub,
    required this.bleProvisioningService,
    required this.blePermissionService,
    required this.locationCaptureService,
    required this.identityResolver,
    bool Function()? isAndroid,
  })  : _isAndroid = isAndroid ?? (() => Platform.isAndroid),
        super(const HubProvisioningState()) {
    on<HubProvisioningStarted>(_onStarted);
    on<HubProvisioningPermissionRequested>(_onPermissionRequested);
    on<HubProvisioningBleScanRequested>(_onBleScanRequested);
    on<HubProvisioningBleCandidateSelected>(_onBleCandidateSelected);
    on<HubProvisioningSecretCodeSubmitted>(_onSecretCodeSubmitted);
    on<HubProvisioningUseCurrentLocationRequested>(
      _onUseCurrentLocationRequested,
    );
    on<HubProvisioningCredentialsSubmitted>(_onCredentialsSubmitted);
    on<HubProvisioningLocationSubmitted>(_onLocationSubmitted);
    on<HubProvisioningRetrySyncRequested>(_onRetrySyncRequested);
    on<HubProvisioningDeleteBindingRequested>(_onDeleteBindingRequested);
    on<HubProvisioningRestartRequested>(_onRestartRequested);
  }

  final GetSpaceHubBinding getSpaceHubBinding;
  final UpsertSpaceHubBinding upsertSpaceHubBinding;
  final DeleteSpaceHubBinding deleteSpaceHubBinding;
  final RestartSpaceHub restartSpaceHub;
  final BleProvisioningService bleProvisioningService;
  final BlePermissionService blePermissionService;
  final LocationCaptureService locationCaptureService;
  final ProvisioningIdentityResolver identityResolver;
  final bool Function() _isAndroid;

  Future<void> _onStarted(
    HubProvisioningStarted event,
    Emitter<HubProvisioningState> emit,
  ) async {
    emit(
      state.copyWith(
        phase: HubProvisioningPhase.loading,
        flowMode: HubProvisioningFlowMode.fullProvisioning,
        spaceId: event.spaceId,
        storeId: event.storeId,
        spaceName: event.spaceName,
        clearBinding: true,
        clearMessage: true,
        clearSelectedBleCandidate: true,
        clearResolvedIdentity: true,
        clearPendingWifiSsid: true,
        clearDraftLocation: true,
        bleCandidates: const <BleCandidate>[],
        wifiCandidates: const <WifiCandidate>[],
      ),
    );

    final bindingResult = await getSpaceHubBinding(event.spaceId);
    final binding = bindingResult.fold((_) => null, (value) => value);

    if (!_isAndroid()) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.success,
          binding: binding,
          message: 'Provisioning tools are available on Android only.',
          isPermissionPermanentlyDenied: false,
        ),
      );
      return;
    }

    if (binding != null) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.success,
          binding: binding,
          message: _buildExistingBindingMessage(binding),
          clearMessage: _buildExistingBindingMessage(binding) == null,
        ),
      );
      return;
    }

    final permissionStatus = await blePermissionService.checkStatus();
    if (permissionStatus != BlePermissionRequirementStatus.granted) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.permissionRequired,
          clearBinding: true,
          isPermissionPermanentlyDenied: permissionStatus ==
              BlePermissionRequirementStatus.permanentlyDenied,
          message: permissionStatus ==
                  BlePermissionRequirementStatus.permanentlyDenied
              ? 'Bluetooth permissions are permanently denied. Open app settings to continue.'
              : 'Bluetooth permissions are required to scan CAM provisioning devices.',
        ),
      );
      return;
    }

    add(const HubProvisioningBleScanRequested());
  }

  Future<void> _onPermissionRequested(
    HubProvisioningPermissionRequested event,
    Emitter<HubProvisioningState> emit,
  ) async {
    final permissionStatus = await blePermissionService.requestPermissions();
    if (permissionStatus == BlePermissionRequirementStatus.granted) {
      add(
        HubProvisioningBleScanRequested(
          flowMode: state.flowMode,
          initialLocation:
              state.isUpdateLocationOnly ? state.draftLocation : null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        phase: HubProvisioningPhase.permissionRequired,
        isPermissionPermanentlyDenied: permissionStatus ==
            BlePermissionRequirementStatus.permanentlyDenied,
        message: permissionStatus ==
                BlePermissionRequirementStatus.permanentlyDenied
            ? 'Bluetooth permissions are permanently denied. Open app settings to continue.'
            : 'Bluetooth permissions are still required before scanning CAM devices.',
      ),
    );
  }

  Future<void> _onBleScanRequested(
    HubProvisioningBleScanRequested event,
    Emitter<HubProvisioningState> emit,
  ) async {
    if (!_isAndroid()) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.failure,
          flowMode: HubProvisioningFlowMode.fullProvisioning,
          message:
              'ESP provisioning is only supported on Android for this build.',
        ),
      );
      return;
    }

    final permissionStatus = await blePermissionService.checkStatus();
    if (permissionStatus != BlePermissionRequirementStatus.granted) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.permissionRequired,
          flowMode: event.flowMode,
          isPermissionPermanentlyDenied: permissionStatus ==
              BlePermissionRequirementStatus.permanentlyDenied,
          message: 'Bluetooth permissions are required to scan CAM devices.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        phase: HubProvisioningPhase.scanningBle,
        flowMode: event.flowMode,
        clearMessage: true,
        clearSelectedBleCandidate: true,
        clearResolvedIdentity: true,
        clearPendingWifiSsid: true,
        draftLocation: event.initialLocation,
        clearDraftLocation: event.initialLocation == null,
        bleCandidates: const <BleCandidate>[],
        wifiCandidates: const <WifiCandidate>[],
      ),
    );

    try {
      final candidates =
          await bleProvisioningService.scanDevices(identityResolver.blePrefix);
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.selectDevice,
          bleCandidates: candidates,
          wifiCandidates: const <WifiCandidate>[],
          message: candidates.isEmpty
              ? 'No CAM devices found. Make sure the ESP32 is in provisioning mode and Bluetooth is enabled.'
              : null,
          clearMessage: candidates.isNotEmpty,
        ),
      );
    } on BleProvisioningException catch (error) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.failure,
          flowMode: HubProvisioningFlowMode.fullProvisioning,
          message:
              'Unable to scan BLE devices. Turn on Bluetooth and try again.\n$error',
        ),
      );
    }
  }

  Future<void> _onBleCandidateSelected(
    HubProvisioningBleCandidateSelected event,
    Emitter<HubProvisioningState> emit,
  ) async {
    emit(
      state.copyWith(
        phase: HubProvisioningPhase.enterSecretCode,
        selectedBleCandidate: event.candidate,
        clearResolvedIdentity: true,
        clearMessage: true,
        clearPendingWifiSsid: true,
        wifiCandidates: const <WifiCandidate>[],
      ),
    );
  }

  Future<void> _onSecretCodeSubmitted(
    HubProvisioningSecretCodeSubmitted event,
    Emitter<HubProvisioningState> emit,
  ) async {
    final candidate = state.selectedBleCandidate;
    if (candidate == null) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.failure,
          flowMode: HubProvisioningFlowMode.fullProvisioning,
          message: 'Choose a CAM device before entering the secret code.',
        ),
      );
      return;
    }

    final secretCode = event.secretCode.trim();
    if (secretCode.isEmpty) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.enterSecretCode,
          clearResolvedIdentity: true,
          wifiCandidates: const <WifiCandidate>[],
          message: 'Enter the secret code before continuing.',
        ),
      );
      return;
    }

    final identity = await identityResolver.resolve(
      candidate,
      proofOfPossession: secretCode,
    );

    if (state.isUpdateLocationOnly) {
      emit(
        state.copyWith(
          phase: state.draftLocation == null
              ? HubProvisioningPhase.resolvingLocation
              : HubProvisioningPhase.reviewLocation,
          resolvedIdentity: identity,
          clearMessage: true,
        ),
      );

      if (state.draftLocation == null) {
        await _captureCurrentLocation(emit);
      }
      return;
    }

    emit(
      state.copyWith(
        phase: HubProvisioningPhase.scanningWifi,
        resolvedIdentity: identity,
        clearMessage: true,
        wifiCandidates: const <WifiCandidate>[],
      ),
    );

    try {
      final wifiCandidates =
          await bleProvisioningService.scanWifiNetworks(identity);
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.enterWifi,
          wifiCandidates: wifiCandidates,
          message: wifiCandidates.isEmpty
              ? 'No Wi-Fi networks were returned by the ESP32. You can still enter an SSID manually.'
              : null,
          clearMessage: wifiCandidates.isNotEmpty,
        ),
      );
    } on BleProvisioningException catch (error) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.enterSecretCode,
          clearResolvedIdentity: true,
          wifiCandidates: const <WifiCandidate>[],
          message:
              'Unable to read Wi-Fi networks from the selected ESP32. Check the secret code and try again.\n$error',
        ),
      );
    }
  }

  Future<void> _onUseCurrentLocationRequested(
    HubProvisioningUseCurrentLocationRequested event,
    Emitter<HubProvisioningState> emit,
  ) async {
    final identity = state.resolvedIdentity;
    if (identity == null) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.enterSecretCode,
          message:
              'Enter the secret code before capturing the device location.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        phase: HubProvisioningPhase.resolvingLocation,
        clearMessage: true,
      ),
    );
    await _captureCurrentLocation(emit);
  }

  Future<void> _onCredentialsSubmitted(
    HubProvisioningCredentialsSubmitted event,
    Emitter<HubProvisioningState> emit,
  ) async {
    final identity = state.resolvedIdentity;
    if (identity == null) {
      emit(
        state.copyWith(
          phase: state.selectedBleCandidate == null
              ? HubProvisioningPhase.failure
              : HubProvisioningPhase.enterSecretCode,
          flowMode: HubProvisioningFlowMode.fullProvisioning,
          message: state.selectedBleCandidate == null
              ? 'Choose a CAM device before sending Wi-Fi credentials.'
              : 'Enter the secret code before sending Wi-Fi credentials.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        phase: HubProvisioningPhase.provisioning,
        clearMessage: true,
      ),
    );

    try {
      final didProvision = await bleProvisioningService.provisionWifi(
        identity,
        ssid: event.ssid,
        passphrase: event.passphrase,
      );
      if (!didProvision) {
        emit(
          state.copyWith(
            phase: HubProvisioningPhase.failure,
            flowMode: HubProvisioningFlowMode.fullProvisioning,
            message:
                'The ESP32 did not confirm the Wi-Fi credentials. Check the password and try again.',
          ),
        );
        return;
      }

      final candidate = state.selectedBleCandidate;
      if (candidate == null) {
        emit(
          state.copyWith(
            phase: HubProvisioningPhase.failure,
            flowMode: HubProvisioningFlowMode.fullProvisioning,
            message:
                'Provisioning completed locally, but the selected device context was lost.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          phase: HubProvisioningPhase.resolvingLocation,
          pendingWifiSsid: event.ssid,
          clearDraftLocation: true,
          clearMessage: true,
        ),
      );
      await _captureCurrentLocation(emit);
    } on BleProvisioningException catch (error) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.failure,
          flowMode: HubProvisioningFlowMode.fullProvisioning,
          message:
              'Provisioning failed before the ESP32 confirmed Wi-Fi.\n$error',
        ),
      );
    }
  }

  Future<void> _onLocationSubmitted(
    HubProvisioningLocationSubmitted event,
    Emitter<HubProvisioningState> emit,
  ) async {
    final identity = state.resolvedIdentity;
    if (identity == null) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.enterSecretCode,
          message: 'Enter the secret code before saving the device location.',
        ),
      );
      return;
    }

    final location = HubDeviceLocation(
      latitude: event.latitude,
      longitude: event.longitude,
      city: event.city.trim(),
      source: event.source,
      capturedAtUtc: DateTime.now().toUtc(),
    );

    emit(
      state.copyWith(
        phase: HubProvisioningPhase.sendingLocation,
        draftLocation: location,
        clearMessage: true,
      ),
    );

    try {
      await bleProvisioningService.sendCustomData(
        identity,
        endpoint: 'custom-location',
        payload: _buildLocationPayload(location),
      );

      await _persistBindingAfterLocationAttempt(
        emit,
        location: location,
        deviceLocationStatus: HubDeviceLocationStatus.configured,
      );
    } on BleProvisioningException catch (error) {
      await _persistBindingAfterLocationAttempt(
        emit,
        location: location,
        deviceLocationStatus: HubDeviceLocationStatus.deviceSyncPending,
        deviceLocationLastError: error.message,
      );
    }
  }

  Future<void> _onRetrySyncRequested(
    HubProvisioningRetrySyncRequested event,
    Emitter<HubProvisioningState> emit,
  ) async {
    final binding = state.binding;
    if (binding == null) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.failure,
          flowMode: HubProvisioningFlowMode.fullProvisioning,
          message: 'No local hub binding is available to retry.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        phase: HubProvisioningPhase.syncing,
        clearMessage: true,
      ),
    );

    final result = await upsertSpaceHubBinding(
      binding.copyWith(
        clearLastError: true,
        clearDeviceLocationLastError: !binding.isDeviceLocationSyncPending,
      ),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          phase: HubProvisioningPhase.failure,
          flowMode: HubProvisioningFlowMode.fullProvisioning,
          message: failure.message,
        ),
      ),
      (savedBinding) => emit(
        state.copyWith(
          phase: HubProvisioningPhase.success,
          flowMode: HubProvisioningFlowMode.fullProvisioning,
          binding: savedBinding,
          didMutateBinding: true,
          message: savedBinding.isSyncPending
              ? 'Sync is still pending. You can retry again later without resending Wi-Fi credentials.'
              : savedBinding.isDeviceLocationSyncPending
                  ? 'Backend sync succeeded. Device location still needs to be sent to the ESP32.'
                  : 'Hub binding synced successfully.',
        ),
      ),
    );
  }

  Future<void> _onDeleteBindingRequested(
    HubProvisioningDeleteBindingRequested event,
    Emitter<HubProvisioningState> emit,
  ) async {
    final result = await deleteSpaceHubBinding(state.spaceId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          phase: HubProvisioningPhase.failure,
          flowMode: HubProvisioningFlowMode.fullProvisioning,
          message: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          phase: HubProvisioningPhase.success,
          flowMode: HubProvisioningFlowMode.fullProvisioning,
          clearBinding: true,
          didMutateBinding: true,
          clearSelectedBleCandidate: true,
          clearResolvedIdentity: true,
          clearPendingWifiSsid: true,
          clearDraftLocation: true,
          bleCandidates: const <BleCandidate>[],
          wifiCandidates: const <WifiCandidate>[],
          message: 'Hub binding removed from this space.',
        ),
      ),
    );
  }

  Future<void> _onRestartRequested(
    HubProvisioningRestartRequested event,
    Emitter<HubProvisioningState> emit,
  ) async {
    final result = await restartSpaceHub(state.spaceId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          phase: HubProvisioningPhase.failure,
          flowMode: HubProvisioningFlowMode.fullProvisioning,
          message: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          phase: HubProvisioningPhase.success,
          flowMode: HubProvisioningFlowMode.fullProvisioning,
          message: 'Restart request queued for the configured hub.',
        ),
      ),
    );
  }

  Future<void> _captureCurrentLocation(
    Emitter<HubProvisioningState> emit,
  ) async {
    try {
      final location = await locationCaptureService.captureCurrentLocation();
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.reviewLocation,
          draftLocation: location,
          message: location.city.trim().isEmpty ||
                  location.displayCity == 'Unknown'
              ? 'Current coordinates were captured. Update the city if needed before saving to the ESP32.'
              : null,
          clearMessage: location.city.trim().isNotEmpty &&
              location.displayCity != 'Unknown',
        ),
      );
    } on LocationCaptureException catch (error) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.reviewLocation,
          message: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.reviewLocation,
          message:
              'Unable to capture the current location automatically. You can still enter the location manually.',
        ),
      );
    }
  }

  Future<void> _persistBindingAfterLocationAttempt(
    Emitter<HubProvisioningState> emit, {
    required HubDeviceLocation location,
    required HubDeviceLocationStatus deviceLocationStatus,
    String? deviceLocationLastError,
  }) async {
    final didConfigureWifiNow =
        state.flowMode == HubProvisioningFlowMode.fullProvisioning;
    final bindingToSave = _buildBindingForLocationAttempt(
      location: location,
      deviceLocationStatus: deviceLocationStatus,
      deviceLocationLastError: deviceLocationLastError,
    );
    if (bindingToSave == null) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.failure,
          flowMode: HubProvisioningFlowMode.fullProvisioning,
          message:
              'The hub configuration completed locally, but the binding payload could not be assembled.',
        ),
      );
      return;
    }

    emit(state.copyWith(phase: HubProvisioningPhase.syncing));
    final bindingResult = await upsertSpaceHubBinding(bindingToSave);
    bindingResult.fold(
      (failure) => emit(
        state.copyWith(
          phase: HubProvisioningPhase.failure,
          flowMode: HubProvisioningFlowMode.fullProvisioning,
          message: failure.message,
        ),
      ),
      (binding) => emit(
        state.copyWith(
          phase: HubProvisioningPhase.success,
          flowMode: HubProvisioningFlowMode.fullProvisioning,
          binding: binding,
          didMutateBinding: true,
          clearSelectedBleCandidate: true,
          clearResolvedIdentity: true,
          clearPendingWifiSsid: true,
          draftLocation: binding.deviceLocation ?? location,
          bleCandidates: const <BleCandidate>[],
          wifiCandidates: const <WifiCandidate>[],
          message: _buildSuccessMessage(
            binding,
            didConfigureWifiNow: didConfigureWifiNow,
          ),
        ),
      ),
    );
  }

  SpaceHubBinding? _buildBindingForLocationAttempt({
    required HubDeviceLocation location,
    required HubDeviceLocationStatus deviceLocationStatus,
    String? deviceLocationLastError,
  }) {
    final locationUpdatedAtUtc = DateTime.now().toUtc();
    final existingBinding = state.binding;
    if (existingBinding != null) {
      return existingBinding.copyWith(
        status: SpaceHubBindingStatus.bound,
        deviceLocation: location,
        deviceLocationStatus: deviceLocationStatus,
        deviceLocationLastError: deviceLocationLastError,
        clearDeviceLocationLastError: deviceLocationLastError == null,
        deviceLocationUpdatedAtUtc: locationUpdatedAtUtc,
      );
    }

    final candidate = state.selectedBleCandidate;
    final wifiSsid = state.pendingWifiSsid?.trim();
    if (candidate == null || wifiSsid == null || wifiSsid.isEmpty) {
      return null;
    }

    return SpaceHubBinding(
      spaceId: state.spaceId,
      bleDeviceName: candidate.bleDeviceName,
      wifiSsid: wifiSsid,
      provisioningMethod: HubProvisioningMethod.blePrefixScan,
      provisionedAtUtc: DateTime.now().toUtc(),
      status: SpaceHubBindingStatus.bound,
      deviceLocation: location,
      deviceLocationStatus: deviceLocationStatus,
      deviceLocationLastError: deviceLocationLastError,
      deviceLocationUpdatedAtUtc: locationUpdatedAtUtc,
    );
  }

  Uint8List _buildLocationPayload(HubDeviceLocation location) {
    final payload = jsonEncode(
      {
        'lat': location.latitude,
        'lon': location.longitude,
        'city': location.displayCity,
      },
    );
    return Uint8List.fromList(utf8.encode(payload));
  }

  String? _buildExistingBindingMessage(SpaceHubBinding binding) {
    if (binding.isDeviceLocationSyncPending) {
      return 'Hub binding is ready, but device location still needs to be sent to the ESP32.';
    }
    if (binding.isSyncPending) {
      return 'Provisioned locally. Backend sync is still pending.';
    }
    return null;
  }

  String _buildSuccessMessage(
    SpaceHubBinding binding, {
    required bool didConfigureWifiNow,
  }) {
    if (binding.isDeviceLocationSyncPending) {
      return didConfigureWifiNow
          ? 'Wi-Fi was sent to the ESP32. Device location still needs to be synced.'
          : 'Device location was saved locally and still needs to be sent to the ESP32.';
    }
    if (binding.isSyncPending) {
      return didConfigureWifiNow
          ? 'ESP32 configured with Wi-Fi and device location. Backend sync is still pending.'
          : 'Device location updated on the ESP32. Backend sync is still pending.';
    }
    return didConfigureWifiNow
        ? 'ESP32 configured with Wi-Fi and device location for this space.'
        : 'Device location updated successfully.';
  }
}
