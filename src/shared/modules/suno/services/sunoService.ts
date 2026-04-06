import { api } from '@/config';
import type { Result } from '@/shared/types';
import type { PaginationResult } from '@/shared/types';
import type {
  SunoConfigResponse,
  SunoConfigUpdateRequest,
  SunoGenerationCreateRequest,
  SunoGenerationStatusDto,
} from '../types';

/**
 * Suno API Endpoints
 * See: docs/cams/FE_SUNO_IMPLEMENTATION_GUIDE.md §1
 */
const SUNO_ENDPOINTS = {
  config: '/api/cms/suno/config',
  generations: '/api/cms/suno/generations',
  generationDetail: (id: string) => `/api/cms/suno/generations/${id}`,
  cancelGeneration: (id: string) => `/api/cms/suno/generations/${id}/cancel`,
} as const;

/**
 * Get Suno configuration for current brand
 * GET /api/cms/suno/config
 */
export const getSunoConfig = async (): Promise<Result<SunoConfigResponse>> => {
  const response = await api.get<Result<SunoConfigResponse>>(
    SUNO_ENDPOINTS.config,
  );
  return response.data;
};

/**
 * Update Suno configuration for current brand
 * PUT /api/cms/suno/config
 */
export const updateSunoConfig = async (
  data: SunoConfigUpdateRequest,
): Promise<Result<SunoConfigResponse>> => {
  const response = await api.put<Result<SunoConfigResponse>>(
    SUNO_ENDPOINTS.config,
    data,
  );
  return response.data;
};

/**
 * Create new Suno generation request
 * POST /api/cms/suno/generations
 * Returns 202 Accepted with generation status
 */
export const createSunoGeneration = async (
  data: SunoGenerationCreateRequest,
): Promise<Result<SunoGenerationStatusDto>> => {
  const response = await api.post<Result<SunoGenerationStatusDto>>(
    SUNO_ENDPOINTS.generations,
    data,
  );
  return response.data;
};

/**
 * Get generation status by ID
 * GET /api/cms/suno/generations/{id}
 */
export const getSunoGenerationStatus = async (
  id: string,
): Promise<Result<SunoGenerationStatusDto>> => {
  const response = await api.get<Result<SunoGenerationStatusDto>>(
    SUNO_ENDPOINTS.generationDetail(id),
  );
  return response.data;
};

/**
 * Get generation history (prompt history) for current brand
 * GET /api/cms/suno/generations?page=&pageSize=
 */
export const getSunoGenerationHistory = async (
  page: number = 1,
  pageSize: number = 20,
): Promise<PaginationResult<SunoGenerationStatusDto>> => {
  // NOTE: backend returns PaginationResult directly (not wrapped by Result<T>)
  const response = await api.get<PaginationResult<SunoGenerationStatusDto>>(
    SUNO_ENDPOINTS.generations,
    {
      params: { page, pageSize },
    },
  );
  return response.data;
};

/**
 * Cancel ongoing generation
 * POST /api/cms/suno/generations/{id}/cancel
 */
export const cancelSunoGeneration = async (
  id: string,
): Promise<Result<void>> => {
  const response = await api.post<Result<void>>(
    SUNO_ENDPOINTS.cancelGeneration(id),
  );
  return response.data;
};
