import { useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';

/**
 * Services
 */
import { storeService } from '@/features/brand/services';

/**
 * Utils
 */
import { showErrorMessage } from '@/shared/utils';

export const useToggleStoreStatus = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => storeService.toggleStatus(id),
    onSuccess: (response) => {
      message.success(
        response.data.message || 'Store status updated successfully!',
      );
      queryClient.invalidateQueries({ queryKey: ['stores'] });
    },
    onError: (error: any) => {
      showErrorMessage(error, 'Failed to toggle store status!');
    },
  });
};
