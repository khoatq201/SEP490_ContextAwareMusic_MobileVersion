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

export const useCreateAccount = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (formData: FormData) => accountService.create(formData),
    onSuccess: (response) => {
      message.success(response.data.message || 'Account created successfully!');
      queryClient.invalidateQueries({ queryKey: ['accounts'] });
    },
    onError: (error: any) => {
      showErrorMessage(error, 'Failed to create account!');
    },
  });
};
