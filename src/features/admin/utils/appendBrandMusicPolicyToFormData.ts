import type { BrandRequest } from '@/features/admin/types';

function appendScalar(fd: FormData, key: string, value: unknown) {
  if (value === undefined || value === null || value === '') return;
  if (typeof value === 'number' && Number.isNaN(value)) return;
  fd.append(key, String(value));
}

/**
 * Appends CAMS fuzzy / music policy fields to brand multipart FormData (create or update).
 * Keys use PascalCase to match `BrandRequest` / `[FromForm]` binding on the API.
 */
export function appendBrandMusicPolicyToFormData(
  formData: FormData,
  values: Partial<BrandRequest>,
  includePolicyFields = true,
) {
  appendScalar(formData, 'FuzzyProfileTemplate', values.fuzzyProfileTemplate);
  if (!includePolicyFields) return;

  appendScalar(formData, 'ChillBpmMin', values.chillBpmMin);
  appendScalar(formData, 'ChillBpmMax', values.chillBpmMax);
  appendScalar(formData, 'FocusBpmMin', values.focusBpmMin);
  appendScalar(formData, 'FocusBpmMax', values.focusBpmMax);
  appendScalar(formData, 'EnergeticBpmMin', values.energeticBpmMin);
  appendScalar(formData, 'EnergeticBpmMax', values.energeticBpmMax);

  appendScalar(formData, 'PressureLowMax', values.pressureLowMax);
  appendScalar(formData, 'PressureCriticalMin', values.pressureCriticalMin);
  appendScalar(formData, 'StressComfortableMax', values.stressComfortableMax);
  appendScalar(formData, 'StressHighMin', values.stressHighMin);
  appendScalar(formData, 'DensitySparseMax', values.densitySparseMax);
  appendScalar(formData, 'DensityCrowdedMin', values.densityCrowdedMin);
  appendScalar(formData, 'SpaceCapacity', values.spaceCapacity);
  appendScalar(
    formData,
    'DefaultDensityRatioWhenNull',
    values.defaultDensityRatioWhenNull,
  );

  const ids = values.allowedPlaylistIds;
  if (Array.isArray(ids)) {
    for (const id of ids) {
      if (id) formData.append('AllowedPlaylistIds', id);
    }
  }
}
