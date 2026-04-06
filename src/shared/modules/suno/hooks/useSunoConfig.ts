import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';
import { STALE_TIME } from '@/config';
import { getSunoConfig, updateSunoConfig } from '../services';
import type { SunoConfigUpdateRequest } from '../types';

/**
 * Query key factory for Suno config
 */
export const sunoConfigKeys = {
  all: ['suno', 'config'] as const,
  detail: () => [...sunoConfigKeys.all] as const,
};

/**
 * Hook to fetch Suno configuration
 */
export const useSunoConfig = () => {
  return useQuery({
    queryKey: sunoConfigKeys.detail(),
    queryFn: async () => {
      const response = await getSunoConfig();
      if (!response.isSuccess || !response.data) {
        throw new Error(response.message || 'Failed to load Suno config');
      }
      return response.data;
    },
    staleTime: STALE_TIME.long,
  });
};

/**
 * Hook to update Suno configuration
 */
export const useUpdateSunoConfig = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (data: SunoConfigUpdateRequest) => {
      const response = await updateSunoConfig(data);
      if (!response.isSuccess) {
        throw new Error(response.message || 'Failed to update Suno config');
      }
      return response.data;
    },
    onSuccess: (data) => {
      queryClient.setQueryData(sunoConfigKeys.detail(), data);
      message.success('Suno configuration updated successfully');
    },
    onError: (error: Error) => {
      message.error(error.message || 'Failed to update Suno configuration');
    },
  });
};
