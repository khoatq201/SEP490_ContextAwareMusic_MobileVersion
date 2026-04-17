import { useMutation, useQueryClient } from '@tanstack/react-query';

/**
 * Utils
 */
import { handleApiError } from '@/shared/utils';

/**
 * Services
 */
import { camsService } from '@/shared/modules/cams/services';

/**
 * Types
 */
import type {
  PlaybackCommand,
  PlaybackControlRequest,
} from '@/shared/modules/cams/types';

/**
 * Control playback for a space
 * Commands: Pause, Resume, SkipToNext, SkipToPrevious
 */
export const usePlaybackControl = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      spaceId,
      command,
      targetQueueItemId,
      seekPositionSeconds,
    }: {
      spaceId: string;
      command: PlaybackCommand;
      targetQueueItemId?: string | null;
      seekPositionSeconds?: number | null;
    }) => {
      const data: PlaybackControlRequest = {
        command,
      } as PlaybackControlRequest;
      if (targetQueueItemId) data.targetQueueItemId = targetQueueItemId;
      if (typeof seekPositionSeconds === 'number')
        data.seekPositionSeconds = seekPositionSeconds;
      return camsService.controlPlayback(spaceId, data);
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ['cams-space-state', variables.spaceId],
      });
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    onError: (error: any) => {
      handleApiError(
        error,
        {},
        'Failed to control playback. Please try again.',
      );
    },
  });
};
