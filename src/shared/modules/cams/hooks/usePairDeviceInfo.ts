import { useQuery } from '@tanstack/react-query';
import { STALE_TIME } from '@/config';
import { camsService } from '../services';

/**
 * Hook to get pair device info for a space
 * GET /api/cams/spaces/{spaceId}/pair-device
 */
export const usePairDeviceInfo = (spaceId?: string, enabled = true) => {
  return useQuery({
    queryKey: ['pairDeviceInfo', spaceId],
    queryFn: async () => {
      if (!spaceId) throw new Error('Space ID is required');
      const response = await camsService.getPairDeviceInfo(spaceId);
      return response.data.data;
    },
    enabled: !!spaceId && enabled,
    staleTime: STALE_TIME.short, // 1 minute - refresh frequently for device status
    refetchInterval: 30000, // Auto-refetch every 30 seconds when active
  });
};
