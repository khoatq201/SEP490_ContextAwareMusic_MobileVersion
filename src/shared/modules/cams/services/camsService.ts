import { api } from '@/config';
import type { Result } from '@/shared/types';
import type {
  SpaceStateResponse,
  OverridePlaylistRequest,
  PlaybackControlRequest,
  PairCodeResponse,
  PairDeviceInfoResponse,
  AddTracksToQueueRequest,
  AddPlaylistToQueueRequest,
  ReorderQueueRequest,
  UpdateAudioStateRequest,
  SpaceQueueItemResponse,
} from '../types';

/**
 * CAMS API endpoints
 * ⚠️ NEW (2026-03-23): Added queue management endpoints
 */
const CAMS_ENDPOINTS = {
  spaceState: (spaceId: string) => `/api/cams/spaces/${spaceId}/state`,
  overridePlaylist: (spaceId: string) => `/api/cams/spaces/${spaceId}/override`,
  playbackControl: (spaceId: string) => `/api/cams/spaces/${spaceId}/playback`,
  pairCode: (spaceId: string) => `/api/cams/spaces/${spaceId}/pair-code`,
  pairDevice: (spaceId: string) => `/api/cams/spaces/${spaceId}/pair-device`,
  unpair: (spaceId: string) => `/api/cams/spaces/${spaceId}/unpair`,
  // NEW: Queue management endpoints
  addTracksToQueue: (spaceId: string) =>
    `/api/cams/spaces/${spaceId}/queue/tracks`,
  addPlaylistToQueue: (spaceId: string) =>
    `/api/cams/spaces/${spaceId}/queue/playlist`,
  reorderQueue: (spaceId: string) =>
    `/api/cams/spaces/${spaceId}/queue/reorder`,
  getQueue: (spaceId: string) => `/api/cams/spaces/${spaceId}/queue`,
  clearQueue: (spaceId: string) => `/api/cams/spaces/${spaceId}/queue/all`,
  removeQueueItem: (spaceId: string, queueItemId: string) =>
    `/api/cams/spaces/${spaceId}/queue/${queueItemId}`,
  updateAudioState: (spaceId: string) =>
    `/api/cams/spaces/${spaceId}/state/audio`,
} as const;

/**
 * CAMS API Service
 * Handles REST API calls for CAMS operations
 */
export const camsService = {
  /**
   * Get space current state (§ 4.3)
   * GET /api/cams/spaces/{spaceId}/state
   */
  getSpaceState: (spaceId: string) =>
    api.get<Result<SpaceStateResponse>>(CAMS_ENDPOINTS.spaceState(spaceId)),

  /**
   * Override playlist for a space (§ 4.1)
   * POST /api/cams/spaces/{spaceId}/override
   *
   * Mode 1: Playlist override - send { playlistId: "guid" }
   * Mode 2: Mood override - send { moodId: "guid" }
   */
  overridePlaylist: (spaceId: string, data: OverridePlaylistRequest) =>
    api.post<Result>(CAMS_ENDPOINTS.overridePlaylist(spaceId), data),

  /**
   * Control playback (§ 4.2)
   * POST /api/cams/spaces/{spaceId}/playback
   */
  controlPlayback: (spaceId: string, data: PlaybackControlRequest) =>
    api.post<Result>(CAMS_ENDPOINTS.playbackControl(spaceId), data),

  /**
   * Generate pair code (§ 4.1)
   * POST /api/cams/spaces/{spaceId}/pair-code
   * Auth: BrandManager, StoreManager
   */
  generatePairCode: (spaceId: string) =>
    api.post<Result<PairCodeResponse>>(CAMS_ENDPOINTS.pairCode(spaceId)),

  /**
   * Revoke pair code (§ 4.2)
   * DELETE /api/cams/spaces/{spaceId}/pair-code
   * Auth: BrandManager, StoreManager
   */
  revokePairCode: (spaceId: string) =>
    api.delete<Result>(CAMS_ENDPOINTS.pairCode(spaceId)),

  /**
   * Get pair device info (§ 3.5)
   * GET /api/cams/spaces/{spaceId}/pair-device
   * Auth: BrandManager, StoreManager, PlaybackDevice
   */
  getPairDeviceInfo: (spaceId: string) =>
    api.get<Result<PairDeviceInfoResponse>>(CAMS_ENDPOINTS.pairDevice(spaceId)),

  /**
   * Unpair device (§ 4.3)
   * DELETE /api/cams/spaces/{spaceId}/unpair
   * Auth: BrandManager, StoreManager, PlaybackDevice
   */
  unpairDevice: (spaceId: string) =>
    api.delete<Result>(CAMS_ENDPOINTS.unpair(spaceId)),

  /**
   * Add tracks to queue (NEW 2026-03-23)
   * POST /api/cams/spaces/{spaceId}/queue/tracks
   * Auth: BrandManager, StoreManager
   */
  addTracksToQueue: (spaceId: string, data: AddTracksToQueueRequest) =>
    api.post<Result>(CAMS_ENDPOINTS.addTracksToQueue(spaceId), data),

  /**
   * Add playlist to queue (NEW 2026-03-23)
   * POST /api/cams/spaces/{spaceId}/queue/playlist
   * Auth: BrandManager, StoreManager
   */
  addPlaylistToQueue: (spaceId: string, data: AddPlaylistToQueueRequest) =>
    api.post<Result>(CAMS_ENDPOINTS.addPlaylistToQueue(spaceId), data),

  /**
   * Reorder queue items (NEW 2026-03-23)
   * PATCH /api/cams/spaces/{spaceId}/queue/reorder
   * Auth: BrandManager, StoreManager
   */
  reorderQueue: (spaceId: string, data: ReorderQueueRequest) =>
    api.patch<Result>(CAMS_ENDPOINTS.reorderQueue(spaceId), data),

  /**
   * Get space queue (NEW 2026-03-23)
   * GET /api/cams/spaces/{spaceId}/queue
   * Auth: Any authenticated user
   */
  getQueue: (spaceId: string) =>
    api.get<Result<SpaceQueueItemResponse[]>>(CAMS_ENDPOINTS.getQueue(spaceId)),

  /**
   * Clear all queue items (NEW 2026-03-23)
   * DELETE /api/cams/spaces/{spaceId}/queue/all
   * Auth: BrandManager, StoreManager
   */
  clearQueue: (spaceId: string) =>
    api.delete<Result>(CAMS_ENDPOINTS.clearQueue(spaceId)),

  /**
   * Remove single queue item (NEW 2026-03-23)
   * DELETE /api/cams/spaces/{spaceId}/queue/{queueItemId}
   * Auth: BrandManager, StoreManager
   */
  removeQueueItem: (spaceId: string, queueItemId: string) =>
    api.delete<Result>(CAMS_ENDPOINTS.removeQueueItem(spaceId, queueItemId)),

  /**
   * Update audio state (volume/mute/queueEndBehavior) (NEW 2026-03-23)
   * PATCH /api/cams/spaces/{spaceId}/state/audio
   * Auth: BrandManager, StoreManager
   */
  updateAudioState: (spaceId: string, data: UpdateAudioStateRequest) =>
    api.patch<Result>(CAMS_ENDPOINTS.updateAudioState(spaceId), data),
};
