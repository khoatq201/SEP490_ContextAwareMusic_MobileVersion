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

export const useUpdateAccount = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, formData }: { id: string; formData: FormData }) =>
      accountService.update(id, formData),
    onSuccess: (response, variables) => {
      message.success(response.data.message || 'Account updated successfully!');
      queryClient.invalidateQueries({ queryKey: ['account', variables.id] });
      queryClient.invalidateQueries({ queryKey: ['accounts'] });
    },
    onError: (error: any) => {
      showErrorMessage(error, 'Failed to update account!');
    },
  });
};
