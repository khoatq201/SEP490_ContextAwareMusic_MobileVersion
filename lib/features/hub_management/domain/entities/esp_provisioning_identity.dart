import 'package:equatable/equatable.dart';

enum EspProvisioningIdentitySource {
  blePrefixScan,
  qrCode,
  backendInventory,
}

extension EspProvisioningIdentitySourceX on EspProvisioningIdentitySource {
  String get apiValue {
    switch (this) {
      case EspProvisioningIdentitySource.blePrefixScan:
        return 'blePrefixScan';
      case EspProvisioningIdentitySource.qrCode:
        return 'qrCode';
      case EspProvisioningIdentitySource.backendInventory:
        return 'backendInventory';
    }
  }
}

class EspProvisioningIdentity extends Equatable {
  const EspProvisioningIdentity({
    required this.blePrefix,
    required this.bleDeviceName,
    required this.proofOfPossession,
    required this.source,
  });

  final String blePrefix;
  final String bleDeviceName;
  final String proofOfPossession;
  final EspProvisioningIdentitySource source;

  @override
  List<Object?> get props => [
        blePrefix,
        bleDeviceName,
        proofOfPossession,
        source,
      ];
}
