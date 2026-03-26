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

export const useToggleBrandStatus = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => brandService.toggleStatus(id),
    onSuccess: () => {
      message.success('Brand status updated successfully');
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.brands.all });
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    onError: (error: any) => {
      handleApiError(error, {}, 'Failed to toggle brand status');
    },
  });
};
