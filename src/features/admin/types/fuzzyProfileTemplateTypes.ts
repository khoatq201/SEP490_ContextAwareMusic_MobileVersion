export type FuzzyProfileTemplateOption = {
  templateKey: string;
  displayName: string;
  sortOrder: number;
  profileDescription?: string | null;
  chillMoodDescription?: string | null;
  focusMoodDescription?: string | null;
  energeticMoodDescription?: string | null;
  chillBpmMin?: number;
  chillBpmMax?: number;
  focusBpmMin?: number;
  focusBpmMax?: number;
  energeticBpmMin?: number;
  energeticBpmMax?: number;
};

export type FuzzyProfileTemplateListItem = FuzzyProfileTemplateOption & {
  id: string;
  isActive: boolean;
};

export type FuzzyProfileTemplateDetail = FuzzyProfileTemplateListItem & {
  chillMoodDescription?: string | null;
  focusMoodDescription?: string | null;
  energeticMoodDescription?: string | null;
  chillBpmMin: number;
  chillBpmMax: number;
  focusBpmMin: number;
  focusBpmMax: number;
  energeticBpmMin: number;
  energeticBpmMax: number;
  pressureLowMax: number;
  pressureCriticalMin: number;
  noiseQuietMaxDb: number;
  noiseLoudMinDb: number;
  spaceCapacity: number;
  defaultDecibelWhenNull: number;
  stressComfortableMax?: number;
  stressHighMin?: number;
  densitySparseMax?: number;
  densityCrowdedMin?: number;
  defaultDensityRatioWhenNull?: number;
};

export type FuzzyProfileTemplateFormValues = {
  templateKey: string;
  displayName: string;
  profileDescription?: string;
  chillMoodDescription?: string;
  focusMoodDescription?: string;
  energeticMoodDescription?: string;
  sortOrder: number;
  isActive: boolean;
  chillBpmMin: number;
  chillBpmMax: number;
  focusBpmMin: number;
  focusBpmMax: number;
  energeticBpmMin: number;
  energeticBpmMax: number;
  pressureLowMax: number;
  pressureCriticalMin: number;
  noiseQuietMaxDb: number;
  noiseLoudMinDb: number;
  spaceCapacity: number;
  defaultDecibelWhenNull: number;
  stressComfortableMax?: number;
  stressHighMin?: number;
  densitySparseMax?: number;
  densityCrowdedMin?: number;
  defaultDensityRatioWhenNull?: number;
};
