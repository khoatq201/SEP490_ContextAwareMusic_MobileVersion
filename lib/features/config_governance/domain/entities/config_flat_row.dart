import 'package:equatable/equatable.dart';

import 'config_governance_enums.dart';

class ConfigFlatRow extends Equatable {
  final String key;
  final ConfigDomain domain;
  final ConfigScopeType scopeType;
  final String? scopeId;
  final ConfigValueType valueType;
  final String? value;
  final ConfigTier policyTier;
  final ConfigValueType? policyDefaultValueType;
  final String? policyDefaultValue;
  final bool? allowStoreOverride;
  final bool? allowSpaceOverride;
  final String? brandLockReason;

  const ConfigFlatRow({
    required this.key,
    required this.domain,
    required this.scopeType,
    this.scopeId,
    required this.valueType,
    this.value,
    required this.policyTier,
    this.policyDefaultValueType,
    this.policyDefaultValue,
    this.allowStoreOverride,
    this.allowSpaceOverride,
    this.brandLockReason,
  });

  bool get hasBrandOverrideGate =>
      allowStoreOverride != null || allowSpaceOverride != null;

  bool get isStoreOverrideAllowed => allowStoreOverride == true;

  bool get isSpaceOverrideAllowed =>
      allowStoreOverride == true && allowSpaceOverride == true;

  ConfigFlatRow copyWith({
    String? key,
    ConfigDomain? domain,
    ConfigScopeType? scopeType,
    String? scopeId,
    ConfigValueType? valueType,
    String? value,
    ConfigTier? policyTier,
    ConfigValueType? policyDefaultValueType,
    String? policyDefaultValue,
    bool? allowStoreOverride,
    bool? allowSpaceOverride,
    String? brandLockReason,
  }) {
    return ConfigFlatRow(
      key: key ?? this.key,
      domain: domain ?? this.domain,
      scopeType: scopeType ?? this.scopeType,
      scopeId: scopeId ?? this.scopeId,
      valueType: valueType ?? this.valueType,
      value: value ?? this.value,
      policyTier: policyTier ?? this.policyTier,
      policyDefaultValueType:
          policyDefaultValueType ?? this.policyDefaultValueType,
      policyDefaultValue: policyDefaultValue ?? this.policyDefaultValue,
      allowStoreOverride: allowStoreOverride ?? this.allowStoreOverride,
      allowSpaceOverride: allowSpaceOverride ?? this.allowSpaceOverride,
      brandLockReason: brandLockReason ?? this.brandLockReason,
    );
  }

  @override
  List<Object?> get props => [
        key,
        domain,
        scopeType,
        scopeId,
        valueType,
        value,
        policyTier,
        policyDefaultValueType,
        policyDefaultValue,
        allowStoreOverride,
        allowSpaceOverride,
        brandLockReason,
      ];
}
