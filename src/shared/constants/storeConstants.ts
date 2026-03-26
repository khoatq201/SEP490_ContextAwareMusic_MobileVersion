import type { DefaultOptionType } from 'antd/es/select';

// Vietnam Cities (common ones)
export const VIETNAM_CITIES: DefaultOptionType[] = [
  { label: 'Hà Nội', value: 'Hà Nội' },
  { label: 'Hồ Chí Minh', value: 'Hồ Chí Minh' },
  { label: 'Đà Nẵng', value: 'Đà Nẵng' },
  { label: 'Hải Phòng', value: 'Hải Phòng' },
  { label: 'Cần Thơ', value: 'Cần Thơ' },
  { label: 'Biên Hòa', value: 'Biên Hòa' },
  { label: 'Nha Trang', value: 'Nha Trang' },
  { label: 'Huế', value: 'Huế' },
] as const;

// Ho Chi Minh Districts
export const HCMC_DISTRICTS: DefaultOptionType[] = [
  { label: 'Quận 1', value: 'Quận 1' },
  { label: 'Quận 2', value: 'Quận 2' },
  { label: 'Quận 3', value: 'Quận 3' },
  { label: 'Quận 4', value: 'Quận 4' },
  { label: 'Quận 5', value: 'Quận 5' },
  { label: 'Quận 6', value: 'Quận 6' },
  { label: 'Quận 7', value: 'Quận 7' },
  { label: 'Quận 8', value: 'Quận 8' },
  { label: 'Quận 9', value: 'Quận 9' },
  { label: 'Quận 10', value: 'Quận 10' },
  { label: 'Quận 11', value: 'Quận 11' },
  { label: 'Quận 12', value: 'Quận 12' },
  { label: 'Bình Thạnh', value: 'Bình Thạnh' },
  { label: 'Tân Bình', value: 'Tân Bình' },
  { label: 'Phú Nhuận', value: 'Phú Nhuận' },
  { label: 'Gò Vấp', value: 'Gò Vấp' },
  { label: 'Thủ Đức', value: 'Thủ Đức' },
] as const;

// Timezone options (IANA format)
export const TIMEZONE_OPTIONS: DefaultOptionType[] = [
  { label: 'Vietnam (UTC+7)', value: 'Asia/Ho_Chi_Minh' },
  { label: 'Singapore (UTC+8)', value: 'Asia/Singapore' },
  { label: 'Bangkok (UTC+7)', value: 'Asia/Bangkok' },
  { label: 'UTC', value: 'UTC' },
] as const;

import { EntityStatusEnum } from '@/shared/types/commonTypes';

export const STORE_STATUS_COLORS = {
  [EntityStatusEnum.Inactive]: 'default',
  [EntityStatusEnum.Active]: 'success',
  [EntityStatusEnum.Pending]: 'processing',
  [EntityStatusEnum.Rejected]: 'error',
} as const;

export const STORE_STATUS_LABELS = {
  [EntityStatusEnum.Inactive]: 'Inactive',
  [EntityStatusEnum.Active]: 'Active',
  [EntityStatusEnum.Pending]: 'Pending',
  [EntityStatusEnum.Rejected]: 'Rejected',
} as const;
