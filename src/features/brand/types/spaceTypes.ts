export type SpaceStatus = 'active' | 'inactive';

export type Space = {
  id: string;
  branch_id: string;
  space_name: string;
  space_code: string;
  description?: string;
  device_id?: string;
  device_status?: 'connected' | 'disconnected';
  status: SpaceStatus;
  created_at: string;
  updated_at: string;
};

export type CreateSpacePayload = {
  branch_id: string;
  space_name: string;
  space_code: string;
  description?: string;
  device_id?: string;
};
