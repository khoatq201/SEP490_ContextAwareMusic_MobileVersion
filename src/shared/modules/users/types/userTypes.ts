import type { EntityStatusEnum, RoleEnum } from '@/shared/types';

/**
 * User Detail Response
 * Full user profile information returned from GET /api/users/{id}
 */
export interface UserDetail {
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
  storeId?: string;
  storeName?: string;
  lastLoginAt?: string;
  createdAt?: string;
  emailConfirmed: boolean;
  phoneNumberConfirmed: boolean;
  twoFactorEnabled: boolean;
}
