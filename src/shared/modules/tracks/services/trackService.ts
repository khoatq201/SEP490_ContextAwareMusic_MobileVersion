import { api } from '@/config';

/**
 * Types
 */
import type {
  TrackFilter,
  TrackDetailResponse,
  CreateTrackRequest,
  UpdateTrackRequest,
  TrackListItem,
} from '@/shared/modules/tracks/types';
import type { PaginationResult, Result } from '@/shared/types';

/**
 * Track API Endpoints (from API_Tracks.md)
 * ⚠️ NEW (2026-03-23): Added retranscode endpoint
 */
const TRACK_ENDPOINTS = {
  list: '/api/tracks',
  detail: (id: string) => `/api/tracks/${id}`,
  create: '/api/tracks',
  update: (id: string) => `/api/tracks/${id}`,
  delete: (id: string) => `/api/tracks/${id}`,
  toggleStatus: (id: string) => `/api/tracks/${id}/toggle-status`,
  retranscode: (id: string) => `/api/tracks/${id}/retranscode`, // NEW
} as const;

/**
 * Create FormData from CreateTrackRequest
 * Converts JSON + files to multipart/form-data
 */
const createFormData = (data: CreateTrackRequest): FormData => {
  const formData = new FormData();

  // Append text fields
  formData.append('title', data.title);
  if (data.artist) formData.append('artist', data.artist);
  if (data.moodId) formData.append('moodId', data.moodId);
  if (data.durationSec !== undefined)
    formData.append('durationSec', data.durationSec.toString());
  if (data.bpm !== undefined) formData.append('bpm', data.bpm.toString());
  if (data.genre) formData.append('genre', data.genre);
  if (data.energyLevel !== undefined)
    formData.append('energyLevel', data.energyLevel.toString());
  if (data.valence !== undefined)
    formData.append('valence', data.valence.toString());
  if (data.provider !== undefined)
    formData.append('provider', data.provider.toString());

  // Append files
  formData.append('audioFile', data.audioFile);
  if (data.coverImageFile)
    formData.append('coverImageFile', data.coverImageFile);

  return formData;
};

/**
 * Create FormData from UpdateTrackRequest (partial)
 * Only non-null fields are appended
 */
const createUpdateFormData = (data: UpdateTrackRequest): FormData => {
  const formData = new FormData();

  // Append only non-null fields
  if (data.title) formData.append('title', data.title);
  if (data.artist) formData.append('artist', data.artist);
  if (data.moodId) formData.append('moodId', data.moodId);
  if (data.durationSec !== undefined && data.durationSec !== null)
    formData.append('durationSec', data.durationSec.toString());
  if (data.bpm !== undefined && data.bpm !== null)
    formData.append('bpm', data.bpm.toString());
  if (data.genre) formData.append('genre', data.genre);
  if (data.energyLevel !== undefined && data.energyLevel !== null)
    formData.append('energyLevel', data.energyLevel.toString());
  if (data.valence !== undefined && data.valence !== null)
    formData.append('valence', data.valence.toString());

  // Append files if provided
  if (data.audioFile) formData.append('audioFile', data.audioFile);
  if (data.coverImageFile)
    formData.append('coverImageFile', data.coverImageFile);

  return formData;
};

/**
 * Track Service
 * Used by: SystemAdmin (read), BrandManager (full CRUD), StoreManager (read)
 */
