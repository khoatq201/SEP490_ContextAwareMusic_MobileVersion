import { useQuery } from '@tanstack/react-query';

/**
 * Services
 */
import { spaceService } from '@/shared/modules/spaces/services';

/**
 * Types
 */
import type { SpaceFilter } from '@/shared/modules/spaces/types';

/**
 * Configs
 */
import { STALE_TIME } from '@/config';

export const useSpaces = (filter: SpaceFilter = {}, enabled = true) => {
  return useQuery({
    queryKey: ['spaces', filter],
    queryFn: async () => {
      const response = await spaceService.getList(filter);
      return response.data;
    },
    enabled,
    staleTime: STALE_TIME.medium, // 5 minutes
    placeholderData: (previousData) => previousData,
  });
};
