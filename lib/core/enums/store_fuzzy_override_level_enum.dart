enum StoreFuzzyOverrideLevelEnum {
  brandLock,
  thresholdOnly,
  fullOverride,
  enabled,
  disabled,
  custom,
  unknown;

  static StoreFuzzyOverrideLevelEnum fromJson(dynamic raw) {
    if (raw == null) return StoreFuzzyOverrideLevelEnum.unknown;
    if (raw is int) {
      switch (raw) {
        case 1:
          return StoreFuzzyOverrideLevelEnum.brandLock;
        case 2:
          return StoreFuzzyOverrideLevelEnum.thresholdOnly;
        case 3:
          return StoreFuzzyOverrideLevelEnum.fullOverride;
        default:
          return StoreFuzzyOverrideLevelEnum.unknown;
      }
    }

    final text = raw.toString().trim();
    if (text.isEmpty) return StoreFuzzyOverrideLevelEnum.unknown;
    final parsedInt = int.tryParse(text);
    if (parsedInt != null) {
      return fromJson(parsedInt);
    }

    final normalized = text
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '')
        .toLowerCase();
    switch (normalized) {
      case 'brandlock':
        return StoreFuzzyOverrideLevelEnum.brandLock;
      case 'thresholdonly':
        return StoreFuzzyOverrideLevelEnum.thresholdOnly;
      case 'fulloverride':
        return StoreFuzzyOverrideLevelEnum.fullOverride;
      case 'enabled':
        return StoreFuzzyOverrideLevelEnum.enabled;
      case 'disabled':
        return StoreFuzzyOverrideLevelEnum.disabled;
      case 'custom':
        return StoreFuzzyOverrideLevelEnum.custom;
      default:
        return StoreFuzzyOverrideLevelEnum.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case StoreFuzzyOverrideLevelEnum.brandLock:
        return 'Brand Lock';
      case StoreFuzzyOverrideLevelEnum.thresholdOnly:
        return 'Threshold Only';
      case StoreFuzzyOverrideLevelEnum.fullOverride:
        return 'Full Override';
      case StoreFuzzyOverrideLevelEnum.enabled:
        return 'Enabled';
      case StoreFuzzyOverrideLevelEnum.disabled:
        return 'Disabled';
      case StoreFuzzyOverrideLevelEnum.custom:
        return 'Custom';
      case StoreFuzzyOverrideLevelEnum.unknown:
        return 'Unknown';
    }
  }

  bool get allowsThresholdOverride {
    switch (this) {
      case StoreFuzzyOverrideLevelEnum.thresholdOnly:
      case StoreFuzzyOverrideLevelEnum.fullOverride:
      case StoreFuzzyOverrideLevelEnum.enabled:
      case StoreFuzzyOverrideLevelEnum.custom:
        return true;
      case StoreFuzzyOverrideLevelEnum.brandLock:
      case StoreFuzzyOverrideLevelEnum.disabled:
      case StoreFuzzyOverrideLevelEnum.unknown:
        return false;
    }
  }

  bool get allowsPlaylistOverride {
    switch (this) {
      case StoreFuzzyOverrideLevelEnum.fullOverride:
      case StoreFuzzyOverrideLevelEnum.custom:
        return true;
      case StoreFuzzyOverrideLevelEnum.brandLock:
      case StoreFuzzyOverrideLevelEnum.thresholdOnly:
      case StoreFuzzyOverrideLevelEnum.enabled:
      case StoreFuzzyOverrideLevelEnum.disabled:
      case StoreFuzzyOverrideLevelEnum.unknown:
        return false;
    }
  }

  bool get isLocked {
    switch (this) {
      case StoreFuzzyOverrideLevelEnum.brandLock:
      case StoreFuzzyOverrideLevelEnum.disabled:
        return true;
      case StoreFuzzyOverrideLevelEnum.thresholdOnly:
      case StoreFuzzyOverrideLevelEnum.fullOverride:
      case StoreFuzzyOverrideLevelEnum.enabled:
      case StoreFuzzyOverrideLevelEnum.custom:
      case StoreFuzzyOverrideLevelEnum.unknown:
        return false;
    }
  }
}
