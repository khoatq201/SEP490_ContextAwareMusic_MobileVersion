import 'package:equatable/equatable.dart';

import '../../domain/entities/ble_candidate.dart';
import '../../domain/entities/hub_device_location.dart';
import 'hub_provisioning_state.dart';

abstract class HubProvisioningEvent extends Equatable {
  const HubProvisioningEvent();

  @override
  List<Object?> get props => const [];
}

class HubProvisioningStarted extends HubProvisioningEvent {
  const HubProvisioningStarted({
    required this.spaceId,
    required this.storeId,
    required this.spaceName,
  });

  final String spaceId;
  final String storeId;
  final String spaceName;

  @override
  List<Object?> get props => [spaceId, storeId, spaceName];
}

class HubProvisioningPermissionRequested extends HubProvisioningEvent {
  const HubProvisioningPermissionRequested();
}

class HubProvisioningBleScanRequested extends HubProvisioningEvent {
  const HubProvisioningBleScanRequested({
    this.flowMode = HubProvisioningFlowMode.fullProvisioning,
    this.initialLocation,
  });

  final HubProvisioningFlowMode flowMode;
  final HubDeviceLocation? initialLocation;

  @override
  List<Object?> get props => [flowMode, initialLocation];
}

class HubProvisioningBleCandidateSelected extends HubProvisioningEvent {
  const HubProvisioningBleCandidateSelected(this.candidate);

  final BleCandidate candidate;

  @override
  List<Object?> get props => [candidate];
}

class HubProvisioningSecretCodeSubmitted extends HubProvisioningEvent {
  const HubProvisioningSecretCodeSubmitted({
    required this.secretCode,
  });

  final String secretCode;

  @override
  List<Object?> get props => [secretCode];
}

class HubProvisioningUseCurrentLocationRequested extends HubProvisioningEvent {
  const HubProvisioningUseCurrentLocationRequested();
}

class HubProvisioningCredentialsSubmitted extends HubProvisioningEvent {
  const HubProvisioningCredentialsSubmitted({
    required this.ssid,
    required this.passphrase,
  });

  final String ssid;
  final String passphrase;

  @override
  List<Object?> get props => [ssid, passphrase];
}

class HubProvisioningLocationSubmitted extends HubProvisioningEvent {
  const HubProvisioningLocationSubmitted({
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.source,
  });

  final String city;
  final double latitude;
  final double longitude;
  final HubDeviceLocationSource source;

  @override
  List<Object?> get props => [city, latitude, longitude, source];
}

class HubProvisioningRetrySyncRequested extends HubProvisioningEvent {
  const HubProvisioningRetrySyncRequested();
}

class HubProvisioningDeleteBindingRequested extends HubProvisioningEvent {
  const HubProvisioningDeleteBindingRequested();
}

class HubProvisioningRestartRequested extends HubProvisioningEvent {
  const HubProvisioningRestartRequested();
}
