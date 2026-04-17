import { useMutation } from '@tanstack/react-query';
import { handleApiError } from '@/shared/utils';
import { camsService } from '../services';
import type { UpdateAudioStateRequest } from '../types';

/**
 * Hook: Update audio state (volume/mute/queueEndBehavior)
 * ⚠️ NEW (2026-03-23): Audio state control
 *
 * PATCH /api/cams/spaces/{spaceId}/state/audio
 * Auth: BrandManager, StoreManager
 *
 * @example
 * const updateAudio = useUpdateAudioState();
 * updateAudio.mutate({
 *   spaceId: 'space-id',
 *   data: { volumePercent: 75, isMuted: false },
 * });
 */
export const useUpdateAudioState = () => {
  return useMutation({
    mutationFn: ({
      spaceId,
      data,
    }: {
      spaceId: string;
      data: UpdateAudioStateRequest;
    }) => camsService.updateAudioState(spaceId, data),
    onSuccess: () => {},

    onError: (error) => {
      handleApiError(error);
    },
  });
};
