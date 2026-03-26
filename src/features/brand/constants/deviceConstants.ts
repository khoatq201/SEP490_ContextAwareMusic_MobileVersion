import type { DefaultOptionType } from 'antd/es/select';

export const DEVICE_TYPES: DefaultOptionType[] = [
  { label: 'ESP32', value: 'esp32' },
  { label: 'Android', value: 'android' },
] as const;

export const DEVICE_STATUS_COLORS = {
  unpaired: 'default',
  paired: 'processing',
  active: 'success',
  offline: 'error',
} as const;

export const DEVICE_STATUS_LABELS = {
  unpaired: 'Unpaired',
  paired: 'Paired',
  active: 'Active',
  offline: 'Offline',
} as const;

export const PAIRING_CODE_LENGTH = 6;
export const PAIRING_CODE_EXPIRY_MINUTES = 15;
export const QR_CODE_EXPIRY_MINUTES = 10;
