import { useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';
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
    }: {
      spaceId: string;
      playlistId?: string;
      moodId?: string;
    }) => {
      const data: OverridePlaylistRequest = {
        playlistId: playlistId || null,
        moodId: moodId || null,
      };
      return camsService.overridePlaylist(spaceId, data);
    },
    onSuccess: (_, variables) => {
      message.success('Playlist overridden successfully');
      // Invalidate space state to refetch
      queryClient.invalidateQueries({
        queryKey: ['cams-space-state', variables.spaceId],
      });
    },
    onError: (error: any) => {
      handleApiError(
        error,
        {},
        'Failed to override playlist. Please try again.',
      );
    },
  });
};