export const trackService = {
  /**
   * GET /api/tracks - List tracks with filters
   * Authorization: SystemAdmin, BrandManager (own brand), StoreManager (own brand)
   *
   * @param filter - TrackFilter with pagination & search params
   * @returns Promise<PaginationResult<TrackListItem>>
   */
  getList: (filter: TrackFilter = {}) => {
    const params = new URLSearchParams();

    // Pagination (inherited from BasePaginationFilter)
    if (filter.page) params.append('page', filter.page.toString());
    if (filter.pageSize) params.append('pageSize', filter.pageSize.toString());

    // Search & Sort
    if (filter.search) params.append('search', filter.search);
    if (filter.sortBy) params.append('sortBy', filter.sortBy);
    if (filter.isAscending !== undefined)
      params.append('isAscending', filter.isAscending.toString());

    // Status filter
    if (filter.status !== undefined)
      params.append('status', filter.status.toString());

    // Track-specific filters
    if (filter.brandId) params.append('brandId', filter.brandId); // SystemAdmin only
    if (filter.moodId) params.append('moodId', filter.moodId);
    if (filter.genre) params.append('genre', filter.genre);
    if (filter.provider !== undefined)
      params.append('provider', filter.provider.toString());
    if (filter.isAiGenerated !== undefined)
      params.append('isAiGenerated', filter.isAiGenerated.toString());
    if (filter.createdFrom) params.append('createdFrom', filter.createdFrom);
    if (filter.createdTo) params.append('createdTo', filter.createdTo);

    return api.get<PaginationResult<TrackListItem>>(
      `${TRACK_ENDPOINTS.list}?${params.toString()}`,
    );
  },

  /**
   * GET /api/tracks/{id} - Get track detail
   * Authorization: SystemAdmin, BrandManager (own brand), StoreManager (own brand)
   *
   * @param id - Track ID (Guid)
   * @returns Promise<Result<TrackDetailResponse>>
   */
  getById: (id: string) => {
    return api.get<Result<TrackDetailResponse>>(TRACK_ENDPOINTS.detail(id));
  },

  /**
   * POST /api/tracks - Create new track (multipart/form-data)
   * Authorization: BrandManager only
   *
   * @param data - CreateTrackRequest with audio file (required) + cover (optional)
   * @returns Promise<Result>
   *
   * @note Audio upload is non-fatal - track created with audioUrl=null if S3 upload fails
   * @note brandId is auto-filled from user.BrandId (not needed in request)
   */
  create: (data: CreateTrackRequest) => {
    const formData = createFormData(data);
    return api.post<Result>(TRACK_ENDPOINTS.create, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  },

  /**
   * PUT /api/tracks/{id} - Update track (multipart/form-data, partial)
   * Authorization: BrandManager only
   *
   * @param id - Track ID (Guid)
   * @param data - UpdateTrackRequest (all fields optional)
   * @returns Promise<Result>
   *
   * @note Partial update: null fields keep existing values
   * @note audioFile=null keeps existing audio, audioFile=File replaces it
   */
  update: (id: string, data: UpdateTrackRequest) => {
    const formData = createUpdateFormData(data);
    return api.put<Result>(TRACK_ENDPOINTS.update(id), formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  },

  /**
   * DELETE /api/tracks/{id} - Soft delete track
   * Authorization: BrandManager only
   *
   * @param id - Track ID (Guid)
   * @returns Promise<Result>
   *
   * @throws 422 BusinessRuleViolation if track is used in any playlist
   */
  delete: (id: string) => {
    return api.delete<Result>(TRACK_ENDPOINTS.delete(id));
  },

  /**
   * PUT /api/tracks/{id}/toggle-status - Toggle track status (Active ↔ Inactive)
   * Authorization: BrandManager only
   *
   * @param id - Track ID (Guid)
   * @returns Promise<Result>
   */
  toggleStatus: (id: string) => {
    return api.put<Result>(TRACK_ENDPOINTS.toggleStatus(id));
  },

  /**
   * POST /api/tracks/{id}/retranscode - Force retranscode track to HLS
   * Authorization: BrandManager, StoreManager
   * ⚠️ NEW (2026-03-23): Track-level retranscode (replaces playlist-level)
   *
   * @param id - Track ID (Guid)
   * @returns Promise<Result>
   *
   * @note Queues MediaConvert job to regenerate HLS segments
   * @note Track hlsUrl will be updated when transcode completes
   */
  retranscode: (id: string) => {
    return api.post<Result>(TRACK_ENDPOINTS.retranscode(id));
  },
};
