import type { BaseResponse, EntityStatusEnum } from '@/shared/types';

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
};

// Response DTOs
export type StoreListItem = BaseResponse & {
  brandId: string;
  name: string;
  contactNumber: string | null;
  address: string | null;
  city: string | null;
  district: string | null;
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
  stressComfortableMax?: number;
  stressHighMin?: number;
  densitySparseMax?: number;
  densityCrowdedMin?: number;
  spaceCapacity?: number;
  defaultDensityRatioWhenNull?: number;
  allowedPlaylistIds?: string[];
};
