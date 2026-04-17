import type { BaseResponse, EntityStatusEnum } from '@/shared/types';
import type { MoodType } from '@/shared/modules/moods/types';

/**
 * Space Type Enum (from API_Spaces.md §4.5)
 */
export enum SpaceTypeEnum {
  Counter = 1,
  Hall = 2,
  Entrance = 3,
  Outdoor = 4,
  Kitchen = 5,
  Restroom = 6,
}

/**
 * Space List Item (from API_Spaces.md §4.3)
 * Inherits from BaseResponse
 */
export interface SpaceListItem extends BaseResponse {
  storeId: string;
  name: string;
  type: SpaceTypeEnum;
  description?: string;
}

/**
 * Space Detail Response (from API_Spaces.md §4.4)
 * Inherits from SpaceListItem
 */
export interface SpaceDetailResponse extends SpaceListItem {
  cameraId?: string;
  roiCoordinates?: string;
  maxOccupancy?: number;
  criticalQueueThreshold?: number;
  wiFiSensorId?: string;
  ioTDeviceId?: string;
  currentPlaylistId?: string; // 🔒 Read-only (set by AI pipeline)

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
}

/**
 * Create Space Request (from API_Spaces.md §4.1)
 * StoreManager: storeId is ignored (auto-filled from user.StoreId)
 */
export interface CreateSpaceRequest {
  name: string; // Required
  type: SpaceTypeEnum; // Required
  description?: string;
  cameraId?: string;
  roiCoordinates?: string;
  maxOccupancy?: number;
  criticalQueueThreshold?: number;
  wiFiSensorId?: string;
  ioTDeviceId?: string;
}

/**
 * Update Space Request (from API_Spaces.md §4.1)
 * Partial update - all fields optional
 */
export interface UpdateSpaceRequest {
  name?: string;
  type?: SpaceTypeEnum;
  description?: string;
  cameraId?: string;
  roiCoordinates?: string;
  maxOccupancy?: number;
  criticalQueueThreshold?: number;
  wiFiSensorId?: string;
  ioTDeviceId?: string;
}

/** POST /api/spaces/{id}/fuzzy-profiles */
export interface SpaceFuzzyOverrideProfileRequest {
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
}

/**
 * Space Filter (from API_Spaces.md §4.2)
 * Extends BasePaginationFilter
 * Note: storeId is auto-overridden to user.StoreId for StoreManager
 */
export type SpaceFilter = {
  page?: number;
  pageSize?: number;
  search?: string;
  sortBy?: string;
  isAscending?: boolean;
  type?: SpaceTypeEnum;
  status?: EntityStatusEnum;
  storeId?: string; // For Brand role to filter spaces by store
  createdFrom?: string; // ISO 8601
  createdTo?: string; // ISO 8601
  /** Resolve a known set of space IDs (e.g. config override allowedSpaceIds). Sent as repeated query params. */
  spaceIds?: string[];
};
