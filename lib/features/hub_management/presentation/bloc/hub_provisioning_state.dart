import 'package:equatable/equatable.dart';

import '../../domain/entities/ble_candidate.dart';
import '../../domain/entities/esp_provisioning_identity.dart';
import '../../domain/entities/space_hub_binding.dart';
import '../../domain/entities/wifi_candidate.dart';

enum HubProvisioningPhase {
  loading,
  permissionRequired,
  scanningBle,
  selectDevice,
  scanningWifi,
  enterWifi,
  provisioning,
  syncing,
  success,
  failure,
}

class HubProvisioningState extends Equatable {
  const HubProvisioningState({
    this.phase = HubProvisioningPhase.loading,
    this.spaceId = '',
    this.storeId = '',
    this.spaceName = '',
    this.binding,
    this.bleCandidates = const <BleCandidate>[],
    this.selectedBleCandidate,
    this.resolvedIdentity,
    this.wifiCandidates = const <WifiCandidate>[],
    this.message,
    this.isPermissionPermanentlyDenied = false,
    this.didMutateBinding = false,
  });

  final HubProvisioningPhase phase;
  final String spaceId;
  final String storeId;
  final String spaceName;
  final SpaceHubBinding? binding;
  final List<BleCandidate> bleCandidates;
  final BleCandidate? selectedBleCandidate;
  final EspProvisioningIdentity? resolvedIdentity;
  final List<WifiCandidate> wifiCandidates;
  final String? message;
  final bool isPermissionPermanentlyDenied;
  final bool didMutateBinding;

  HubProvisioningState copyWith({
    HubProvisioningPhase? phase,
    String? spaceId,
    String? storeId,
    String? spaceName,
    SpaceHubBinding? binding,
    bool clearBinding = false,
    List<BleCandidate>? bleCandidates,
    BleCandidate? selectedBleCandidate,
    bool clearSelectedBleCandidate = false,
    EspProvisioningIdentity? resolvedIdentity,
    bool clearResolvedIdentity = false,
    List<WifiCandidate>? wifiCandidates,
    String? message,
    bool clearMessage = false,
    bool? isPermissionPermanentlyDenied,
    bool? didMutateBinding,
  }) {
    return HubProvisioningState(
      phase: phase ?? this.phase,
      spaceId: spaceId ?? this.spaceId,
      storeId: storeId ?? this.storeId,
      spaceName: spaceName ?? this.spaceName,
      binding: clearBinding ? null : (binding ?? this.binding),
      bleCandidates: bleCandidates ?? this.bleCandidates,
      selectedBleCandidate: clearSelectedBleCandidate
          ? null
          : (selectedBleCandidate ?? this.selectedBleCandidate),
      resolvedIdentity: clearResolvedIdentity
          ? null
          : (resolvedIdentity ?? this.resolvedIdentity),
      wifiCandidates: wifiCandidates ?? this.wifiCandidates,
      message: clearMessage ? null : (message ?? this.message),
      isPermissionPermanentlyDenied:
          isPermissionPermanentlyDenied ?? this.isPermissionPermanentlyDenied,
      didMutateBinding: didMutateBinding ?? this.didMutateBinding,
    );
  }

  bool get hasBinding => binding != null;

  bool get canConfigureWifi =>
      selectedBleCandidate != null && resolvedIdentity != null;

  @override
  List<Object?> get props => [
        phase,
        spaceId,
        storeId,
        spaceName,
        binding,
        bleCandidates,
        selectedBleCandidate,
        resolvedIdentity,
        wifiCandidates,
        message,
        isPermissionPermanentlyDenied,
        didMutateBinding,
      ];
}
