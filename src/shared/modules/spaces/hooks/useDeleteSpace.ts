import { useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';

/**
 * Services
 */
import { spaceService } from '@/shared/modules/spaces/services';

/**
 * Utils
 */
import { showErrorMessage } from '@/shared/utils';

/**
 * Hook to delete space (soft-delete)
 */
export const useDeleteSpace = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => spaceService.delete(id),
    onSuccess: (response) => {
      queryClient.invalidateQueries({ queryKey: ['spaces'] });
      message.success(response.data.message || 'Space deleted successfully');
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    onError: (error: any) => {
      showErrorMessage(error, 'Failed to delete space');
    },
  });
};
