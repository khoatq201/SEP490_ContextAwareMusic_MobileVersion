import { useQuery } from '@tanstack/react-query';

/**
 * Services
 */
import { accountService } from '@/features/admin/services';

/**
 * Configs
 */
import { STALE_TIME } from '@/config';

export const useAccount = (id: string | undefined, enabled: boolean = true) => {
  return useQuery({
    queryKey: ['account', id],
    queryFn: async () => {
      if (!id) throw new Error('Account ID is required');
      const response = await accountService.getById(id);
      return response.data.data;
    },
    enabled: !!id && enabled,
    staleTime: STALE_TIME.medium,
  });
};
