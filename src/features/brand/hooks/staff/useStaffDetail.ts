import { useQuery } from '@tanstack/react-query';

/**
 * Services
 */
import { staffService } from '@/features/brand/services';
import { STALE_TIME } from '@/config';

export const useStaffDetail = (
  id: string | undefined,
  enabled: boolean = true,
) => {
  return useQuery({
    queryKey: ['staff-detail', id],
    queryFn: async () => {
      if (!id) throw new Error('Staff ID is required');
      const response = await staffService.getById(id);
      return response.data.data;
    },
    enabled: enabled && !!id,
    staleTime: STALE_TIME.medium,
  });
};
