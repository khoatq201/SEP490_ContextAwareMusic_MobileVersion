import '../../domain/entities/ble_candidate.dart';
import '../../domain/entities/esp_provisioning_identity.dart';

abstract class ProvisioningIdentityResolver {
  String get blePrefix;

  Future<EspProvisioningIdentity> resolve(
    BleCandidate candidate, {
    required String proofOfPossession,
  });
}

class PrefixProvisioningIdentityResolver
    implements ProvisioningIdentityResolver {
  const PrefixProvisioningIdentityResolver({
    required this.blePrefix,
  });

  @override
  final String blePrefix;

  @override
  Future<EspProvisioningIdentity> resolve(
    BleCandidate candidate, {
    required String proofOfPossession,
  }) async {
    return EspProvisioningIdentity(
      blePrefix: blePrefix,
      bleDeviceName: candidate.bleDeviceName,
      proofOfPossession: proofOfPossession.trim(),
      source: EspProvisioningIdentitySource.blePrefixScan,
    );
  }
}
