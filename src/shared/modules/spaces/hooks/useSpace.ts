import { useQuery } from '@tanstack/react-query';

/**
 * Services
 */
import { spaceService } from '@/shared/modules/spaces/services';

/**
 * Configs
 */
import { STALE_TIME } from '@/config';

export const useSpace = (id?: string, enabled = true) => {
  return useQuery({
    queryKey: ['space', id],
    queryFn: async () => {
      if (!id) throw new Error('Space ID is required');
      const response = await spaceService.getById(id);
      return response.data.data;
    },
    enabled: enabled && !!id,
    staleTime: STALE_TIME.medium,
  });
};
