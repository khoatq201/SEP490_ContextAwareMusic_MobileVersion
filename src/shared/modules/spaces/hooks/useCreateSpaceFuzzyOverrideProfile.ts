import { useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';

import { spaceService } from '@/shared/modules/spaces/services';
import type { SpaceFuzzyOverrideProfileRequest } from '@/shared/modules/spaces/types';
import { showErrorMessage } from '@/shared/utils';

export const useCreateSpaceFuzzyOverrideProfile = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      spaceId,
      body,
    }: {
      spaceId: string;
      body: SpaceFuzzyOverrideProfileRequest;
    }) => spaceService.createFuzzyOverrideProfile(spaceId, body),
    onSuccess: (response, variables) => {
      queryClient.invalidateQueries({ queryKey: ['spaces'] });
      queryClient.invalidateQueries({ queryKey: ['space', variables.spaceId] });
      message.success(
        response.data.message || 'Space fuzzy override profile created.',
      );
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    onError: (error: any) => {
      showErrorMessage(error, 'Failed to create space fuzzy profile.');
    },
  });
};
