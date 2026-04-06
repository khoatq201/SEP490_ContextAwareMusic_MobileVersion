import { EntityStatusEnum } from '@/shared/types';

export const STAFF_STATUS_COLORS = {
  [EntityStatusEnum.Inactive]: 'default',
  [EntityStatusEnum.Active]: 'success',
  [EntityStatusEnum.Pending]: 'processing',
  [EntityStatusEnum.Rejected]: 'error',
} as const;

export const STAFF_STATUS_LABELS = {
  [EntityStatusEnum.Inactive]: 'Inactive',
  [EntityStatusEnum.Active]: 'Active',
  [EntityStatusEnum.Pending]: 'Pending',
  [EntityStatusEnum.Rejected]: 'Rejected',
} as const;

export const STAFF_ROLE_LABEL = 'Store Manager' as const;
export const STAFF_ROLE_COLOR = 'blue' as const;
