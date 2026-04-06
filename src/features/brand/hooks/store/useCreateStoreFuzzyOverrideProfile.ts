import { useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';

import { storeService } from '@/features/brand/services';
import { showErrorMessage } from '@/shared/utils';
import type { StoreFuzzyOverrideProfileRequest } from '@/features/brand/types';

export const useCreateStoreFuzzyOverrideProfile = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      storeId,
      body,
    }: {
      storeId: string;
      body: StoreFuzzyOverrideProfileRequest;
    }) => storeService.createFuzzyOverrideProfile(storeId, body),
    onSuccess: (response) => {
      message.success(
        response.data.message || 'Store fuzzy override profile created.',
      );
      queryClient.invalidateQueries({ queryKey: ['stores'] });
    },
    onError: (error: unknown) => {
      showErrorMessage(error, 'Failed to create store fuzzy profile.');
    },
  });
};
