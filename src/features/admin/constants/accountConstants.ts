/**
 * Types
 */
import type { DefaultOptionType } from 'antd/es/select';
import { EntityStatusEnum, RoleEnum } from '@/shared/types';

export const ROLE_OPTIONS_FOR_ADMIN: DefaultOptionType[] = [
  { label: 'Brand Manager', value: RoleEnum.BrandManager },
] as const;

export const ACCOUNT_STATUS_COLORS = {
  [EntityStatusEnum.Inactive]: 'default',
  [EntityStatusEnum.Active]: 'success',
  [EntityStatusEnum.Pending]: 'processing',
  [EntityStatusEnum.Rejected]: 'error',
} as const;

export const ACCOUNT_STATUS_LABELS = {
  [EntityStatusEnum.Inactive]: 'Inactive',
  [EntityStatusEnum.Active]: 'Active',
  [EntityStatusEnum.Pending]: 'Pending',
  [EntityStatusEnum.Rejected]: 'Rejected',
} as const;

export const ACCOUNT_STATUS_OPTIONS: DefaultOptionType[] = [
  { label: 'Active', value: EntityStatusEnum.Active },
  { label: 'Inactive', value: EntityStatusEnum.Inactive },
  { label: 'Pending', value: EntityStatusEnum.Pending },
  { label: 'Rejected', value: EntityStatusEnum.Rejected },
] as const;
