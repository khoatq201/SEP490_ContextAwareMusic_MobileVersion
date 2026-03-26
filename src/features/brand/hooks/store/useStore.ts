import { useQuery } from '@tanstack/react-query';

/**
 * Services
 */
import { storeService } from '@/features/brand/services';
import { STALE_TIME } from '@/config';

export const useStore = (id: string | undefined, enabled: boolean = true) => {
  return useQuery({
    queryKey: ['store', id],
    queryFn: async () => {
      if (!id) throw new Error('Store ID is required');
      const response = await storeService.getById(id);
      return response.data.data;
    },
    enabled: enabled && !!id,
    staleTime: STALE_TIME.medium,
  });
};
