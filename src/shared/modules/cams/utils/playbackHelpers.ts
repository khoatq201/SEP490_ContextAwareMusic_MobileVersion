/**
 * Format seconds to MM:SS or HH:MM:SS
 */
export const formatPlaybackTime = (seconds: number): string => {
  if (!seconds || seconds < 0) return '0:00';

  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = Math.floor(seconds % 60);

  if (hours > 0) {
    return `${hours}:${minutes.toString().padStart(2, '0')}:${secs
      .toString()
      .padStart(2, '0')}`;
  }

  return `${minutes}:${secs.toString().padStart(2, '0')}`;
};

/**
 * Calculate progress percentage
 */
export const calculateProgress = (
  currentSeconds: number,
  totalSeconds: number,
): number => {
  if (!totalSeconds || totalSeconds <= 0) return 0;
  return Math.min((currentSeconds / totalSeconds) * 100, 100);
};

/**
 * Convert volume (0-100) to audio element volume (0-1)
 */
export const volumeToAudioLevel = (volume: number): number => {
  return Math.max(0, Math.min(100, volume)) / 100;
};

/**
 * Convert audio element volume (0-1) to volume (0-100)
 */
export const audioLevelToVolume = (level: number): number => {
  return Math.round(Math.max(0, Math.min(1, level)) * 100);
};

/**
 * Check if space is currently playing
 * Based on isPaused flag and time range (startedAtUtc, expectedEndAtUtc)
 *
 * ⚠️ IMPORTANT: isPaused takes priority over time-based calculation
 */
export const isSpacePlaying = (state: {
  isPaused?: boolean;
  startedAtUtc: string | null;
  expectedEndAtUtc: string | null;
}): boolean => {
  // ✅ Priority 1: Check isPaused flag (from server state)
  if (state.isPaused === true) {
    return false;
  }

  // ✅ Priority 2: Check time range (for AI-scheduled playlists)
  if (!state.startedAtUtc || !state.expectedEndAtUtc) {
    return false;
  }

  const now = new Date();
  const startedAt = new Date(state.startedAtUtc);
  const expectedEndAt = new Date(state.expectedEndAtUtc);

  // Currently playing if now is between start and end
  return now >= startedAt && now <= expectedEndAt;
};

/**
 * Calculate effective seek offset from SpaceStateDto/SpaceStateResponse
 * (from SIGNALR_STOREHUB.md § 4 - SpaceStateDto notes)
 *
 * Used for both REST and SignalR responses:
 * - REST: seekOffsetSeconds is pre-calculated by server
 * - SignalR: seekOffsetSeconds is null, calculate from startedAtUtc
 */
export const getEffectiveSeekOffset = (state: {
  isPaused: boolean;
  pausePositionSeconds: number | null;
  seekOffsetSeconds: number | null;
  startedAtUtc: string | null;
}): number => {
  // Priority 1: If paused, use pause position
  if (state.isPaused) {
    return state.pausePositionSeconds ?? 0;
  }

  // Priority 2: If REST response has seekOffsetSeconds, use it
  if (state.seekOffsetSeconds != null) {
    return state.seekOffsetSeconds;
  }

  // Priority 3: Calculate from startedAtUtc (SignalR case)
  if (!state.startedAtUtc) {
    return 0;
  }

  const now = Date.now();
  const startedAt = new Date(state.startedAtUtc).getTime();
  return Math.max(0, (now - startedAt) / 1000);
};

/**
 * Check if HLS is supported in current browser
 */
export const isHLSSupported = (): boolean => {
  const video = document.createElement('video');
  return video.canPlayType('application/vnd.apple.mpegurl') !== '';
};

/**
 * Get error message for HLS errors
 */
export const getHLSErrorMessage = (errorType: string): string => {
  const errorMessages: Record<string, string> = {
    NETWORK_ERROR: 'Network error. Please check your connection.',
    MEDIA_ERROR: 'Media error. The stream may be corrupted.',
    MUX_ERROR: 'Stream format error. Please contact support.',
    OTHER_ERROR: 'Playback error. Please try again.',
  };

  return errorMessages[errorType] || 'Unknown error occurred';
};
