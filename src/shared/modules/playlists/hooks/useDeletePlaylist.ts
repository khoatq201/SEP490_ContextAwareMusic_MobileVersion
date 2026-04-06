import { useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';

/**
 * Utils
 */
import { handleApiError } from '@/shared/utils';

/**
 * Types
 */
import { ErrorCodeEnum } from '@/shared/types';

/**
 * Services
 */
import { playlistService } from '@/shared/modules/playlists/services';

export const useDeletePlaylist = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => playlistService.delete(id),
    onSuccess: (response) => {
      if (response.data.isSuccess) {
        queryClient.invalidateQueries({ queryKey: ['playlists'] });
        message.success(
          response.data.message || 'Playlist deleted successfully!',
        );
      }
    },
    onError: (error: any) => {
      handleApiError(
        error,
        {
          [ErrorCodeEnum.BusinessRuleViolation]: () => {
            message.error(
              'Cannot delete playlist. It is currently being streamed.',
            );
          },
        },
        'Failed to delete playlist.',
      );
    },
  });
};
