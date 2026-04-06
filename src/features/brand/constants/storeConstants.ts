import { EntityStatusEnum } from '@/shared/types';
import type { SelectProps } from 'antd';

export const STORE_STATUS_OPTIONS: SelectProps['options'] = [
  { label: 'Active', value: EntityStatusEnum.Active },
  { label: 'Inactive', value: EntityStatusEnum.Inactive },
  { label: 'Pending', value: EntityStatusEnum.Pending },
  { label: 'Rejected', value: EntityStatusEnum.Rejected },
];