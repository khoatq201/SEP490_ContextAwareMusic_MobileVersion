import { RoleEnum } from '../types';

export const ROLE_LABELS: Record<RoleEnum, string> = {
  [RoleEnum.SystemAdmin]: 'System Admin',
  [RoleEnum.BrandManager]: 'Brand Manager',
  [RoleEnum.StoreManager]: 'Store Manager',
} as const;

export const ROLE_COLORS: Record<RoleEnum, string> = {
  [RoleEnum.SystemAdmin]: 'red',
  [RoleEnum.BrandManager]: 'purple',
  [RoleEnum.StoreManager]: 'blue',
} as const;
