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
    'noiseQuietMaxDb',
    'noiseLoudMinDb',
    'defaultDecibelWhenNull',
  ];
  for (const key of decimals) {
    const value = fuzzy[key];
    if (typeof value === 'number' && !Number.isNaN(value)) {
      (out as Record<string, unknown>)[key] = value;
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
    fuzzy.allowedPlaylistIds.length > 0
  ) {
    out.allowedPlaylistIds = fuzzy.allowedPlaylistIds.filter(Boolean);
  }

  if (
    Array.isArray(fuzzy.chillMoodCandidates) &&
    fuzzy.chillMoodCandidates.length > 0
  ) {
    out.chillMoodCandidates = fuzzy.chillMoodCandidates;
  }

  if (
    Array.isArray(fuzzy.focusMoodCandidates) &&
    fuzzy.focusMoodCandidates.length > 0
  ) {
    out.focusMoodCandidates = fuzzy.focusMoodCandidates;
  }

  if (
    Array.isArray(fuzzy.energeticMoodCandidates) &&
    fuzzy.energeticMoodCandidates.length > 0
  ) {
    out.energeticMoodCandidates = fuzzy.energeticMoodCandidates;
  }

  return out;
};
