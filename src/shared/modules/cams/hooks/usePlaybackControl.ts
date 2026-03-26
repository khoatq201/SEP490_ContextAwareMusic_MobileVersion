import { useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';

/**
 * Utils
 */
import { handleApiError } from '@/shared/utils';

/**
 * Services
 */
import { camsService } from '@/shared/modules/cams/services';

/**
 * Constants
 */
import { PLAYBACK_COMMAND_LABELS } from '@/shared/modules/cams/constants';

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
    }: {
      spaceId: string;
      command: PlaybackCommand;
    }) => {
      const data: PlaybackControlRequest = { command };
      return camsService.controlPlayback(spaceId, data);
    },
    onSuccess: (_, variables) => {
      // Only show success message for Skip commands, not Pause/Resume
      if (
        variables.command !== 1 && // Pause
        variables.command !== 2 // Resume
      ) {
        const commandLabel = PLAYBACK_COMMAND_LABELS[variables.command];
        message.success(`${commandLabel} command sent`);
      }
      // Invalidate space state
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
