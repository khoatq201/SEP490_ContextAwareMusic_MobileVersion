import { useMutation, useQueryClient } from '@tanstack/react-query';
import { QUERY_KEYS } from '@/config';
import { handleApiError } from '@/shared/utils';
import { camsService } from '../services';

/**
 * Cancel manual override for a space.
 */
export const useCancelOverride = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (spaceId: string) => camsService.cancelOverride(spaceId),
    onSuccess: (_, spaceId) => {
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.cams.spaceState(spaceId),
      });
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.cams.queue(spaceId),
      });
    },
    onError: (error) => {
      handleApiError(error, {}, 'Failed to cancel manual override.');
    },
  });
};
