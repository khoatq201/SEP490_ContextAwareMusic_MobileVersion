import type { SelectProps } from 'antd';
import { EntityStatusEnum } from '@/shared/types';

/**
 * Entity Status Options (used across all features)
 */
export const ENTITY_STATUS_OPTIONS: SelectProps['options'] = [
  { label: 'Active', value: EntityStatusEnum.Active },
  { label: 'Inactive', value: EntityStatusEnum.Inactive },
  { label: 'Pending', value: EntityStatusEnum.Pending },
  { label: 'Rejected', value: EntityStatusEnum.Rejected },
];

/**
 * Entity Status Labels
 */
export const ENTITY_STATUS_LABELS: Record<EntityStatusEnum, string> = {
  [EntityStatusEnum.Inactive]: 'Inactive',
  [EntityStatusEnum.Active]: 'Active',
  [EntityStatusEnum.Pending]: 'Pending',
  [EntityStatusEnum.Rejected]: 'Rejected',
};

/**
 * Entity Status Colors (for Tag component)
 */
export const ENTITY_STATUS_COLORS: Record<EntityStatusEnum, string> = {
  [EntityStatusEnum.Inactive]: 'default',
  [EntityStatusEnum.Active]: 'success',
  [EntityStatusEnum.Pending]: 'warning',
  [EntityStatusEnum.Rejected]: 'error',
};

/**
 * Common Pagination Sizes
 */
//TODO: Đưa ra common constants
export const PAGINATION_SIZES = [10, 20, 50, 100];

/**
 * Default Page Size
 */
//TODO: Đưa ra common constants
export const DEFAULT_PAGE_SIZE = 10;
