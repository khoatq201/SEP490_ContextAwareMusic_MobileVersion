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

export const useUpdateBrand = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, formData }: { id: string; formData: FormData }) =>
      brandService.update(id, formData),
    onSuccess: (response, variables) => {
      message.success(response.data.message || 'Brand updated successfully!');
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.brands.detail(variables.id),
      });
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.brands.all });
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    onError: (error: any) => {
      handleApiError(error, {}, 'Failed to update brand');
    },
  });
};
