import type { SpaceFuzzyOverrideProfileRequest } from '@/shared/modules/spaces/types';

export const pickSpaceFuzzyOverrideBody = (
  fuzzy: Partial<SpaceFuzzyOverrideProfileRequest> | undefined,
): SpaceFuzzyOverrideProfileRequest => {
  if (!fuzzy) return {};

  const out: SpaceFuzzyOverrideProfileRequest = {};

  if (fuzzy.name?.trim()) out.name = fuzzy.name.trim();

  const nums: (keyof SpaceFuzzyOverrideProfileRequest)[] = [
    'chillBpmMin',
    'chillBpmMax',
    'focusBpmMin',
    'focusBpmMax',
    'energeticBpmMin',
    'energeticBpmMax',
    'pressureLowMax',
    'pressureCriticalMin',
    'spaceCapacity',
  ];
  for (const key of nums) {
    const value = fuzzy[key];
    if (typeof value === 'number' && !Number.isNaN(value)) {
      (out as Record<string, unknown>)[key] = value;
    }
  }

  const decimals: (keyof SpaceFuzzyOverrideProfileRequest)[] = [
    'stressComfortableMax',
    'stressHighMin',
    'densitySparseMax',
    'densityCrowdedMin',
    'defaultDensityRatioWhenNull',
  ];
  for (const key of decimals) {
    const value = fuzzy[key];
    if (typeof value === 'number' && !Number.isNaN(value)) {
      (out as Record<string, unknown>)[key] = value;
    }
  }

  if (
    Array.isArray(fuzzy.allowedPlaylistIds) &&
    fuzzy.allowedPlaylistIds.length > 0
  ) {
    out.allowedPlaylistIds = fuzzy.allowedPlaylistIds.filter(Boolean);
  }

  return out;
};
