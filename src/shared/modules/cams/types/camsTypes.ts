/**
 * Playback command enum (from API_CAMS.md § 2)
 * ⚠️ Must match backend exactly!
 */
export enum PlaybackCommand {
  Pause = 1, // ✅ Backend definition
  Resume = 2,
  Seek = 3,
  SeekForward = 4,
  SeekBackward = 5,
  SkipNext = 6,
  SkipPrevious = 7,
  SkipToTrack = 8,
  TrackEnded = 9, // NEW (2026-03-23): Track ended event
}

/**
 * Transition type enum (from SIGNALR_STOREHUB.md § 1)
 */
export enum TransitionType {
  Immediate = 1,
  Crossfade = 2,
  Pending = 3,
}

/**
 * Playback mode enum
 */
export enum PlaybackMode {
  Sequential = 0,
  Shuffle = 1,
}

/**
 * Repeat mode enum
 */
export enum RepeatMode {
  Off = 0,
  RepeatAll = 1,
  RepeatOne = 2,
}

/**
 * Override mode enum (from API_CAMS.md § 4.1)
 */
export enum OverrideMode {
  Playlist = 1,
  Mood = 2,
}

/**
 * Queue Insert Mode Enum (from API_CAMS.md § 3.3.2)
 * ⚠️ NEW (2026-03-23): Queue insert modes
 */
export enum QueueInsertMode {
  PlayNow = 1, // Switch immediately to first track if stream-ready
  PlayNext = 2, // Insert after currently playing item
  AddToQueue = 3, // Add to end of pending queue
}

/**
 * Queue Item Status Enum (from API_CAMS.md § 3.3.7)
 * ⚠️ NEW (2026-03-23): Queue item status
 */
export enum QueueItemStatus {
  Pending = 0,
  Playing = 1,
  Played = 2,
  Skipped = 3,
}

/**
 * Queue Item Source Enum (from API_CAMS.md § 3.3.7)
 * ⚠️ NEW (2026-03-23): Queue item source
 */
export enum QueueItemSource {
  AI = 0,
  Manager = 1,
}

/**
 * Space Queue Item Response (from API_CAMS.md § 3.3.7)
 * ⚠️ NEW (2026-03-23): Queue item in GET queue response
 */
export interface SpaceQueueItemResponse {
  queueItemId: string;
  trackId: string;
  trackName: string;
  position: number;
  queueStatus: QueueItemStatus;
  source: QueueItemSource;
  hlsUrl: string | null;
  isReadyToStream: boolean;
}

/**
 * Queue End Behavior Enum (from API_CAMS.md)
 * ⚠️ NEW (2026-03-23): Queue end behavior
 */
export enum QueueEndBehavior {
  Stop = 0,
  RepeatQueue = 1,
  ReturnToSchedule = 2,
}

/**
 * Space Queue Item DTO (from SIGNALR_STOREHUB.md § 4)
 * ⚠️ NEW (2026-03-23): Queue item in space state
 */
export interface SpaceQueueItemDto {
  queueItemId: string;
  trackId: string;
  trackName: string | null;
  artist: string | null;
  hlsUrl: string | null;
  durationSec: number | null;
  coverImageUrl: string | null;
  orderIndex: number;
}

/**
 * Space state DTO (from SIGNALR_STOREHUB.md § 4)
 * Used in SignalR SpaceStateSync event
 * ⚠️ BREAKING CHANGE (2026-03-23): currentPlaylistId/Name → currentQueueItemId/TrackName
 * ⚠️ seekOffsetSeconds is always NULL in SignalR - client must calculate from startedAtUtc
 * ⚠️ NEW (2026-03-24): AI Explainability fields for fuzzy logic transparency
 */
export interface SpaceStateDto {
  spaceId: string;
  storeId: string;
  brandId: string;
  currentQueueItemId: string | null; // Changed from currentPlaylistId
  currentTrackName: string | null; // Changed from currentPlaylistName
  hlsUrl: string | null;
  moodName: string | null;
  isManualOverride: boolean;
  overrideMode: OverrideMode | null;
  startedAtUtc: string | null;
  expectedEndAtUtc: string | null;
  seekOffsetSeconds: number | null; // Always null in SignalR
  isPaused: boolean;
  pausePositionSeconds: number | null;
  pendingQueueItemId: string | null; // Changed from pendingPlaylistId
  pendingOverrideReason: string | null;
  volumePercent: number; // NEW: 0-100
  isMuted: boolean; // NEW
  queueEndBehavior: QueueEndBehavior; // NEW
  spaceQueueItems: SpaceQueueItemDto[]; // NEW: Queue items array

  // AI Explainability (NEW 2026-03-24)
  bpmMin?: number | null; // Recommended BPM range minimum
  bpmMax?: number | null; // Recommended BPM range maximum
  bpmTarget?: number | null; // Target BPM within range
  fuzzyRule?: string | null; // Triggered rule name (e.g., "RULE_1_RUSH_HOUR")
  fuzzyReason?: string | null; // Human-readable reason (e.g., "Critical pressure detected")
  isBpmFallback?: boolean | null; // True if using mood-only selection (not enough BPM data)
}

/**
 * Play stream payload (from SIGNALR_STOREHUB.md § 3 - PlayStream event)
 */
export interface PlayStreamPayload {
  spaceId: string;
  hlsUrl: string;
  transitionType: TransitionType;
  playlistId: string;
  isManualOverride: boolean;
  startedAtUtc: string;
}

