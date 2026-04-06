import { useQuery } from '@tanstack/react-query';

/**
 * Services
 */
import { brandService } from '@/features/admin/services';

/**
 * Types
 */
import type { BrandFilter } from '@/features/admin/types';

/**
 * Config
 */
import { STALE_TIME, QUERY_KEYS } from '@/config';

export const useBrands = (filter: BrandFilter = {}) => {
  return useQuery({
    queryKey: QUERY_KEYS.brands.list(filter),
    queryFn: async () => {
      const response = await brandService.getList(filter);
      return response.data;
    },
    staleTime: STALE_TIME.medium,
    placeholderData: (previousData) => previousData,
  });
};
