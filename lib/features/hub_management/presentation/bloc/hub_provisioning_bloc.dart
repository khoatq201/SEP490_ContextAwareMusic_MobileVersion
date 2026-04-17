import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/ble_permission_service.dart';
import '../../data/services/ble_provisioning_service.dart';
import '../../data/services/location_capture_service.dart';
import '../../data/services/provisioning_identity_resolver.dart';
import '../../../locations/data/datasources/location_remote_datasource.dart';
import '../../../locations/domain/usecases/location_usecases.dart';
import '../../domain/entities/ble_candidate.dart';
import '../../domain/entities/esp_provisioning_identity.dart';
import '../../domain/entities/space_hub_binding.dart';
import '../../domain/entities/wifi_candidate.dart';
import '../../domain/usecases/space_hub_usecases.dart';
import 'hub_provisioning_event.dart';
import 'hub_provisioning_state.dart';

class _NvrChannelDiscoveryResult {
  const _NvrChannelDiscoveryResult({
    required this.channels,
    required this.scanComplete,
  });

  final List<NvrChannelPreview> channels;
  final bool scanComplete;
}

class HubProvisioningBloc
    extends Bloc<HubProvisioningEvent, HubProvisioningState> {
  HubProvisioningBloc({
    required this.getSpaceHubBinding,
    required this.upsertSpaceHubBinding,
    required this.deleteSpaceHubBinding,
    required this.restartSpaceHub,
    required this.updateSpace,
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
    on<HubProvisioningCredentialsSubmitted>(_onCredentialsSubmitted);
    on<HubProvisioningNvrConfigSubmitted>(_onNvrConfigSubmitted);
    on<HubProvisioningNvrChannelSelected>(_onNvrChannelSelected);
    on<HubProvisioningNvrChannelsRefreshRequested>(
        _onNvrChannelsRefreshRequested);
    on<HubProvisioningRetrySyncRequested>(_onRetrySyncRequested);
    on<HubProvisioningDeleteBindingRequested>(_onDeleteBindingRequested);
    on<HubProvisioningRestartRequested>(_onRestartRequested);
  }

  final GetSpaceHubBinding getSpaceHubBinding;
  final UpsertSpaceHubBinding upsertSpaceHubBinding;
  final DeleteSpaceHubBinding deleteSpaceHubBinding;
  final RestartSpaceHub restartSpaceHub;
  final UpdateSpace updateSpace;
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
        clearPendingWifiPassphrase: true,
        nvrChannels: const <NvrChannelPreview>[],
        clearNvrPreviewBaseUrl: true,
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
        clearPendingWifiPassphrase: true,
        nvrChannels: const <NvrChannelPreview>[],
        clearNvrPreviewBaseUrl: true,
        clearDraftLocation: true,
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
    } on BleProvisioningException {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.failure,
          flowMode: HubProvisioningFlowMode.fullProvisioning,
          message:
              'Unable to scan CAM devices right now. Turn on Bluetooth and try again.',
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
        clearPendingWifiPassphrase: true,
        nvrChannels: const <NvrChannelPreview>[],
        clearNvrPreviewBaseUrl: true,
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
              ? 'No Wi-Fi networks were returned by the ESP32. This list comes from the device, not the phone, so hidden, weak, or 5 GHz networks may not appear. You can still enter a 2.4 GHz SSID manually.'
              : null,
          clearMessage: wifiCandidates.isNotEmpty,
        ),
      );
    } on BleProvisioningException {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.enterSecretCode,
          clearResolvedIdentity: true,
          wifiCandidates: const <WifiCandidate>[],
          message:
              'Unable to read Wi-Fi networks from the selected ESP32. Check the secret code and try again. This scan is performed by the ESP32 itself, so move closer to the device and confirm it is still in provisioning mode.',
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
        phase: HubProvisioningPhase.enterNvrConfig,
        pendingWifiSsid: event.ssid,
        pendingWifiPassphrase: event.passphrase,
        message:
            'Wi-Fi details are ready. Send NVR config first, then the app will finalize Wi-Fi provisioning.',
      ),
    );
  }

  Future<void> _onNvrConfigSubmitted(
    HubProvisioningNvrConfigSubmitted event,
    Emitter<HubProvisioningState> emit,
  ) async {
    final identity = state.resolvedIdentity;
    final candidate = state.selectedBleCandidate;
    final wifiSsid = state.pendingWifiSsid;
    final wifiPassphrase = state.pendingWifiPassphrase;
    if (identity == null ||
        candidate == null ||
        wifiSsid == null ||
        wifiPassphrase == null) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.failure,
          flowMode: HubProvisioningFlowMode.fullProvisioning,
          message:
              'Wi-Fi completed, but the BLE provisioning context was lost before NVR setup.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        phase: HubProvisioningPhase.sendingNvrConfig,
        clearMessage: true,
      ),
    );

    final payload = <String, Object?>{
      'device_id': identity.deviceId,
      'wifi_ssid': wifiSsid,
      'wifi_passphrase': wifiPassphrase,
      'mode': event.mode,
      'username': event.username.trim(),
      'password': event.password,
      'host': event.host.trim(),
      'port': event.port,
    };

    try {
      final responseBytes = await bleProvisioningService.sendCustomData(
        identity,
        endpoint: 'nvr-config',
        payload: Uint8List.fromList(utf8.encode(jsonEncode(payload))),
      );
      final response = utf8.decode(responseBytes, allowMalformed: true);
      if (!response.contains('"ok"') && !response.contains('ok')) {
        emit(
          state.copyWith(
            phase: HubProvisioningPhase.enterNvrConfig,
            message: 'ESP32 rejected the NVR config: $response',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          phase: HubProvisioningPhase.discoveringNvrChannels,
          message:
              'ESP32 is joining Wi-Fi and preparing camera previews. Keep this screen open.',
          nvrChannels: const <NvrChannelPreview>[],
          clearNvrPreviewBaseUrl: true,
        ),
      );
      final previewBaseUrl = await _waitForNvrPreviewBaseUrl(identity);
      final channels = await _waitForNvrChannels(previewBaseUrl);
      if (channels.isEmpty) {
        emit(
          state.copyWith(
            phase: HubProvisioningPhase.enterNvrConfig,
            message:
                'ESP32 connected, but no camera snapshots were available. Check the NVR credentials or network, then try again.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          phase: HubProvisioningPhase.selectNvrChannel,
          nvrChannels: channels,
          nvrPreviewBaseUrl: previewBaseUrl,
          message:
              'Choose the camera view for people counting. The ESP32 will only analyze the selected channel.',
        ),
      );
    } on BleProvisioningException catch (error) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.enterNvrConfig,
          message:
              'Unable to send NVR config over BLE: ${error.message}. Keep the ESP32 close and try again.',
        ),
      );
    } on TimeoutException catch (error) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.enterNvrConfig,
          message:
              'ESP32 did not become reachable for preview in time: ${error.message ?? 'timeout'}.',
        ),
      );
    } on SocketException catch (error) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.enterNvrConfig,
          message:
              'The phone could not reach the ESP32 preview server on the Wi-Fi network: ${error.message}.',
        ),
      );
    } on FormatException catch (error) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.enterNvrConfig,
          message:
              'ESP32 preview response was not valid JSON: ${error.message}.',
        ),
      );
    }
  }

  Future<void> _onNvrChannelsRefreshRequested(
    HubProvisioningNvrChannelsRefreshRequested event,
    Emitter<HubProvisioningState> emit,
  ) async {
    final previewBaseUrl = state.nvrPreviewBaseUrl;
    if (previewBaseUrl == null || previewBaseUrl.trim().isEmpty) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.enterNvrConfig,
          message: 'Preview server address is missing. Send NVR config again.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        phase: HubProvisioningPhase.discoveringNvrChannels,
        message: 'Refreshing camera previews.',
      ),
    );

    try {
      final channels = await _waitForNvrChannels(
        previewBaseUrl,
        forceRefresh: true,
      );
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.selectNvrChannel,
          nvrChannels: channels,
          message:
              'Choose the camera view for people counting. The ESP32 will only analyze the selected channel.',
        ),
      );
    } on SocketException catch (error) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.selectNvrChannel,
          message: 'Unable to refresh camera previews: ${error.message}.',
        ),
      );
    } on FormatException catch (error) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.selectNvrChannel,
          message:
              'Camera preview response was not valid JSON: ${error.message}.',
        ),
      );
    }
  }

  Future<void> _onNvrChannelSelected(
    HubProvisioningNvrChannelSelected event,
    Emitter<HubProvisioningState> emit,
  ) async {
    final identity = state.resolvedIdentity;
    final candidate = state.selectedBleCandidate;
    final wifiSsid = state.pendingWifiSsid;
    if (identity == null || candidate == null || wifiSsid == null) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.failure,
          message:
              'The BLE provisioning context was lost before saving the selected camera view.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        phase: HubProvisioningPhase.sendingNvrChannelSelection,
        clearMessage: true,
      ),
    );

    final payload = <String, Object?>{
      'selected_channel': event.selectedChannel,
    };

    try {
      final responseBytes = await bleProvisioningService.sendCustomData(
        identity,
        endpoint: 'nvr-select',
        payload: Uint8List.fromList(utf8.encode(jsonEncode(payload))),
      );
      final response = utf8.decode(responseBytes, allowMalformed: true);
      if (!response.contains('"ok"') && !response.contains('ok')) {
        emit(
          state.copyWith(
            phase: HubProvisioningPhase.selectNvrChannel,
            message: 'ESP32 rejected the selected camera channel: $response',
          ),
        );
        return;
      }

      final iotDeviceId = await _loadEspIotDeviceId(identity) ??
          identity.deviceId;

      await _persistBindingAfterWifiProvisioning(
        emit,
        candidate: candidate,
        wifiSsid: wifiSsid,
        iotDeviceId: iotDeviceId,
      );
    } on BleProvisioningException catch (error) {
      emit(
        state.copyWith(
          phase: HubProvisioningPhase.selectNvrChannel,
          message:
              'Unable to save selected camera channel over BLE: ${error.message}.',
        ),
      );
    }
  }

  Future<String> _waitForNvrPreviewBaseUrl(
    EspProvisioningIdentity identity,
  ) async {
    for (var attempt = 0; attempt < 180; attempt++) {
      try {
        final responseBytes = await bleProvisioningService.sendCustomData(
          identity,
          endpoint: 'nvr-status',
          payload: Uint8List.fromList(utf8.encode('{}')),
        );
        final response = utf8.decode(responseBytes, allowMalformed: true);
        final status = jsonDecode(response) as Map<String, dynamic>;
        final wifiConnected =
            status['wifi'] == 1 || status['wifi_connected'] == true;
        final previewStarted =
            status['preview'] == 1 || status['preview_server_started'] == true;
        final nvrIp = ((status['nvr'] ?? status['nvr_ip']) as String?)?.trim();
        final nvrDiscovered = status['nvr_discovered'] == true ||
            (nvrIp != null && nvrIp.isNotEmpty);
        final espIp = ((status['ip'] ?? status['esp_ip']) as String?)?.trim();
        final previewPort =
            ((status['port'] ?? status['preview_port']) as num?)?.toInt() ??
                8080;
        if (wifiConnected &&
            previewStarted &&
            nvrDiscovered &&
            espIp != null &&
            espIp.isNotEmpty) {
          return 'http://$espIp:$previewPort';
        }
      } on BleProvisioningException {
        if (attempt > 12) rethrow;
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    throw TimeoutException(
        'waiting for ESP32 NVR discovery and preview server');
  }

  Future<String?> _loadEspIotDeviceId(
    EspProvisioningIdentity identity,
  ) async {
    try {
      final responseBytes = await bleProvisioningService.sendCustomData(
        identity,
        endpoint: 'nvr-status',
        payload: Uint8List.fromList(utf8.encode('{}')),
      );
      final response = utf8.decode(responseBytes, allowMalformed: true);
      final status = jsonDecode(response) as Map<String, dynamic>;
      final deviceId = (status['device_id'] ?? status['deviceId'])
          ?.toString()
          .trim();
      return deviceId == null || deviceId.isEmpty ? null : deviceId;
    } catch (_) {
      return null;
    }
  }

  Future<List<NvrChannelPreview>> _waitForNvrChannels(
    String baseUrl, {
    bool forceRefresh = false,
  }) async {
    List<NvrChannelPreview> latestChannels = const <NvrChannelPreview>[];
    for (var attempt = 0; attempt < 30; attempt++) {
      final result = await _loadNvrChannelDiscoveryResult(
        baseUrl,
        refresh: forceRefresh && attempt == 0,
      );
      latestChannels = result.channels;
      if (result.scanComplete) {
        return result.channels;
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return latestChannels;
  }

  Future<_NvrChannelDiscoveryResult> _loadNvrChannelDiscoveryResult(
    String baseUrl, {
    bool refresh = false,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final uri = Uri.parse(
        refresh ? '$baseUrl/channels?refresh=1' : '$baseUrl/channels',
      );
      final request =
          await client.getUrl(uri).timeout(const Duration(seconds: 8));
      final response =
          await request.close().timeout(const Duration(seconds: 20));
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SocketException(
          'ESP32 preview server returned HTTP ${response.statusCode}: $body',
        );
      }

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final channelsJson = decoded['channels'] as List<dynamic>? ?? const [];
      final channels = channelsJson
          .whereType<Map<String, dynamic>>()
          .map(NvrChannelPreview.fromJson)
          .where((channel) => channel.channel > 0)
          .toList(growable: false);
      return _NvrChannelDiscoveryResult(
        channels: channels,
        scanComplete: decoded['scan_complete'] == true,
      );
    } finally {
      client.close(force: true);
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
          clearPendingWifiPassphrase: true,
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

  Future<void> _persistBindingAfterWifiProvisioning(
    Emitter<HubProvisioningState> emit, {
    required BleCandidate candidate,
    required String wifiSsid,
    required String iotDeviceId,
  }) async {
    final bindingToSave = _buildBindingToSave(
      candidate: candidate,
      wifiSsid: wifiSsid,
    );
    emit(
      state.copyWith(
        phase: HubProvisioningPhase.syncing,
        pendingWifiSsid: wifiSsid,
      ),
    );
    final bindingResult = await upsertSpaceHubBinding(bindingToSave);
    await bindingResult.fold<Future<void>>(
      (failure) async => emit(
        state.copyWith(
          phase: HubProvisioningPhase.failure,
          flowMode: HubProvisioningFlowMode.fullProvisioning,
          message: failure.message,
        ),
      ),
      (binding) async {
        final spaceUpdateResult = await updateSpace(
          state.spaceId,
          SpaceMutationRequest(ioTDeviceId: iotDeviceId),
        );

        spaceUpdateResult.fold(
          (failure) => emit(
            state.copyWith(
              phase: HubProvisioningPhase.failure,
              flowMode: HubProvisioningFlowMode.fullProvisioning,
              binding: binding,
              didMutateBinding: true,
              message:
                  'ESP32 setup completed, but updating this space with IoT device ID $iotDeviceId failed: ${failure.message}',
            ),
          ),
          (_) => emit(
            state.copyWith(
              phase: HubProvisioningPhase.success,
              flowMode: HubProvisioningFlowMode.fullProvisioning,
              binding: binding,
              didMutateBinding: true,
              clearSelectedBleCandidate: true,
              clearResolvedIdentity: true,
              clearPendingWifiSsid: true,
              clearDraftLocation: true,
              bleCandidates: const <BleCandidate>[],
              wifiCandidates: const <WifiCandidate>[],
              message:
                  '${_buildSuccessMessage(binding)} IoT device ID $iotDeviceId saved to the space.',
            ),
          ),
        );
      },
    );
  }

  SpaceHubBinding _buildBindingToSave({
    required BleCandidate candidate,
    required String wifiSsid,
  }) {
    final existingBinding = state.binding;
    if (existingBinding != null) {
      return existingBinding.copyWith(
        bleDeviceName: candidate.bleDeviceName,
        wifiSsid: wifiSsid.trim(),
        provisionedAtUtc: DateTime.now().toUtc(),
        status: SpaceHubBindingStatus.bound,
        clearLastError: true,
        clearDeviceLocation: true,
        deviceLocationStatus: HubDeviceLocationStatus.unknown,
        clearDeviceLocationLastError: true,
        clearDeviceLocationUpdatedAtUtc: true,
      );
    }

    if (wifiSsid.trim().isEmpty) {
      throw StateError('Missing selected BLE device or Wi-Fi SSID');
    }

    return SpaceHubBinding(
      spaceId: state.spaceId,
      bleDeviceName: candidate.bleDeviceName,
      wifiSsid: wifiSsid.trim(),
      provisioningMethod: HubProvisioningMethod.blePrefixScan,
      provisionedAtUtc: DateTime.now().toUtc(),
      status: SpaceHubBindingStatus.bound,
      deviceLocationStatus: HubDeviceLocationStatus.unknown,
    );
  }

  String? _buildExistingBindingMessage(SpaceHubBinding binding) {
    if (binding.isSyncPending) {
      return 'Provisioned locally. Backend sync is still pending.';
    }
    return null;
  }

  String _buildSuccessMessage(SpaceHubBinding binding) {
    if (binding.isSyncPending) {
      return 'ESP32 configured with Wi-Fi. Backend sync is still pending.';
    }
    return 'ESP32 configured with Wi-Fi for this space.';
  }
}
