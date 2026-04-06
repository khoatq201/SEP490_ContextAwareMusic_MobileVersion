import { useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';

/**
 * Services
 */
import { staffService } from '@/features/brand/services';

/**
 * Utils
 */
import { showErrorMessage } from '@/shared/utils';

export const useUpdateStaff = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, formData }: { id: string; formData: FormData }) =>
      staffService.update(id, formData),
    onSuccess: (response, variables) => {
      message.success(response.data.message || 'Staff updated successfully!');
      queryClient.invalidateQueries({
        queryKey: ['staff-detail', variables.id],
      });
      queryClient.invalidateQueries({ queryKey: ['staff'] });
    },
    onError: (error: any) => {
      showErrorMessage(error, 'Failed to update staff!');
    },
  });
};
