import { useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';
import { QUERY_KEYS } from '@/config';
import { handleApiError } from '@/shared/utils';
import { trackService } from '../services';

/**
 * Hook: Retranscode track to HLS
 * ⚠️ NEW (2026-03-23): Track-level retranscode (replaces playlist-level)
 *
 * POST /api/tracks/{id}/retranscode
 * Auth: BrandManager, StoreManager
 *
 * @returns useMutation hook
 *
 * @example
 * const retranscode = useRetranscodeTrack();
 * retranscode.mutate(trackId, {
 *   onSuccess: () => console.log('Retranscode queued'),
 * });
 */
export const useRetranscodeTrack = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => trackService.retranscode(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.tracks.all });
      message.success('Track retranscode queued successfully');
    },
    onError: (error) => {
      handleApiError(error);
    },
  });
};
