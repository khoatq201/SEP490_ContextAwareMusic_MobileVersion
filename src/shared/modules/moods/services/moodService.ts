import { api } from '@/config';

/**
 * Constants
 */
import { MOOD_ENDPOINTS } from '@/shared/modules/moods/constants';

/**
 * Types
 */
import type { Result } from '@/shared/types/commonTypes';
import type { MoodListItem } from '@/shared/modules/moods/types';

/**
 * Mood Service - API calls for mood management
 * Used by both Brand and Store roles
 */
export const moodService = {
  /**
   * Get all active moods (no pagination needed - small dataset)
   * Auth: SystemAdmin, BrandManager, StoreManager
   */
  getList: async (): Promise<Result<MoodListItem[]>> => {
    const response = await api.get<Result<MoodListItem[]>>(
      MOOD_ENDPOINTS.GET_LIST,
    );
    return response.data;
  },
};
