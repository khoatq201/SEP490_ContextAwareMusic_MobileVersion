import { useQuery } from '@tanstack/react-query';

/**
 * Services
 */
import { storeService } from '@/features/brand/services';

/**
 * Types
 */
import type { StoreFilter } from '@/features/brand/types';
import { STALE_TIME } from '@/config';

export const useStores = (filter: StoreFilter = {}) => {
  return useQuery({
    queryKey: ['stores', filter],
    queryFn: async () => {
      const response = await storeService.getList(filter);
      return response.data;
    },
    staleTime: STALE_TIME.medium,
    placeholderData: (previousData) => previousData,
  });
};
