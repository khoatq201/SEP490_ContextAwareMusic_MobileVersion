import { api } from '@/config';

import type { PaginationResult, Result } from '@/shared/types';
import type {
  FuzzyProfileTemplateDetail,
  FuzzyProfileTemplateListItem,
  FuzzyProfileTemplateOption,
} from '../types/fuzzyProfileTemplateTypes';

const BASE = '/api/fuzzy-profile-templates';

export const fuzzyProfileTemplateService = {
  getForSelect: () =>
    api.get<Result<FuzzyProfileTemplateOption[]>>(`${BASE}/for-select`),

  getManagePaged: (page = 1, pageSize = 20) =>
    api.get<PaginationResult<FuzzyProfileTemplateListItem>>(
      `${BASE}/manage?page=${page}&pageSize=${pageSize}`,
    ),

  getById: (id: string) =>
    api.get<Result<FuzzyProfileTemplateDetail>>(`${BASE}/${id}`),

  create: (body: Record<string, unknown>) =>
    api.post<Result<string>>(BASE, body),

  update: (id: string, body: Record<string, unknown>) =>
    api.put<Result>(`${BASE}/${id}`, body),

  delete: (id: string) => api.delete<Result>(`${BASE}/${id}`),
};
