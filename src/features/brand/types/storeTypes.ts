import type { BaseResponse, EntityStatusEnum } from '@/shared/types';
import type { GovernanceModeEnum } from './configTypes';
import type { MoodType } from '@/shared/modules/moods/types';

// Enums
export enum MoodTypeEnum {
  // Values depend on AI pipeline configuration
  Calm = 'Calm',
  Energetic = 'Energetic',
  Happy = 'Happy',
  Relaxed = 'Relaxed',
}

// Request DTOs
export type StoreRequest = {
  name?: string; // Required for CREATE, max 200 chars
  address?: string; // Max 500 chars
  city?: string; // Max 100 chars
  district?: string; // Max 100 chars
  contactNumber?: string; // Valid phone: 7-15 digits, supports +, (), -, spaces
  latitude?: number; // Range: -90 to 90
  longitude?: number; // Range: -180 to 180
  mapUrl?: string; // Valid http/https URL
  timeZone?: string; // IANA timezone ID (e.g., "Asia/Ho_Chi_Minh")
  areaSquareMeters?: number; // Must be > 0
  maxCapacity?: number; // Must be > 0
  fuzzyOverrideLevel?: number; // 1=BrandLock, 2=ThresholdOnly, 3=FullOverride
};

// Filter
export type StoreFilter = {
  page?: number;
  pageSize?: number;
  search?: string;
  sortBy?: string;
  isAscending?: boolean;
  status?: EntityStatusEnum;
  city?: string;
  district?: string;
  createdFrom?: string; // ISO 8601
  createdTo?: string; // ISO 8601
  storeManagerName?: string;
  /** Resolve a known set of store IDs (e.g. config override allowedStoreIds). Sent as repeated query params. */
  storeIds?: string[];
};

// Response DTOs
export type StoreListItem = BaseResponse & {
  brandId: string;
  name: string;
  contactNumber: string | null;
  address: string | null;
  city: string | null;
  district: string | null;
  governanceMode: GovernanceModeEnum;
};

export type StoreDetailResponse = StoreListItem & {
  latitude: number | null;
  longitude: number | null;
  mapUrl: string | null;
  timeZone: string | null;
  areaSquareMeters: number | null;
  maxCapacity: number | null;
  firestoreCollectionPath: string | null; // Read-only, managed by AI/IoT
  currentMood: MoodTypeEnum | null; // Read-only, set by AI pipeline
  lastMoodUpdateAt: string | null; // Read-only, UTC timestamp
  fuzzyOverrideLevel: number;
  governanceMode: GovernanceModeEnum;

  activeFuzzyMusicProfileId?: string | null;
  activeFuzzyProfileName?: string | null;

  chillBpmMin?: number | null;
  chillBpmMax?: number | null;
  focusBpmMin?: number | null;
  focusBpmMax?: number | null;
  energeticBpmMin?: number | null;
  energeticBpmMax?: number | null;
  pressureLowMax?: number | null;
  pressureCriticalMin?: number | null;
  noiseQuietMaxDb?: number | null;
  noiseLoudMinDb?: number | null;
  defaultDecibelWhenNull?: number | null;
  stressComfortableMax?: number | null;
  stressHighMin?: number | null;
  densitySparseMax?: number | null;
  densityCrowdedMin?: number | null;
  spaceCapacity?: number | null;
  defaultDensityRatioWhenNull?: number | null;

  chillMoodCandidates?: MoodType[] | null;
  focusMoodCandidates?: MoodType[] | null;
  energeticMoodCandidates?: MoodType[] | null;
  allowedPlaylistIds?: string[] | null;
};

/** POST /api/stores/{id}/fuzzy-profiles */
export type StoreFuzzyOverrideProfileRequest = {
  name?: string;
  chillBpmMin?: number;
  chillBpmMax?: number;
  focusBpmMin?: number;
  focusBpmMax?: number;
  energeticBpmMin?: number;
  energeticBpmMax?: number;
  pressureLowMax?: number;
  pressureCriticalMin?: number;
  noiseQuietMaxDb?: number;
  noiseLoudMinDb?: number;
  defaultDecibelWhenNull?: number;
  stressComfortableMax?: number;
  stressHighMin?: number;
  densitySparseMax?: number;
  densityCrowdedMin?: number;
  spaceCapacity?: number;
  defaultDensityRatioWhenNull?: number;
  chillMoodCandidates?: MoodType[];
  focusMoodCandidates?: MoodType[];
  energeticMoodCandidates?: MoodType[];
  allowedPlaylistIds?: string[];
};

export type StoreContextRawLogsFilter = {
  page?: number;
  pageSize?: number;
  spaceId?: string;
  fromUtc?: string;
  toUtc?: string;
};

export type StoreContextRawLogItem = {
  id: number;
  spaceId?: string | null;
  spaceName: string;
  moodId?: string | null;
  moodName: string;
  measuredAtUtc: string;
  avgTemperature?: number | null;
  avgHumidity?: number | null;
  avgNoise?: number | null;
  crowdDensity?: number | null;
  currentWeather?: string | null;
};

export type StoreContextTimeSeriesFilter = {
  spaceId?: string;
  fromUtc?: string;
  toUtc?: string;
  granularity?: 'hour' | 'day';
};

export type StoreContextTimeSeriesPoint = {
  bucketStartUtc: string;
  samples: number;
  avgTemperature?: number | null;
  avgHumidity?: number | null;
  avgNoise?: number | null;
  avgCrowdDensity?: number | null;
};

export type StoreContextTimeSeriesResponse = {
  storeId: string;
  spaceId?: string | null;
  granularity: 'hour' | 'day';
  fromUtc: string;
  toUtc: string;
  points: StoreContextTimeSeriesPoint[];
};

export type StoreContextAggregateFilter = {
  spaceId?: string;
  fromUtc?: string;
  toUtc?: string;
  compareFromUtc?: string;
  compareToUtc?: string;
};

export type MetricMinMaxAvg = {
  min?: number | null;
  max?: number | null;
  avg?: number | null;
};

export type MetricTrend = {
  current?: number | null;
  previous?: number | null;
  delta?: number | null;
  deltaPercent?: number | null;
  isIncrease?: boolean | null;
};

export type StoreContextAggregateSummary = {
  samples: number;
  temperature: MetricMinMaxAvg;
  humidity: MetricMinMaxAvg;
  noise: MetricMinMaxAvg;
  crowdDensity: MetricMinMaxAvg;
};

export type StoreContextTrendSummary = {
  temperature: MetricTrend;
  humidity: MetricTrend;
  noise: MetricTrend;
  crowdDensity: MetricTrend;
  samples: MetricTrend;
};

export type StoreContextAggregateResponse = {
  storeId: string;
  spaceId?: string | null;
  fromUtc: string;
  toUtc: string;
  compareFromUtc: string;
  compareToUtc: string;
  current: StoreContextAggregateSummary;
  previous: StoreContextAggregateSummary;
  trend: StoreContextTrendSummary;
};
