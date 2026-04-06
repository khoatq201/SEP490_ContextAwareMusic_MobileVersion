import { EntityStatusEnum } from '@/shared/types';
import type { SelectProps } from 'antd';

export const STAFF_STATUS_OPTIONS: SelectProps['options'] = [
  { label: 'Active', value: EntityStatusEnum.Active },
  { label: 'Inactive', value: EntityStatusEnum.Inactive },
];
