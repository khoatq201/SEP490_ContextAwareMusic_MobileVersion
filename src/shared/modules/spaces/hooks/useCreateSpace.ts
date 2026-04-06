import { useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';

/**
 * Services
 */
import { spaceService } from '@/shared/modules/spaces/services';

/**
 * Types
 */
import type { CreateSpaceRequest } from '@/shared/modules/spaces/types';

/**
 * Utils
 */
import { showErrorMessage } from '@/shared/utils';

/**
 * Hook to create new space
 * StoreManager: storeId is auto-filled from session
 */
export const useCreateSpace = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateSpaceRequest) => spaceService.create(data),
    onSuccess: (response) => {
      queryClient.invalidateQueries({ queryKey: ['spaces'] });
      message.success(response.data.message || 'Space created successfully');
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    onError: (error: any) => {
      showErrorMessage(error, 'Failed to create space');
    },
  });
};
