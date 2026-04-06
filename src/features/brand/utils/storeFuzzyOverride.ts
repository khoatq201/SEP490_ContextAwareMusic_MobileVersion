import type { StoreFuzzyOverrideProfileRequest } from '@/features/brand/types';

/** Builds JSON body for POST .../fuzzy-profiles; omits empty optional fields. */
export function pickStoreFuzzyOverrideBody(
  fuzzy: Partial<StoreFuzzyOverrideProfileRequest> | undefined | null,
): StoreFuzzyOverrideProfileRequest {
  if (!fuzzy) return {};

  const out: StoreFuzzyOverrideProfileRequest = {};

  if (fuzzy.name?.trim()) out.name = fuzzy.name.trim();

  const nums: (keyof StoreFuzzyOverrideProfileRequest)[] = [
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
  for (const k of nums) {
    const v = fuzzy[k];
    if (typeof v === 'number' && !Number.isNaN(v)) {
      (out as Record<string, unknown>)[k] = v;
    }
  }

  const decimals: (keyof StoreFuzzyOverrideProfileRequest)[] = [
    'stressComfortableMax',
    'stressHighMin',
    'densitySparseMax',
    'densityCrowdedMin',
    'defaultDensityRatioWhenNull',
  ];
  for (const k of decimals) {
    const v = fuzzy[k];
    if (typeof v === 'number' && !Number.isNaN(v)) {
      (out as Record<string, unknown>)[k] = v;
    }
  }

  if (
    Array.isArray(fuzzy.allowedPlaylistIds) &&
    fuzzy.allowedPlaylistIds.length
  ) {
    out.allowedPlaylistIds = fuzzy.allowedPlaylistIds.filter(Boolean);
  }

  return out;
}
