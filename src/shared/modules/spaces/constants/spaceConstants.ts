import type { SelectProps } from 'antd';

/**
 * Types
 */
import { EntityStatusEnum } from '@/shared/types';
import { SpaceTypeEnum } from '@/shared/modules/spaces/types';

export const SPACE_STATUS_OPTIONS: SelectProps['options'] = [
  { label: 'Active', value: EntityStatusEnum.Active },
  { label: 'Inactive', value: EntityStatusEnum.Inactive },
];

/**
 * Space Type Options for Select Dropdown
 */
export const SPACE_TYPE_OPTIONS: SelectProps['options'] = [
  { label: 'Counter', value: SpaceTypeEnum.Counter },
  { label: 'Hall', value: SpaceTypeEnum.Hall },
  { label: 'Entrance', value: SpaceTypeEnum.Entrance },
  { label: 'Outdoor', value: SpaceTypeEnum.Outdoor },
  { label: 'Kitchen', value: SpaceTypeEnum.Kitchen },
  { label: 'Restroom', value: SpaceTypeEnum.Restroom },
];

/**
 * Space Type Labels (for display)
 */
export const SPACE_TYPE_LABELS: Record<SpaceTypeEnum, string> = {
  [SpaceTypeEnum.Counter]: 'Counter',
  [SpaceTypeEnum.Hall]: 'Hall',
  [SpaceTypeEnum.Entrance]: 'Entrance',
  [SpaceTypeEnum.Outdoor]: 'Outdoor',
  [SpaceTypeEnum.Kitchen]: 'Kitchen',
  [SpaceTypeEnum.Restroom]: 'Restroom',
};

/**
 * Space Type Colors (for Tag/Badge)
 */
export const SPACE_TYPE_COLORS: Record<SpaceTypeEnum, string> = {
  [SpaceTypeEnum.Counter]: 'blue',
  [SpaceTypeEnum.Hall]: 'green',
  [SpaceTypeEnum.Entrance]: 'orange',
  [SpaceTypeEnum.Outdoor]: 'cyan',
  [SpaceTypeEnum.Kitchen]: 'volcano',
  [SpaceTypeEnum.Restroom]: 'purple',
};
