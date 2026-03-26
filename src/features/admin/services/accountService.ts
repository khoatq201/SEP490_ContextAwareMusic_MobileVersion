import { api } from '@/config';

/**
 * Types
 */
import type {
  AccountListItem,
  AccountDetailResponse,
  ResetPasswordRequest,
  AssignBrandRequest,
  AssignStoreRequest,
  AccountFilter,
} from '../types';
import type { PaginationResult, Result } from '@/shared/types';

const ACCOUNT_ENDPOINTS = {
  list: '/api/users',
  detail: (id: string) => `/api/users/${id}`,
  create: '/api/users',
  update: (id: string) => `/api/users/${id}`,
  toggleStatus: (id: string) => `/api/users/${id}/status`,
  resetPassword: (id: string) => `/api/users/${id}/reset-password`,
  assignBrand: (id: string) => `/api/users/${id}/brand`,
  assignStore: (id: string) => `/api/users/${id}/store`,
};

export const accountService = {
  // GET /api/users?page=1&pageSize=10
  getList: (filter: AccountFilter = {}) => {
    const params = new URLSearchParams();
    if (filter.page) params.append('page', filter.page.toString());
    if (filter.pageSize) params.append('pageSize', filter.pageSize.toString());
    if (filter.search) params.append('search', filter.search);
    if (filter.sortBy) params.append('sortBy', filter.sortBy);
    if (filter.isAscending !== undefined)
      params.append('isAscending', filter.isAscending.toString());
    if (filter.status !== undefined)
      params.append('status', filter.status.toString());
    if (filter.role !== undefined)
      params.append('role', filter.role.toString());
    if (filter.brandId) params.append('brandId', filter.brandId);
    // if (filter.storeId) params.append('storeId', filter.storeId);
    // if (filter.joiningFrom) params.append('joiningFrom', filter.joiningFrom);
    // if (filter.joiningTo) params.append('joiningTo', filter.joiningTo);
    // if (filter.isPrimaryOwner !== undefined)
    //   params.append('isPrimaryOwner', filter.isPrimaryOwner.toString());

    return api.get<PaginationResult<AccountListItem>>(
      `${ACCOUNT_ENDPOINTS.list}?${params.toString()}`,
    );
  },

  // GET /api/users/{id}
  getById: (id: string) =>
    api.get<Result<AccountDetailResponse>>(ACCOUNT_ENDPOINTS.detail(id)),

  // POST /api/users (multipart/form-data)
  create: (formData: FormData) =>
    api.post<Result>(ACCOUNT_ENDPOINTS.create, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    }),

  // PATCH /api/users/{id} (multipart/form-data, partial)
  update: (id: string, formData: FormData) =>
    api.patch<Result>(ACCOUNT_ENDPOINTS.update(id), formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    }),

  // PUT /api/users/{id}/status
  toggleStatus: (id: string) =>
    api.put<Result>(ACCOUNT_ENDPOINTS.toggleStatus(id)),

  // PUT /api/users/{id}/reset-password
  resetPassword: (id: string, data: ResetPasswordRequest) =>
    api.put<Result>(ACCOUNT_ENDPOINTS.resetPassword(id), data),

  // PUT /api/users/{id}/brand (SA only)
  assignBrand: (id: string, data: AssignBrandRequest) =>
    api.put<Result>(ACCOUNT_ENDPOINTS.assignBrand(id), data),

  // PUT /api/users/{id}/store
  assignStore: (id: string, data: AssignStoreRequest) =>
    api.put<Result>(ACCOUNT_ENDPOINTS.assignStore(id), data),
};
