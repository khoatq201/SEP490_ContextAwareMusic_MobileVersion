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
    'noiseQuietMaxDb',
    'noiseLoudMinDb',
    'defaultDecibelWhenNull',
  ];
  for (const k of decimals) {
    const v = fuzzy[k];
    if (typeof v === 'number' && !Number.isNaN(v)) {
      (out as Record<string, unknown>)[k] = v;
    }
  }

  // Backward compatibility for older form payloads still using legacy field names.
  if (
    out.noiseQuietMaxDb === undefined &&
    typeof fuzzy.stressComfortableMax === 'number' &&
    !Number.isNaN(fuzzy.stressComfortableMax)
  ) {
    out.noiseQuietMaxDb = fuzzy.stressComfortableMax;
  }
  if (
    out.noiseQuietMaxDb === undefined &&
    typeof fuzzy.densitySparseMax === 'number' &&
    !Number.isNaN(fuzzy.densitySparseMax)
  ) {
    out.noiseQuietMaxDb = fuzzy.densitySparseMax;
  }

  if (
    out.noiseLoudMinDb === undefined &&
    typeof fuzzy.stressHighMin === 'number' &&
    !Number.isNaN(fuzzy.stressHighMin)
  ) {
    out.noiseLoudMinDb = fuzzy.stressHighMin;
  }
  if (
    out.noiseLoudMinDb === undefined &&
    typeof fuzzy.densityCrowdedMin === 'number' &&
    !Number.isNaN(fuzzy.densityCrowdedMin)
  ) {
    out.noiseLoudMinDb = fuzzy.densityCrowdedMin;
  }

  if (
    out.defaultDecibelWhenNull === undefined &&
    typeof fuzzy.defaultDensityRatioWhenNull === 'number' &&
    !Number.isNaN(fuzzy.defaultDensityRatioWhenNull)
  ) {
    out.defaultDecibelWhenNull = fuzzy.defaultDensityRatioWhenNull;
  }

  if (
    Array.isArray(fuzzy.allowedPlaylistIds) &&
    fuzzy.allowedPlaylistIds.length
  ) {
    out.allowedPlaylistIds = fuzzy.allowedPlaylistIds.filter(Boolean);
  }

  if (
    Array.isArray(fuzzy.chillMoodCandidates) &&
    fuzzy.chillMoodCandidates.length
  ) {
    out.chillMoodCandidates = fuzzy.chillMoodCandidates;
  }

  if (
    Array.isArray(fuzzy.focusMoodCandidates) &&
    fuzzy.focusMoodCandidates.length
  ) {
    out.focusMoodCandidates = fuzzy.focusMoodCandidates;
  }

  if (
    Array.isArray(fuzzy.energeticMoodCandidates) &&
    fuzzy.energeticMoodCandidates.length
  ) {
    out.energeticMoodCandidates = fuzzy.energeticMoodCandidates;
  }

  return out;
}
