import 'package:equatable/equatable.dart';

import 'config_governance_enums.dart';

class ConfigValueUpsertRequest extends Equatable {
  final String key;
  final ConfigDomain domain;
  final ConfigValueType valueType;
  final String value;
  final BrandOverrideIntent? brandOverrideIntent;
  final StoreOverrideIntent? storeOverrideIntent;
  final SpaceOverrideIntent? spaceOverrideIntent;
  final String? overrideReason;
  final List<String>? targetStoreIds;
  final List<String>? targetSpaceIds;

  const ConfigValueUpsertRequest({
    required this.key,
    required this.domain,
    required this.valueType,
    required this.value,
    this.brandOverrideIntent,
    this.storeOverrideIntent,
    this.spaceOverrideIntent,
    this.overrideReason,
    this.targetStoreIds,
    this.targetSpaceIds,
  });

  Map<String, dynamic> toJson({
    bool includeBrandOverrideIntent = false,
    bool includeStoreOverrideIntent = false,
    bool includeSpaceOverrideIntent = false,
    String? spaceId,
  }) {
    final reason = overrideReason?.trim();
    final storeTargets = targetStoreIds
        ?.map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final spaceTargets = targetSpaceIds
        ?.map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    return {
      if (spaceId != null) 'spaceId': spaceId,
      'key': key,
      'domain': domain.value,
      'valueType': valueType.value,
      'value': value,
      if (includeBrandOverrideIntent)
        'overrideIntent':
            (brandOverrideIntent ?? BrandOverrideIntent.none).value,
      if (includeStoreOverrideIntent)
        'overrideIntent':
            (storeOverrideIntent ?? StoreOverrideIntent.none).value,
      if (includeSpaceOverrideIntent)
        'overrideIntent':
            (spaceOverrideIntent ?? SpaceOverrideIntent.overrideAtSpace).value,
      if (reason != null && reason.isNotEmpty) 'overrideReason': reason,
      if (storeTargets != null && storeTargets.isNotEmpty)
        'targetStoreIds': storeTargets,
      if (spaceTargets != null && spaceTargets.isNotEmpty)
        'targetSpaceIds': spaceTargets,
    };
  }

  @override
  List<Object?> get props => [
        key,
        domain,
        valueType,
        value,
        brandOverrideIntent,
        storeOverrideIntent,
        spaceOverrideIntent,
        overrideReason,
        targetStoreIds,
        targetSpaceIds,
      ];
}

class SetStoreGovernanceModeRequest extends Equatable {
  final List<String> storeIds;
  final StoreGovernanceMode mode;

  const SetStoreGovernanceModeRequest({
    required this.storeIds,
    required this.mode,
  });

  Map<String, dynamic> toJson() {
    final normalizedStoreIds = storeIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    return {
      'storeIds': normalizedStoreIds,
      'mode': mode.value,
    };
  }

  @override
  List<Object?> get props => [storeIds, mode];
}

class PublishConfigVersionRequest extends Equatable {
  final ConfigScopeType scopeType;
  final String scopeId;
  final String? note;

  const PublishConfigVersionRequest({
    required this.scopeType,
    required this.scopeId,
    this.note,
  });

  Map<String, dynamic> toJson() {
    final trimmedNote = note?.trim();
    return {
      'scopeType': scopeType.value,
      'scopeId': scopeId.trim(),
      if (trimmedNote != null && trimmedNote.isNotEmpty) 'note': trimmedNote,
    };
  }

  @override
  List<Object?> get props => [scopeType, scopeId, note];
}

class RollbackConfigVersionRequest extends Equatable {
  final String versionId;
  final String? note;

  const RollbackConfigVersionRequest({
    required this.versionId,
    this.note,
  });

  Map<String, dynamic> toJson() {
    final trimmedNote = note?.trim();
    return {
      'versionId': versionId.trim(),
      if (trimmedNote != null && trimmedNote.isNotEmpty) 'note': trimmedNote,
    };
  }

  @override
  List<Object?> get props => [versionId, note];
}
