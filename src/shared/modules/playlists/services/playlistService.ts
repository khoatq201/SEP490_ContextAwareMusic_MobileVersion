import { api } from '@/config';

/**
 * Types
 */
import type {
  PlaylistPaginationResult,
  PlaylistDetailResponse,
  CreatePlaylistRequest,
  UpdatePlaylistRequest,
  AddTracksToPlaylistRequest,
  PlaylistFilter,
} from '@/shared/modules/playlists/types';
import type { Result } from '@/shared/types';

/**
 * Playlist API Endpoints (from API_Playlists.md)
 * ⚠️ BREAKING CHANGE (2026-03-23): Removed retranscode endpoint (moved to track-level)
 */
const PLAYLIST_ENDPOINTS = {
  list: '/api/playlists',
  create: '/api/playlists',
  detail: (id: string) => `/api/playlists/${id}`,
  update: (id: string) => `/api/playlists/${id}`,
  delete: (id: string) => `/api/playlists/${id}`,
  toggleStatus: (id: string) => `/api/playlists/${id}/toggle-status`,
  addTracks: (id: string) => `/api/playlists/${id}/tracks`,
  removeTrack: (id: string, trackId: string) =>
    `/api/playlists/${id}/tracks/${trackId}`,
} as const;

export const playlistService = {
  /**
   * Get paginated playlist list
   * ⚠️ BREAKING CHANGE (2026-03-23): Removed isDynamic filter
   */
  getList: (filter: PlaylistFilter = {}) => {
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
    if (filter.moodId) params.append('moodId', filter.moodId);
    if (filter.isDefault !== undefined)
      params.append('isDefault', filter.isDefault.toString());
    if (filter.createdFrom) params.append('createdFrom', filter.createdFrom);
    if (filter.createdTo) params.append('createdTo', filter.createdTo);

    return api.get<PlaylistPaginationResult>(
      `${PLAYLIST_ENDPOINTS.list}?${params.toString()}`,
    );
  },

  /**
   * Get playlist detail by ID
   */
  getById: (id: string) => {
    return api.get<Result<PlaylistDetailResponse>>(
      PLAYLIST_ENDPOINTS.detail(id),
    );
  },

  /**
   * Create new playlist
   */
  create: (data: CreatePlaylistRequest) => {
    return api.post<Result>(PLAYLIST_ENDPOINTS.create, data);
  },

  /**
   * Update playlist
   */
  update: (id: string, data: UpdatePlaylistRequest) => {
    return api.put<Result>(PLAYLIST_ENDPOINTS.update(id), data);
  },

  /**
   * Delete playlist (soft delete)
   */
  delete: (id: string) => {
    return api.delete<Result>(PLAYLIST_ENDPOINTS.delete(id));
  },

  /**
   * Toggle playlist status (Active ↔ Inactive)
   */
  toggleStatus: (id: string) => {
    return api.put<Result>(PLAYLIST_ENDPOINTS.toggleStatus(id));
  },

  /**
   * Add tracks to playlist
   */
  addTracks: (id: string, data: AddTracksToPlaylistRequest) => {
    return api.post<Result>(PLAYLIST_ENDPOINTS.addTracks(id), data);
  },

  /**
   * Remove track from playlist
   */
  removeTrack: (id: string, trackId: string) => {
    return api.delete<Result>(PLAYLIST_ENDPOINTS.removeTrack(id, trackId));
  },
};
