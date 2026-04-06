/** Mirrors backend StoreFuzzyOverrideLevelEnum */
export const STORE_OVERRIDE_LEVEL = {
  brandLock: 1,
  thresholdOnly: 2,
  fullOverride: 3,
} as const;

export const STORE_FUZZY_OVERRIDE_LEVEL_OPTIONS = [
  {
    label: '1 - Brand lock',
    value: STORE_OVERRIDE_LEVEL.brandLock,
    description:
      'Store uses brand default profile for runtime mood thresholds and playlist scope.',
  },
  {
    label: '2 - Threshold only',
    value: STORE_OVERRIDE_LEVEL.thresholdOnly,
    description:
      'Store profile can tune fuzzy thresholds; playlist scope can still follow brand defaults.',
  },
  {
    label: '3 - Full override',
    value: STORE_OVERRIDE_LEVEL.fullOverride,
    description:
      'Store profile can own both thresholds and playlist scope for CAMS runtime.',
  },
] as const;

export function getStoreOverrideLevelDescription(
  level: number | null | undefined,
) {
  switch (level) {
    case STORE_OVERRIDE_LEVEL.brandLock:
      return 'Brand lock — store profile is still supported; brand profile is used as fallback when no active store profile exists.';
    case STORE_OVERRIDE_LEVEL.thresholdOnly:
      return 'Threshold only — store profile is used at runtime; configure BPM / fuzzy thresholds per store.';
    case STORE_OVERRIDE_LEVEL.fullOverride:
      return 'Full override — store profile is used at runtime with optional allowed-playlist scope.';
    default:
      return null;
  }
}

export function getStoreOverrideLevelLabel(level: number | null | undefined) {
  switch (level) {
    case STORE_OVERRIDE_LEVEL.brandLock:
      return 'Brand lock (1)';
    case STORE_OVERRIDE_LEVEL.thresholdOnly:
      return 'Threshold only (2)';
    case STORE_OVERRIDE_LEVEL.fullOverride:
      return 'Full override (3)';
    default:
      return 'Not configured';
  }
}
