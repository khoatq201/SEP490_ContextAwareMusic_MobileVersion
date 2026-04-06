import { useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';

/**
 * Services
 */
import { accountService } from '@/features/admin/services';

/**
 * Utils
 */
import { showErrorMessage } from '@/shared/utils';

export const useToggleAccountStatus = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => accountService.toggleStatus(id),
    onSuccess: (response) => {
      message.success(
        response.data.message || 'Account status updated successfully!',
      );
      queryClient.invalidateQueries({ queryKey: ['accounts'] });
    },
    onError: (error: any) => {
      showErrorMessage(error, 'Failed to toggle account status!');
    },
  });
};
