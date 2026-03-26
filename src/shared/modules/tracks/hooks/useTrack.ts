import { useQuery } from '@tanstack/react-query';

/**
 * Services
 */
import { trackService } from '@/shared/modules/tracks/services';

/**
 * Configs
 */
import { STALE_TIME } from '@/config';

export const useTrack = (id?: string, enabled = true) => {
  return useQuery({
    queryKey: ['tracks', id],
    queryFn: async () => {
      if (!id) throw new Error('Track ID is required');
      const response = await trackService.getById(id);
      return response.data.data;
    },
    enabled: enabled && !!id,
    staleTime: STALE_TIME.medium,
  });
};
