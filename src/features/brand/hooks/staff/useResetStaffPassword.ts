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

/**
 * Types
 */
import type { ResetStaffPasswordRequest } from '@/features/brand/types';

export const useResetStaffPassword = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      id,
      data,
    }: {
      id: string;
      data: ResetStaffPasswordRequest;
    }) => staffService.resetPassword(id, data),
    onSuccess: (response, variables) => {
      message.success(response.data.message || 'Password reset successfully!');
      queryClient.invalidateQueries({
        queryKey: ['staff-detail', variables.id],
      });
    },
    onError: (error: any) => {
      showErrorMessage(error, 'Failed to reset password!');
    },
  });
};
