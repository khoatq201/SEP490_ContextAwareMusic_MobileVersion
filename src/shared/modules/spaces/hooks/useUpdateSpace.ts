import { useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';

/**
 * Services
 */
import { spaceService } from '@/shared/modules/spaces/services';

/**
 * Types
 */
import type { UpdateSpaceRequest } from '@/shared/modules/spaces/types';

/**
 * Utils
 */
import { showErrorMessage } from '@/shared/utils';

export const useUpdateSpace = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: UpdateSpaceRequest }) =>
      spaceService.update(id, data),
    onSuccess: (response, { id }) => {
      queryClient.invalidateQueries({ queryKey: ['spaces'] });
      queryClient.invalidateQueries({ queryKey: ['space', id] });
      message.success(response.data.message || 'Space updated successfully');
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    onError: (error: any) => {
      showErrorMessage(error, 'Failed to update space');
    },
  });
};
