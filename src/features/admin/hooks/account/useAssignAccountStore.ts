import { useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';

/**
 * Utils
 */
import { showErrorMessage } from '@/shared/utils';

/**
 * Services
 */
import { accountService } from '@/features/admin/services';

/**
 * Types
 */
import type { AssignStoreRequest } from '@/features/admin/types';

export const useAssignAccountStore = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: AssignStoreRequest }) =>
      accountService.assignStore(id, data),
    onSuccess: (response, variables) => {
      message.success(
        response.data.message || 'Store assignment updated successfully!',
      );
      queryClient.invalidateQueries({ queryKey: ['account', variables.id] });
      queryClient.invalidateQueries({ queryKey: ['accounts'] });
    },
    onError: (error: any) => {
      showErrorMessage(error, 'Failed to update store assignment!');
    },
  });
};
