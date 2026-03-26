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

export const useDeleteBrand = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => brandService.delete(id),
    onSuccess: (response) => {
      message.success(response.data.message || 'Brand deleted successfully!');
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.brands.all });
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    onError: (error: any) => {
      handleApiError(error, {}, 'Failed to delete brand');
    },
  });
};
