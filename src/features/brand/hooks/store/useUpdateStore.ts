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

/**
 * Types
 */
import type { StoreRequest } from '@/features/brand/types';

export const useUpdateStore = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: StoreRequest }) =>
      storeService.update(id, data),
    onSuccess: (response, variables) => {
      message.success(response.data.message || 'Store updated successfully!');
      queryClient.invalidateQueries({ queryKey: ['store', variables.id] });
      queryClient.invalidateQueries({ queryKey: ['stores'] });
    },
    onError: (error: any) => {
      showErrorMessage(error, 'Failed to update store!');
    },
  });
};
