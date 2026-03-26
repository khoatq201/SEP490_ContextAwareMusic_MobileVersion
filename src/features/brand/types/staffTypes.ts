import type { BaseResponse, EntityStatusEnum, RoleEnum } from '@/shared/types';

// Request DTOs for StoreManager
export type CreateStaffRequest = {
  firstName: string; // Required, max 100 chars
  lastName: string; // Required, max 100 chars
  email: string; // Required, unique, valid email
  password: string; // Required, min 6 chars
  phoneNumber?: string; // Optional, valid phone format
  storeId: string; // Required - which store this StoreManager manages
  avatar?: File; // Optional, max 5MB
};

export type UpdateStaffRequest = {
  firstName?: string;
  lastName?: string;
  email?: string;
  phoneNumber?: string;
  avatar?: File;
};

export type AssignStaffStoreRequest = {
  newStoreId: string | null; // null = unassign, string = assign new store
};

export type ResetStaffPasswordRequest = {
  newPassword: string; // Min 6 chars
};

// Filter
export type StaffFilter = {
  page?: number;
  pageSize?: number;
  search?: string; // Search by name, email, phone
  sortBy?: string; // 'firstname' | 'lastname' | 'email' | 'createdat'
  role?: RoleEnum;
  isAscending?: boolean;
  status?: EntityStatusEnum;
  storeId?: string; // Filter by assigned store
};

// Response DTOs
export interface StaffListItem extends BaseResponse {
  firstName: string;
  lastName: string;
  fullName: string;
  email: string;
  phoneNumber: string | null;
  avatarUrl: string | null;
  lastLoginAt: string | null;
  roles: RoleEnum[];
  brandId: string | null;
  brandName: string | null;
  brandLogoUrl: string | null;
  storeId: string | null;
  storeName: string | null;
  isPrimaryOwner: boolean;
  children?: StaffListItem[];
}

export type StaffDetailResponse = StaffListItem & {
  // Same as StaffListItem for now
  // Can add more fields later if needed
};

export type StaffListFilter = Omit<StaffFilter, 'role'>;
