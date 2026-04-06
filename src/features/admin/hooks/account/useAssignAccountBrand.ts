import { useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';

/**
 * Utils
 */
import { handleApiError } from '@/shared/utils';

/**
 * Services
 */
import { accountService } from '@/features/admin/services';

/**
 * Types
 */
import type { AssignBrandRequest } from '@/features/admin/types';

/**
 * Config
 */
import { QUERY_KEYS } from '@/config';

export const useAssignAccountBrand = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      id,
      data,
    }: {
      id: string;
      data: AssignBrandRequest;
      skipDefaultError?: boolean;
    }) => accountService.assignBrand(id, data),
    onSuccess: (response, variables) => {
      message.success(response.data.message || 'Brand assigned successfully!');
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.accounts.detail(variables.id),
      });
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.accounts.all });
    },
    onError: (error, variables) => {
      // Skip default error handling if skipDefaultError is set in variables
      if (variables?.skipDefaultError) {
        return;
      }
      handleApiError(error, {}, 'Failed to assign brand');
    },
  });
};
