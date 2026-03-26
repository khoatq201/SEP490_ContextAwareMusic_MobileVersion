/**
 * Types
 */
import type { DefaultOptionType, SelectProps } from 'antd/es/select';
import { EntityStatusEnum } from '@/shared/types';

export const BRAND_STATUS_OPTIONS: SelectProps['options'] = [
  { label: 'Active', value: EntityStatusEnum.Active },
  { label: 'Inactive', value: EntityStatusEnum.Inactive },
  { label: 'Pending', value: EntityStatusEnum.Pending },
  { label: 'Rejected', value: EntityStatusEnum.Rejected },
];

export const INDUSTRY_OPTIONS: DefaultOptionType[] = [
  { label: 'F&B', value: 'F&B' },
  { label: 'Retail', value: 'Retail' },
  { label: 'Hospitality', value: 'Hospitality' },
  { label: 'Healthcare', value: 'Healthcare' },
  { label: 'Education', value: 'Education' },
  { label: 'Entertainment', value: 'Entertainment' },
  { label: 'Technology', value: 'Technology' },
  { label: 'Other', value: 'Other' },
] as const;

export const BRAND_STATUS_COLORS = {
  [EntityStatusEnum.Active]: 'success',
  [EntityStatusEnum.Inactive]: 'default',
  [EntityStatusEnum.Pending]: 'processing',
  [EntityStatusEnum.Rejected]: 'error',
} as const;

export const BRAND_STATUS_LABELS = {
  [EntityStatusEnum.Active]: 'Active',
  [EntityStatusEnum.Inactive]: 'Inactive',
  [EntityStatusEnum.Pending]: 'Pending',
  [EntityStatusEnum.Rejected]: 'Rejected',
} as const;
