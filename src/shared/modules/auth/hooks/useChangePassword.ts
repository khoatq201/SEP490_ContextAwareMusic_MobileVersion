import { useMutation } from '@tanstack/react-query';
import { message } from 'antd';

/**
 * Services
 */
import { authService } from '../services';

/**
 * Utils
 */
import { showErrorMessage } from '@/shared/utils';

/**
 * Types
 */
import type { ChangePasswordRequest } from '../types';

/**
 * Hook to change current user's password
 * Used in profile page for self-service password change
 */
export const useChangePassword = () => {
  return useMutation({
    mutationFn: (data: ChangePasswordRequest) =>
      authService.changePassword(data),
    onSuccess: (response) => {
      message.success(
        response.data.message || 'Password changed successfully!',
      );
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    onError: (error: any) => {
      showErrorMessage(error, 'Failed to change password');
    },
  });
};
