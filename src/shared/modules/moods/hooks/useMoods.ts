import { useQuery } from '@tanstack/react-query';

/**
 * Services
 */
import { moodService } from '@/shared/modules/moods/services';

/**
 * Constants
 */
import { MOOD_QUERY_KEYS } from '@/shared/modules/moods/constants';

/**
 * Types
 */
import type { MoodOption } from '@/shared/modules/moods/types';

/**
 * Configs
 */
import { STALE_TIME } from '@/config';

/**
 * Hook to fetch mood list
 * Returns all active moods sorted by priority
 */
export const useMoods = () => {
  return useQuery({
    queryKey: MOOD_QUERY_KEYS.LIST,
    queryFn: async () => {
      const response = await moodService.getList();
      return response.data;
    },
    staleTime: STALE_TIME.veryLong, // 60 minutes (moods rarely change)
  });
};

/**
 * Hook to get mood options for Select component
 * Transforms MoodListItem[] to SelectOption[]
 */
export const useMoodOptions = (): {
  options: MoodOption[];
  isLoading: boolean;
} => {
  const { data: moods, isLoading } = useMoods();

  const options: MoodOption[] =
    moods?.map((mood) => ({
      label: mood.name,
      value: mood.id,
      moodType: mood.moodType,
      energyLevel: mood.energyLevel,
    })) || [];

  return { options, isLoading };
};
