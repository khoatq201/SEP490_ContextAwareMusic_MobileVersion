export type BusinessType = 'cafe' | 'retail' | 'restaurant' | 'other';

export type Store = {
  id: string;
  store_name: string;
  business_type: BusinessType;
  description?: string;
  // manager_emails: string[];
  created_at: string;
  updated_at: string;
};

export type CreateStorePayload = {
  store_name: string;
  business_type: BusinessType;
  description?: string;
};
