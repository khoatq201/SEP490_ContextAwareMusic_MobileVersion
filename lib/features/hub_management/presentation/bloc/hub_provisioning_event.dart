import 'package:equatable/equatable.dart';

import '../../domain/entities/ble_candidate.dart';

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
  const HubProvisioningBleScanRequested();
}

class HubProvisioningBleCandidateSelected extends HubProvisioningEvent {
  const HubProvisioningBleCandidateSelected(this.candidate);

  final BleCandidate candidate;

  @override
  List<Object?> get props => [candidate];
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

class HubProvisioningRetrySyncRequested extends HubProvisioningEvent {
  const HubProvisioningRetrySyncRequested();
}

class HubProvisioningDeleteBindingRequested extends HubProvisioningEvent {
  const HubProvisioningDeleteBindingRequested();
}

class HubProvisioningRestartRequested extends HubProvisioningEvent {
  const HubProvisioningRestartRequested();
}
