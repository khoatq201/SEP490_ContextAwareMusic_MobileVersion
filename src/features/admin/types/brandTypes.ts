import type { EntityStatusEnum } from '@/shared/types/commonTypes';

// Request DTO
export type BrandRequest = {
  name?: string;
  logo?: File;
  description?: string;
  website?: string;
  industry?: string;
  contactEmail?: string;
  contactPhone?: string;
  primaryContactName?: string;
  technicalContactEmail?: string;
  legalName?: string;
  taxCode?: string;
  billingAddress?: string;
  defaultTimeZone?: string;
  /** CAMS fuzzy template: Cafe | Apparel | Furniture | LuxuryRestaurant */
  fuzzyProfileTemplate?: string;
  /** 1 = brand lock, 2 = threshold only, 3 = full override */
  storeOverrideLevel?: number;
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

// List Item Response (extends BaseResponse)
export type BrandListItem = {
  id: string;
  name: string;
  logoUrl: string | null;
  industry: string | null;
  primaryContactName: string | null;
  contactEmail: string | null;
  contactPhone: string | null;
  createdAt: string;
  updatedAt: string | null;
  createdBy: string | null;
  updatedBy: string | null;
  status: EntityStatusEnum;
};

// Detail Response (extends BrandListItem)
export type BrandDetailResponse = BrandListItem & {
  description: string | null;
  website: string | null;
  legalName: string | null;
  taxCode: string | null;
  billingAddress: string | null;
  technicalContactEmail: string | null;
  defaultTimeZone: string;
  currentSubscriptionId: string | null;
  /** CAMS: mirrors BrandRequest music policy when present */
  storeOverrideLevel?: number | null;
  fuzzyProfileTemplate?: string | null;
  chillBpmMin?: number | null;
  chillBpmMax?: number | null;
  focusBpmMin?: number | null;
  focusBpmMax?: number | null;
  energeticBpmMin?: number | null;
  energeticBpmMax?: number | null;
  pressureLowMax?: number | null;
  pressureCriticalMin?: number | null;
  stressComfortableMax?: number | null;
  stressHighMin?: number | null;
  densitySparseMax?: number | null;
  densityCrowdedMin?: number | null;
  spaceCapacity?: number | null;
  defaultDensityRatioWhenNull?: number | null;
  allowedPlaylistIds?: string[] | null;
};

// Filter (extends BasePaginationFilter)
export type BrandFilter = {
  page?: number;
  pageSize?: number;
  search?: string;
  sortBy?: 'name' | 'industry' | 'createdat' | 'updatedat';
  isAscending?: boolean;
  status?: EntityStatusEnum;
  createdFrom?: string; // ISO 8601
  createdTo?: string;
};
