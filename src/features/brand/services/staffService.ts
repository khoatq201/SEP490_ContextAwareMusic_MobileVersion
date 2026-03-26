import { api } from '@/config';

/**
 * Types
 */
import type {
  StaffFilter,
  StaffListItem,
  StaffDetailResponse,
  ResetStaffPasswordRequest,
  AssignStaffStoreRequest,
} from '../types';
import type { PaginationResult, Result } from '@/shared/types';

const STAFF_ENDPOINTS = {
  list: '/api/users',
  detail: (id: string) => `/api/users/${id}`,
  create: '/api/users',
  update: (id: string) => `/api/users/${id}`,
  resetPassword: (id: string) => `/api/users/${id}/reset-password`,
  assignStore: (id: string) => `/api/users/${id}/store`,
  toggleStatus: (id: string) => `/api/users/${id}/status`,
} as const;

export const staffService = {
  // GET /api/users (BrandManager filtered to own brand)
  getList: (filter: StaffFilter = {}) => {
    const params = new URLSearchParams();
    if (filter.page) params.append('page', filter.page.toString());
    if (filter.pageSize) params.append('pageSize', filter.pageSize.toString());
    if (filter.search) params.append('search', filter.search);
    if (filter.sortBy) params.append('sortBy', filter.sortBy);
    if (filter.isAscending !== undefined)
      params.append('isAscending', filter.isAscending.toString());
    if (filter.status !== undefined)
      params.append('status', filter.status.toString());
    if (filter.storeId) params.append('storeId', filter.storeId);
    if (filter.role !== undefined)
      params.append('role', filter.role.toString());

    return api.get<PaginationResult<StaffListItem>>(
      `${STAFF_ENDPOINTS.list}?${params.toString()}`,
    );
  },

  // GET /api/users/{id}
  getById: (id: string) =>
    api.get<Result<StaffDetailResponse>>(STAFF_ENDPOINTS.detail(id)),

  // POST /api/users (multipart/form-data for avatar)
  create: (formData: FormData) =>
    api.post<Result>(STAFF_ENDPOINTS.create, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    }),

  // PATCH /api/users/{id} (multipart/form-data for avatar)
  update: (id: string, formData: FormData) =>
    api.patch<Result>(STAFF_ENDPOINTS.update(id), formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    }),

  // PUT /api/users/{id}/reset-password
  resetPassword: (id: string, data: ResetStaffPasswordRequest) =>
    api.put<Result>(STAFF_ENDPOINTS.resetPassword(id), data),

  // PUT /api/users/{id}/store
  assignStore: (id: string, data: AssignStaffStoreRequest) =>
    api.put<Result>(STAFF_ENDPOINTS.assignStore(id), data),

  // PUT /api/users/{id}/status
  toggleStatus: (id: string) =>
    api.put<Result>(STAFF_ENDPOINTS.toggleStatus(id)),
};
