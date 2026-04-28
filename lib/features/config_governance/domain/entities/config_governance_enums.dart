enum ConfigDomain {
  unknown(0),
  ops(1),
  playback(2),
  fuzzy(3),
  content(4),
  governance(5),
  scheduling(6),
  cams(7),
  sys(8);

  const ConfigDomain(this.value);

  final int value;

  static ConfigDomain fromJson(dynamic raw) {
    final value = _readInt(raw);
    for (final domain in ConfigDomain.values) {
      if (domain.value == value) return domain;
    }
    return ConfigDomain.unknown;
  }
}

enum ConfigScopeType {
  system(0),
  brand(1),
  store(2),
  space(3),
  unknown(-1);

  const ConfigScopeType(this.value);

  final int value;

  static ConfigScopeType fromJson(dynamic raw) {
    final value = _readInt(raw);
    for (final scope in ConfigScopeType.values) {
      if (scope.value == value) return scope;
    }
    return ConfigScopeType.unknown;
  }
}

enum ConfigTier {
  system(0),
  tenant(1),
  unknown(-1);

  const ConfigTier(this.value);

  final int value;

  static ConfigTier fromJson(dynamic raw) {
    final value = _readInt(raw);
    for (final tier in ConfigTier.values) {
      if (tier.value == value) return tier;
    }
    return ConfigTier.unknown;
  }
}

enum ConfigValueType {
  unknown(0),
  string(1),
  number(2),
  boolean(3),
  dateTime(4);

  const ConfigValueType(this.value);

  final int value;

  static ConfigValueType fromJson(dynamic raw) {
    final value = _readInt(raw);
    for (final type in ConfigValueType.values) {
      if (type.value == value) return type;
    }
    return ConfigValueType.unknown;
  }
}

enum BrandOverrideIntent {
  none(0),
  allowStoreOverride(1),
  forceInheritToAllChildren(2);

  const BrandOverrideIntent(this.value);

  final int value;
}

enum StoreOverrideIntent {
  none(0),
  allowSpaceOverride(1),
  forceInheritToAllSpaces(2);

  const StoreOverrideIntent(this.value);

  final int value;
}

enum SpaceOverrideIntent {
  overrideAtSpace(0),
  inheritFromStore(1);

  const SpaceOverrideIntent(this.value);

  final int value;
}

enum StoreGovernanceMode {
  strictSync(1),
  aiMode(2),
  freedom(3);

  const StoreGovernanceMode(this.value);

  final int value;

  String get label {
    switch (this) {
      case StoreGovernanceMode.strictSync:
        return 'Strict Sync';
      case StoreGovernanceMode.aiMode:
        return 'AI Mode';
      case StoreGovernanceMode.freedom:
        return 'Freedom';
    }
  }

  String get description {
    switch (this) {
      case StoreGovernanceMode.strictSync:
        return 'Server-scheduled playback with schedule sync.';
      case StoreGovernanceMode.aiMode:
        return 'AI-driven playback within brand policy bounds.';
      case StoreGovernanceMode.freedom:
        return 'Manual store playback with AI fallback when needed.';
    }
  }

  static StoreGovernanceMode? tryParseConfigValue(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    final normalized = trimmed.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
    switch (normalized) {
      case 'strictsync':
        return StoreGovernanceMode.strictSync;
      case 'aimode':
      case 'ai':
        return StoreGovernanceMode.aiMode;
      case 'freedom':
        return StoreGovernanceMode.freedom;
    }

    final value = _readInt(trimmed);
    if (value == null) return null;
    for (final mode in StoreGovernanceMode.values) {
      if (mode.value == value) return mode;
    }
    return null;
  }
}

int? _readInt(dynamic raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw);
  return null;
}
