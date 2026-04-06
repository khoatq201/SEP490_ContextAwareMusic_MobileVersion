import { useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';

/**
 * Utils
 */
import { showErrorMessage } from '@/shared/utils';

/**
 * Services
 */
import { playlistService } from '@/shared/modules/playlists/services';

/**
 * Types
 */
import type { CreatePlaylistRequest } from '@/shared/modules/playlists/types';

export const useCreatePlaylist = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreatePlaylistRequest) => playlistService.create(data),
    onSuccess: (response) => {
      if (response.data.isSuccess) {
        queryClient.invalidateQueries({ queryKey: ['playlists'] });
        message.success(
          response.data.message || 'Playlist created successfully!',
        );
      }
    },
    onError: (error: any) => {
      showErrorMessage(error, 'Failed to create playlist.');
    },
  });
};