/**
 * Playback state changed payload (from SIGNALR_STOREHUB.md § 3 - PlaybackStateChanged event)
 */
export interface PlaybackStateChangedPayload {
  spaceId: string;
  command: PlaybackCommand;
  seekPositionSeconds: number | null;
  targetTrackId: string | null;
}

/**
 * Override playlist request (from API_CAMS.md § 3.1)
 * Mode 1: DirectPlaylist (provide playlistId only)
 * Mode 2: MoodOverride (provide moodId only)
 * ⚠️ BREAKING CHANGE (2026-03-23): Added trackIds and isClearManagerSelectedQueues
 * ⚠️ Must provide exactly ONE of playlistId or moodId, not both
 */
export interface OverridePlaylistRequest {
  playlistId?: string | null;
  moodId?: string | null;
  trackIds?: string[] | null; // NEW: Direct track selection
  isClearManagerSelectedQueues?: boolean; // NEW: Clear existing queue
  reason?: string | null; // Optional reason for audit trail
}

/**
 * Add tracks to queue request (from API_CAMS.md § 3.3.2)
 * ⚠️ NEW (2026-03-23): Queue management
 */
export interface AddTracksToQueueRequest {
  trackIds: string[];
  mode: QueueInsertMode; // 1=PlayNow, 2=PlayNext, 3=AddToQueue
  isClearExistingQueue?: boolean; // Default: false
  reason?: string | null; // Max 500 chars
}

/**
 * Add playlist to queue request (from API_CAMS.md § 3.3.3)
 * ⚠️ NEW (2026-03-23): Queue management
 */
export interface AddPlaylistToQueueRequest {
  playlistId: string;
  mode: QueueInsertMode; // 1=PlayNow, 2=PlayNext, 3=AddToQueue
  isClearExistingQueue?: boolean; // Default: false
  reason?: string | null; // Max 500 chars
}

/**
 * Reorder queue request (from API_CAMS.md)
 * ⚠️ NEW (2026-03-23): Queue management
 */
export interface ReorderQueueRequest {
  queueItemIds: string[]; // New order of queue item IDs
}

/**
 * Update audio state request (from API_CAMS.md)
 * ⚠️ NEW (2026-03-23): Volume/mute/queue end behavior control
 */
export interface UpdateAudioStateRequest {
  volumePercent?: number; // 0-100
  isMuted?: boolean;
  queueEndBehavior?: QueueEndBehavior;
}

/**
 * Playback control request (from API_CAMS.md § 3.3)
 */
export interface PlaybackControlRequest {
  command: PlaybackCommand;
  seekPositionSeconds?: number | null;
  targetTrackId?: string | null;
}

/**
 * Space state response (from API_CAMS.md § 3.4)
 * REST API GET /api/cams/spaces/{id}/state
 * ⚠️ BREAKING CHANGE (2026-03-23): currentPlaylistId/Name → currentQueueItemId/TrackName
 * ⚠️ seekOffsetSeconds is calculated server-side at REST call time
 * ⚠️ NEW (2026-03-24): AI Explainability fields for fuzzy logic transparency
 */
export interface SpaceStateResponse {
  spaceId: string;
  storeId: string;
  brandId: string;
  currentQueueItemId: string | null; // Changed from currentPlaylistId
  currentTrackName: string | null; // Changed from currentPlaylistName
  hlsUrl: string | null;
  moodName: string | null;
  isManualOverride: boolean;
  overrideMode: OverrideMode | null;
  startedAtUtc: string | null;
  expectedEndAtUtc: string | null;
  seekOffsetSeconds: number | null; // Calculated server-side in REST
  isPaused: boolean;
  pausePositionSeconds: number | null;
  pendingQueueItemId: string | null; // Changed from pendingPlaylistId
  pendingOverrideReason: string | null;
  volumePercent: number; // NEW: 0-100
  isMuted: boolean; // NEW
  queueEndBehavior: QueueEndBehavior; // NEW
  spaceQueueItems: SpaceQueueItemDto[]; // NEW: Queue items array

  // AI Explainability (NEW 2026-03-24)
  bpmMin?: number | null; // Recommended BPM range minimum
  bpmMax?: number | null; // Recommended BPM range maximum
  bpmTarget?: number | null; // Target BPM within range
  fuzzyRule?: string | null; // Triggered rule name (e.g., "RULE_1_RUSH_HOUR")
  fuzzyReason?: string | null; // Human-readable reason (e.g., "Critical pressure detected")
  isBpmFallback?: boolean | null; // True if using mood-only selection (not enough BPM data)
}

/**
 * Pair code response (from API_CAMS.md § 4.1)
 * POST /api/cams/spaces/{spaceId}/pair-code
 */
export interface PairCodeResponse {
  code: string; // 6-character code (plain)
  displayCode: string; // Code with dash (e.g., "ABC-123")
  spaceId: string;
  spaceName: string;
  expiresAt: string; // ISO 8601 UTC
  expiresInSeconds: number;
}

/**
 * Pair device info response (from API_CAMS.md § 3.5)
 * GET /api/cams/spaces/{spaceId}/pair-device
 */
export interface PairDeviceInfoResponse {
  spaceId: string;
  storeId: string;
  brandId: string;
  deviceSessionId: string | null;
  isPlaybackDeviceCaller: boolean;
  manufacturer: string | null;
  model: string | null;
  osVersion: string | null;
  appVersion: string | null;
  deviceId: string | null;
  pairedAtUtc: string | null; // ISO 8601 UTC
  lastActiveAtUtc: string | null; // ISO 8601 UTC
}
