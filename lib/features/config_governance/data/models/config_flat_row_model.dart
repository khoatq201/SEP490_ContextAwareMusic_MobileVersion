import '../../domain/entities/config_flat_row.dart';
import '../../domain/entities/config_governance_enums.dart';

class ConfigFlatRowModel extends ConfigFlatRow {
  const ConfigFlatRowModel({
    required super.key,
    required super.domain,
    required super.scopeType,
    super.scopeId,
    required super.valueType,
    super.value,
    required super.policyTier,
    super.policyDefaultValueType,
    super.policyDefaultValue,
    super.allowStoreOverride,
    super.allowSpaceOverride,
    super.brandLockReason,
  });

  factory ConfigFlatRowModel.fromJson(Map<String, dynamic> json) {
    return ConfigFlatRowModel(
      key: _readString(json, 'key') ?? '',
      domain: ConfigDomain.fromJson(_readValue(json, 'domain')),
      scopeType: ConfigScopeType.fromJson(_readValue(json, 'scopeType')),
      scopeId: _readString(json, 'scopeId'),
      valueType: ConfigValueType.fromJson(_readValue(json, 'valueType')),
      value: _readString(json, 'value'),
      policyTier: ConfigTier.fromJson(_readValue(json, 'policyTier')),
      policyDefaultValueType: _readValue(json, 'policyDefaultValueType') == null
          ? null
          : ConfigValueType.fromJson(
              _readValue(json, 'policyDefaultValueType'),
            ),
      policyDefaultValue: _readString(json, 'policyDefaultValue'),
      allowStoreOverride: _readBool(json, 'allowStoreOverride'),
      allowSpaceOverride: _readBool(json, 'allowSpaceOverride'),
      brandLockReason: _readString(json, 'brandLockReason'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'domain': domain.value,
      'scopeType': scopeType.value,
      'scopeId': scopeId,
      'valueType': valueType.value,
      'value': value,
      'policyTier': policyTier.value,
      'policyDefaultValueType': policyDefaultValueType?.value,
      'policyDefaultValue': policyDefaultValue,
      'allowStoreOverride': allowStoreOverride,
      'allowSpaceOverride': allowSpaceOverride,
      'brandLockReason': brandLockReason,
    };
  }

  static dynamic _readValue(Map<String, dynamic> json, String key) {
    if (json.containsKey(key)) return json[key];
    if (key.isEmpty) return null;
    final pascalCaseKey = '${key[0].toUpperCase()}${key.substring(1)}';
    return json[pascalCaseKey];
  }

  static String? _readString(Map<String, dynamic> json, String key) {
    final value = _readValue(json, key);
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static bool? _readBool(Map<String, dynamic> json, String key) {
    final value = _readValue(json, key);
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return null;
  }
}
