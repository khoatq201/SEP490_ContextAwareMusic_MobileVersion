import type { EntityStatusEnum, RoleEnum } from '@/shared/types/commonTypes';

export type CreateAccountRequest = {
  firstName: string;
  lastName: string;
  email: string;
  password: string;
  phoneNumber?: string;
  role: RoleEnum;
  brandId?: string;
  storeId?: string;
  avatar?: File;
};

export type UpdateAccountRequest = {
  firstName?: string;
  lastName?: string;
  email?: string;
  phoneNumber?: string;
  avatar?: File;
};

export type ResetPasswordRequest = {
  newPassword: string;
};

export type AssignBrandRequest = {
  newBrandId: string;
};

export type AssignStoreRequest = {
  newStoreId: string | null;
};

/**
 * Filter Parameters
 */
export type AccountFilter = {
  page?: number;
  pageSize?: number;
  search?: string;
  sortBy?: string;
  role?: RoleEnum;
  isAscending?: boolean;
  status?: EntityStatusEnum;
  brandId?: string;
  hasAssignedBrand?: boolean;
};

/**
 * List Item with optional children for grouping
 */
export type AccountListItem = {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  fullName: string;
  phoneNumber?: string;
  avatarUrl?: string;
  status: EntityStatusEnum;
  roles: RoleEnum[];
  isPrimaryOwner: boolean;
  brandId?: string;
  brandName?: string;
  brandLogoUrl?: string;
  lastLoginAt?: string;
  children?: AccountListItem[];
};

export type AccountDetailResponse = AccountListItem & {
  emailConfirmed: boolean;
  phoneNumberConfirmed: boolean;
  twoFactorEnabled: boolean;
};

export type AccountListFilter = Omit<AccountFilter, 'role'>;
