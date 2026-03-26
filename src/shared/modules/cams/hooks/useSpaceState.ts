import { useQuery } from '@tanstack/react-query';

/**
 * Configs
 */
import { STALE_TIME } from '@/config';

/**
 * Services
 */
import { camsService } from '@/shared/modules/cams/services';

/**
 * Get space current state from API
 * Use this for initial load or when SignalR is not available
 */
export const useSpaceState = (spaceId?: string, enabled = true) => {
  return useQuery({
    queryKey: ['cams-space-state', spaceId],
    queryFn: async () => {
      if (!spaceId) throw new Error('Space ID is required');
      const response = await camsService.getSpaceState(spaceId);
      return response.data.data;
    },
    enabled: !!spaceId && enabled,
    staleTime: STALE_TIME.medium,
  });
};
