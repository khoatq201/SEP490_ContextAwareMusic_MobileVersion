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

export const useRemoveTrackFromPlaylist = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, trackId }: { id: string; trackId: string }) =>
      playlistService.removeTrack(id, trackId),
    onSuccess: (response) => {
      if (response.data.isSuccess) {
        queryClient.invalidateQueries({ queryKey: ['playlists'] });
        message.success(response.data.message || 'Track removed successfully!');
      }
    },
    onError: (error: any) => {
      handleApiError(
        error,
        {
          [ErrorCodeEnum.BusinessRuleViolation]: () => {
            message.error('Cannot modify playlist while actively streaming.');
          },
        },
        'Failed to remove track from playlist.',
      );
    },
  });
};
