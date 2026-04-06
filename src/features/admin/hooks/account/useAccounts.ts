import { useQuery } from '@tanstack/react-query';

/**
 * Services
 */
import { accountService } from '@/features/admin/services';

/**
 * Types
 */
import { RoleEnum } from '@/shared/types';
import type { AccountFilter } from '@/features/admin/types';

/**
 * Configs
 */
import { STALE_TIME } from '@/config';

export const useAccounts = (filter: Omit<AccountFilter, 'role'> = {}) => {
  return useQuery({
    queryKey: ['accounts', filter],
    queryFn: async () => {
      const response = await accountService.getList({
        ...filter,
        role: RoleEnum.BrandManager,
      });
      return response.data;
    },
    staleTime: STALE_TIME.medium,
    placeholderData: (previousData) => previousData,
  });
};
