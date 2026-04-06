import type { BaseResponse, PaginationResult } from '@/shared/types';

// ============================================================================
// Enums
// ============================================================================

export enum PlaylistTypeEnum {
  Static = 0,
  Dynamic = 1,
}

// ============================================================================
// Request DTOs
// ============================================================================

/**
 * Create Playlist Request (from API_Playlists.md)
 * ⚠️ BREAKING CHANGE (2026-03-23): Removed isDynamic, hlsUrl, totalDurationSeconds
 */
export interface CreatePlaylistRequest {
  name: string;
  storeId: string;
  moodId?: string;
  description?: string;
  isDefault?: boolean;
  trackIds?: string[]; // Initial tracks
}

/**
 * Update Playlist Request (from API_Playlists.md)
 * ⚠️ BREAKING CHANGE (2026-03-23): Removed isDynamic, hlsUrl, totalDurationSeconds
 */
export interface UpdatePlaylistRequest {
  name?: string;
  moodId?: string;
  description?: string;
  isDefault?: boolean;
  trackIds?: string[] | null; // null = no change; [] = clear all; [...] = sync
}

export interface AddTracksToPlaylistRequest {
  trackIds: string[];
}

// ============================================================================
// Filter
// ============================================================================

/**
 * Playlist Filter (from API_Playlists.md)
 * ⚠️ BREAKING CHANGE (2026-03-23): Removed isDynamic filter
 */
export interface PlaylistFilter {
  page?: number;
  pageSize?: number;
  search?: string;
  sortBy?: string;
  isAscending?: boolean;
  status?: number;
  brandId?: string;
  storeId?: string;
  moodId?: string;
  isDefault?: boolean;
  createdFrom?: string;
  createdTo?: string;
}

// ============================================================================
// Response DTOs
// ============================================================================

/**
 * Playlist List Item (from API_Playlists.md)
 * ⚠️ BREAKING CHANGE (2026-03-23): Removed isDynamic, hlsUrl, totalDurationSeconds
 */
export interface PlaylistListItem extends BaseResponse {
  brandId?: string;
  storeId?: string;
  storeName?: string;
  moodId?: string;
  moodName?: string;
  name?: string;
  description?: string;
  isDefault?: boolean;
  trackCount: number;
}

/**
 * Playlist Track Item (from API_Playlists.md)
 * ⚠️ BREAKING CHANGE (2026-03-23): Each track now has hlsUrl + seekOffsetSeconds
 */
export interface PlaylistTrackItem {
  trackId: string;
  title?: string;
  artist?: string;
  durationSec?: number;
  orderIndex?: number;
  coverImageUrl?: string;
  actualDurationSec?: number;
  hlsUrl?: string; // HLS URL per track (.m3u8)
  seekOffsetSeconds: number; // Server-calculated cumulative offset for SkipToTrack
}

export interface PlaylistDetailResponse extends PlaylistListItem {
  tracks: PlaylistTrackItem[];
}

// ============================================================================
// Pagination Result
// ============================================================================

export type PlaylistPaginationResult = PaginationResult<PlaylistListItem>;
