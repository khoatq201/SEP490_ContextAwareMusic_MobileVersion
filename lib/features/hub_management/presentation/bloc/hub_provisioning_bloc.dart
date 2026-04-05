import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/ble_permission_service.dart';
import '../../data/services/ble_provisioning_service.dart';
import '../../data/services/provisioning_identity_resolver.dart';
import '../../domain/entities/ble_candidate.dart';
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
    required this.identityResolver,
    bool Function()? isAndroid,
  })  : _isAndroid = isAndroid ?? (() => Platform.isAndroid),
        super(const HubProvisioningState()) {
    on<HubProvisioningStarted>(_onStarted);
    on<HubProvisioningPermissionRequested>(_onPermissionRequested);
    on<HubProvisioningBleScanRequested>(_onBleScanRequested);
    on<HubProvisioningBleCandidateSelected>(_onBleCandidateSelected);
    on<HubProvisioningCredentialsSubmitted>(_onCredentialsSubmitted);
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
  final ProvisioningIdentityResolver identityResolver;
  final bool Function() _isAndroid;

  Future<void> _onStarted(
    HubProvisioningStarted event,
    Emitter<HubProvisioningState> emit,
  ) async {
    emit(
      state.copyWith(
        phase: HubProvisioningPhase.loading,
        spaceId: event.spaceId,
        storeId: event.storeId,
        spaceName: event.spaceName,
        clearMessage: true,
        clearSelectedBleCandidate: true,
        clearResolvedIdentity: true,
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
          message: binding.isSyncPending
              ? 'Provisioned locally. Backend sync is still pending.'
              : null,
          clearMessage: !binding.isSyncPending,
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
      add(const HubProvisioningBleScanRequested());
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
        clearMessage: true,
        clearSelectedBleCandidate: true,
        clearResolvedIdentity: true,
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
        phase: HubProvisioningPhase.scanningWifi,
        selectedBleCandidate: event.candidate,
        clearMessage: true,
        wifiCandidates: const <WifiCandidate>[],
      ),
    );

    try {
      final identity = await identityResolver.resolve(event.candidate);
      final wifiCandidates =
          await bleProvisioningService.scanWifiNetworks(identity);
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.enterWifi,
          resolvedIdentity: identity,
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
          phase: HubProvisioningPhase.failure,
          message:
              'Unable to read Wi-Fi networks from the selected ESP32.\n$error',
        ),
      );
    }
  }

  Future<void> _onCredentialsSubmitted(
    HubProvisioningCredentialsSubmitted event,
    Emitter<HubProvisioningState> emit,
  ) async {
    final identity = state.resolvedIdentity;
    if (identity == null) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.failure,
          message: 'Choose a CAM device before sending Wi-Fi credentials.',
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
            message:
                'Provisioning completed locally, but the selected device context was lost.',
          ),
        );
        return;
      }

      emit(state.copyWith(phase: HubProvisioningPhase.syncing));
      final bindingResult = await upsertSpaceHubBinding(
        SpaceHubBinding(
          spaceId: state.spaceId,
          bleDeviceName: candidate.bleDeviceName,
          wifiSsid: event.ssid,
          provisioningMethod: HubProvisioningMethod.blePrefixScan,
          provisionedAtUtc: DateTime.now().toUtc(),
          status: SpaceHubBindingStatus.bound,
        ),
      );

      bindingResult.fold(
        (failure) => emit(
          state.copyWith(
            phase: HubProvisioningPhase.failure,
            message: failure.message,
          ),
        ),
        (binding) => emit(
          state.copyWith(
            phase: HubProvisioningPhase.success,
            binding: binding,
            didMutateBinding: true,
            message: binding.isSyncPending
                ? 'Wi-Fi was sent to the ESP32 successfully. Backend sync is still pending.'
                : 'ESP32 configured successfully for this space.',
            bleCandidates: const <BleCandidate>[],
            wifiCandidates: const <WifiCandidate>[],
          ),
        ),
      );
    } on BleProvisioningException catch (error) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.failure,
          message:
              'Provisioning failed before the ESP32 confirmed Wi-Fi.\n$error',
        ),
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
      binding.copyWith(clearLastError: true),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          phase: HubProvisioningPhase.failure,
          message: failure.message,
        ),
      ),
      (savedBinding) => emit(
        state.copyWith(
          phase: HubProvisioningPhase.success,
          binding: savedBinding,
          didMutateBinding: true,
          message: savedBinding.isSyncPending
              ? 'Sync is still pending. You can retry again later without resending Wi-Fi credentials.'
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
          message: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          phase: HubProvisioningPhase.success,
          clearBinding: true,
          didMutateBinding: true,
          clearSelectedBleCandidate: true,
          clearResolvedIdentity: true,
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
          message: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          phase: HubProvisioningPhase.success,
          message: 'Restart request queued for the configured hub.',
        ),
      ),
    );
  }
}
