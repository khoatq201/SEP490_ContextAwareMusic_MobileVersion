import { useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';

/**
 * Utils
 */
import { handleApiError } from '@/shared/utils';

/**
 * Services
 */
import { storeService } from '@/features/brand/services';

export const useDeleteStore = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => storeService.delete(id),
    onSuccess: (response) => {
      queryClient.invalidateQueries({ queryKey: ['stores'] });
      message.success(response.data.message || 'Store deleted successfully');
    },

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    onError: (error: any) => {
      handleApiError(error || 'Failed to delete store');
    },
  });
};
