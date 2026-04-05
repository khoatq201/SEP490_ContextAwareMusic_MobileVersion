import '../../domain/entities/ble_candidate.dart';
import '../../domain/entities/esp_provisioning_identity.dart';

abstract class ProvisioningIdentityResolver {
  String get blePrefix;

  Future<EspProvisioningIdentity> resolve(BleCandidate candidate);
}

class PrefixProvisioningIdentityResolver
    implements ProvisioningIdentityResolver {
  const PrefixProvisioningIdentityResolver({
    required this.blePrefix,
    required this.sharedProofOfPossession,
  });

  @override
  final String blePrefix;
  final String sharedProofOfPossession;

  @override
  Future<EspProvisioningIdentity> resolve(BleCandidate candidate) async {
    return EspProvisioningIdentity(
      blePrefix: blePrefix,
      bleDeviceName: candidate.bleDeviceName,
      proofOfPossession: sharedProofOfPossession,
      source: EspProvisioningIdentitySource.blePrefixScan,
    );
  }
}
