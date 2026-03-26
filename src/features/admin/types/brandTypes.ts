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
