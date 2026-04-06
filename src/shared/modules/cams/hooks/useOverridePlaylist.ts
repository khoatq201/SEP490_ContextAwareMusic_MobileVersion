import { useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';
import { QUERY_KEYS } from '@/config';
import { handleApiError } from '@/shared/utils';
import { camsService } from '../services';
import type { OverridePlaylistRequest } from '../types';

/**
 * Override playlist for a space
 * Triggers backend to generate new HLS stream and broadcast via SignalR
 *
 * Mode 1: Override with specific playlist
 * Mode 2: Override with mood (backend picks playlist)
 */
export const useOverridePlaylist = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      spaceId,
      playlistId,
      moodId,
      trackIds,
      isClearManagerSelectedQueues,
      isCutOver,
      reason,
    }: {
      spaceId: string;
      playlistId?: string;
      moodId?: string;
      trackIds?: string[];
      isClearManagerSelectedQueues?: boolean;
      isCutOver?: boolean;
      reason?: string;
    }) => {
      const data: OverridePlaylistRequest = {
        playlistId: playlistId || null,
        moodId: moodId || null,
        trackIds: trackIds?.length ? trackIds : null,
        isClearManagerSelectedQueues,
        isCutOver: isCutOver ?? null,
        reason: reason || null,
      };
      return camsService.overridePlaylist(spaceId, data);
    },
    onSuccess: (_, variables) => {
      message.success('Manual override applied successfully');
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.cams.spaceState(variables.spaceId),
      });
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.cams.queue(variables.spaceId),
      });
    },
    onError: (error: unknown) => {
      handleApiError(
        error,
        {},
        'Failed to apply manual override. Please try again.',
      );
    },
  });
};
