export type DeviceCoordinate = {
  device_id: string;
  device_name: string;
  device_type: 'esp32' | 'android';
  x: number; // Position X (0-100 or pixels)
  y: number; // Position Y (0-100 or pixels)
  status: 'active' | 'offline' | 'unpaired';
  space_id: string;
  space_name: string;
  signal_strength?: number; // Signal strength (0-100)
  value?: number; // For color mapping
};

export type VoronoiPolygon = {
  x: number[]; // Array of X coordinates
  y: number[]; // Array of Y coordinates
  data: DeviceCoordinate; // Original device data
};
