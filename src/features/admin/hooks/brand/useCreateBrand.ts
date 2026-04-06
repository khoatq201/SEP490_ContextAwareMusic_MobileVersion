import { useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';

/**
 * Services
 */
import { brandService } from '@/features/admin/services';

/**
 * Config
 */
import { QUERY_KEYS } from '@/config';

export const useCreateBrand = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (formData: FormData) => brandService.create(formData),
    onSuccess: (response) => {
      message.success(response.data.message || 'Brand created successfully!');
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.brands.all });
    },
  });
};
