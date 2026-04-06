export type DeviceType = 'esp32' | 'android';

export type DeviceStatus = 'unpaired' | 'paired' | 'active' | 'offline';

export type PairingMethod = 'qr_code' | 'pairing_code';

export type Device = {
  id: string;
  device_id: string; // MAC address or Android ID
  device_type: DeviceType;
  space_id?: string;
  space_name?: string;
  status: DeviceStatus;
  pairing_code?: string;
  pairing_code_expires_at?: string;
  last_connected_at?: string;
  device_info?: {
    os_version?: string;
    firmware_version?: string;
    ip_address?: string;
  };
  created_at: string;
  updated_at: string;
};

export type PairDevicePayload = {
  space_id: string;
  pairing_method: PairingMethod;
  pairing_code?: string; // For ESP32
};

export type QRCodePayload = {
  space_id: string;
  device_token: string;
  api_endpoint: string;
  expires_at: string;
};
