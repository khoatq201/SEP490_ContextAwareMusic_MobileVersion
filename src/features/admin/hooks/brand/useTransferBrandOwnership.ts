import { useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';

/**
 * Services
 */
import { brandService } from '@/features/admin/services';

/**
 * Utils
 */
import { handleApiError } from '@/shared/utils';

/**
 * Config
 */
import { QUERY_KEYS } from '@/config';

export const useTransferBrandOwnership = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      id,
      newOwnerId,
    }: {
      id: string;
      newOwnerId: string;
      skipDefaultError?: boolean;
    }) => brandService.transferOwnership(id, { newOwnerId }),
    onSuccess: (response, variables) => {
      message.success(
        response.data.message || 'Brand ownership transferred successfully!',
      );

      // Invalidate brand detail and list
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.brands.all });
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.brands.detail(variables.id),
      });
    },
    onError: (error, variables) => {
      // Skip default error handling if skipDefaultError is set in variables
      if (variables?.skipDefaultError) {
        return;
      }
      handleApiError(error, {}, 'Failed to transfer brand ownership');
    },
  });
};
