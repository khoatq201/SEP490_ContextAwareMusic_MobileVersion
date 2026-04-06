import type { SelectProps } from 'antd';

/**
 * Types
 */
import {
  PlaybackCommand,
  PlaybackMode,
  RepeatMode,
  TransitionType,
  OverrideMode,
} from '@/shared/modules/cams/types';

/**
 * Playback command labels (from API_CAMS.md § 2)
 */
export const PLAYBACK_COMMAND_LABELS: Record<PlaybackCommand, string> = {
  [PlaybackCommand.Pause]: 'Pause',
  [PlaybackCommand.Resume]: 'Resume',
  [PlaybackCommand.Seek]: 'Seek',
  [PlaybackCommand.SeekForward]: 'Seek Forward',
  [PlaybackCommand.SeekBackward]: 'Seek Backward',
  [PlaybackCommand.SkipNext]: 'Skip to Next',
  [PlaybackCommand.SkipPrevious]: 'Skip to Previous',
  [PlaybackCommand.SkipToTrack]: 'Skip to Track',
  [PlaybackCommand.TrackEnded]: 'Track Ended',
};

/**
 * Playback mode labels
 */
export const PLAYBACK_MODE_LABELS: Record<PlaybackMode, string> = {
  [PlaybackMode.Sequential]: 'Sequential',
  [PlaybackMode.Shuffle]: 'Shuffle',
};

/**
 * Repeat mode labels
 */
export const REPEAT_MODE_LABELS: Record<RepeatMode, string> = {
  [RepeatMode.Off]: 'Off',
  [RepeatMode.RepeatAll]: 'Repeat All',
  [RepeatMode.RepeatOne]: 'Repeat One',
};

/**
 * Transition type labels (from SIGNALR_STOREHUB.md § 1.1)
 */
export const TRANSITION_TYPE_LABELS: Record<TransitionType, string> = {
  [TransitionType.Immediate]: 'Immediate',
  [TransitionType.Crossfade]: 'Crossfade',
  [TransitionType.Pending]: 'Pending',
};

/**
 * Override mode labels (from API_CAMS.md § 4.1)
 */
export const OVERRIDE_MODE_LABELS: Record<OverrideMode, string> = {
  [OverrideMode.Playlist]: 'Playlist Override',
  [OverrideMode.Mood]: 'Mood Override',
};

/**
 * Playback mode options for Select
 */
export const PLAYBACK_MODE_OPTIONS: SelectProps['options'] = [
  { label: 'Sequential', value: PlaybackMode.Sequential },
  { label: 'Shuffle', value: PlaybackMode.Shuffle },
];

/**
 * Repeat mode options for Select
 */
export const REPEAT_MODE_OPTIONS: SelectProps['options'] = [
  { label: 'Off', value: RepeatMode.Off },
  { label: 'Repeat All', value: RepeatMode.RepeatAll },
  { label: 'Repeat One', value: RepeatMode.RepeatOne },
];

/**
 * Transition type options for Select
 */
export const TRANSITION_TYPE_OPTIONS: SelectProps['options'] = [
  { label: 'Immediate', value: TransitionType.Immediate },
  { label: 'Crossfade', value: TransitionType.Crossfade },
];

/**
 * SignalR Hub URL (relative path)
 * Will be combined with API_BASE_URL from env config
 */
export const STORE_HUB_URL = '/hubs/store';

/**
 * SignalR event names (from SIGNALR_STOREHUB.md)
 */
export const STORE_HUB_EVENTS = {
  // Server → Client events
  PLAY_STREAM: 'PlayStream',
  PLAYBACK_STATE_CHANGED: 'PlaybackStateChanged',
  SPACE_STATE_SYNC: 'SpaceStateSync',

  // Client → Server methods
  JOIN_MANAGER_ROOM: 'JoinManagerRoomAsync',
  LEAVE_MANAGER_ROOM: 'LeaveManagerRoomAsync',
  JOIN_SPACE: 'JoinSpaceAsync',
  LEAVE_SPACE: 'LeaveSpaceAsync',
} as const;

/**
 * Default volume level (0-100)
 */
export const DEFAULT_VOLUME = 75;

/**
 * HLS player config
 */
export const HLS_PLAYER_CONFIG = {
  maxBufferLength: 30,
  maxMaxBufferLength: 60,
  maxBufferSize: 60 * 1000 * 1000, // 60MB
  maxBufferHole: 0.5,
  lowLatencyMode: true,
  backBufferLength: 90,
} as const;

/**
 * Seek step in seconds (for SeekForward/SeekBackward)
 */
export const SEEK_STEP_SECONDS = 10;
