import { useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';

/**
 * Utils
 */
import { showErrorMessage } from '@/shared/utils';

/**
 * Services
 */
import { trackService } from '@/shared/modules/tracks/services';

/**
 * Types
 */
import type { UpdateTrackRequest } from '@/shared/modules/tracks/types';

export const useUpdateTrack = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: UpdateTrackRequest }) =>
      trackService.update(id, data),
    onSuccess: (response, variables) => {
      if (response.data.isSuccess) {
        queryClient.invalidateQueries({ queryKey: ['tracks'] });
        queryClient.invalidateQueries({ queryKey: ['tracks', variables.id] });
        message.success(response.data.message || 'Track updated successfully!');
      }
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    onError: (error: any) => {
      showErrorMessage(error, 'Failed to update track.');
    },
  });
};
