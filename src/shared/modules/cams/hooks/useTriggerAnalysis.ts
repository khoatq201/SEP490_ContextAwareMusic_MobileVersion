import { useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';

import { camsService } from '../services';
import type { TriggerAnalysisRequest } from '../types';
import { handleApiError } from '@/shared/utils';

export const useTriggerAnalysis = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      spaceId,
      body,
    }: {
      spaceId: string;
      body: TriggerAnalysisRequest;
    }) => camsService.triggerAnalysis(spaceId, body),
    onSuccess: (response, variables) => {
      message.success(
        response.data.message || 'AI analysis triggered successfully.',
      );
      queryClient.invalidateQueries({
        queryKey: ['cams-space-state', variables.spaceId],
      });
    },
    onError: (error: unknown) => {
      handleApiError(error, {}, 'Failed to trigger AI analysis.');
    },
  });
};
