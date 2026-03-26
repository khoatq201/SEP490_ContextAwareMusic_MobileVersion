import { MoodType } from '@/shared/modules/moods/types';

/**
 * API Endpoints
 */
export const MOOD_ENDPOINTS = {
  GET_LIST: '/api/moods',
} as const;

/**
 * Mood Type Labels (from API_Moods.md §3)
 */
export const MOOD_TYPE_LABELS: Record<MoodType, string> = {
  [MoodType.Calm]: 'Calm',
  [MoodType.Energetic]: 'Energetic',
  [MoodType.Focus]: 'Focus',
  [MoodType.Social]: 'Social',
  [MoodType.Romantic]: 'Romantic',
  [MoodType.Uplifting]: 'Uplifting',
};

/**
 * Mood Type Colors for UI
 */
export const MOOD_TYPE_COLORS: Record<MoodType, string> = {
  [MoodType.Calm]: '#87d068', // Green
  [MoodType.Energetic]: '#ff4d4f', // Red
  [MoodType.Focus]: '#1890ff', // Blue
  [MoodType.Social]: '#faad14', // Orange
  [MoodType.Romantic]: '#eb2f96', // Pink
  [MoodType.Uplifting]: '#722ed1', // Purple
};

/**
 * Mood Type Descriptions
 */
export const MOOD_TYPE_DESCRIPTIONS: Record<MoodType, string> = {
  [MoodType.Calm]: 'Lo-fi / ambient — thư giãn',
  [MoodType.Energetic]: 'Upbeat / Electronic — năng lượng',
  [MoodType.Focus]: 'Acoustic / Jazz — tập trung',
  [MoodType.Social]: 'Nhạc nền xã hội',
  [MoodType.Romantic]: 'R&B / Ballad lãng mạn',
  [MoodType.Uplifting]: 'Pop / Gospel truyền cảm hứng',
};

/**
 * Query Keys
 */
export const MOOD_QUERY_KEYS = {
  LIST: ['moods'] as const,
};
