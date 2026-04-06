import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';
import { STALE_TIME } from '@/config';
import { getErrorMessage } from '@/shared/utils/errorHandler';
import {
  createSunoGeneration,
  getSunoGenerationStatus,
  getSunoGenerationHistory,
  cancelSunoGeneration,
} from '../services';
import type {
  SunoGenerationCreateRequest,
  SunoGenerationStatusDto,
} from '../types';
import type { PaginationResult } from '@/shared/types';

/**
 * Query key factory for Suno generations
 */
export const sunoGenerationKeys = {
  all: ['suno', 'generations'] as const,
  detail: (id: string) => [...sunoGenerationKeys.all, id] as const,
};

/**
 * Hook to fetch generation status by ID
 * Used for polling fallback when SignalR disconnects
 */
export const useSunoGenerationStatus = (
  id: string | undefined,
  options?: {
    enabled?: boolean;
    refetchInterval?: number | false;
  },
) => {
  return useQuery({
    queryKey: id
      ? sunoGenerationKeys.detail(id)
      : ['suno', 'generations', 'none'],
    queryFn: async () => {
      if (!id) throw new Error('Generation ID is required');
      const response = await getSunoGenerationStatus(id);
      if (!response.isSuccess || !response.data) {
        throw new Error(response.message || 'Failed to load generation status');
      }
      return response.data;
    },
    enabled: !!id && (options?.enabled ?? true),
    staleTime: STALE_TIME.short,
    refetchInterval: options?.refetchInterval ?? false,
  });
};

/**
 * Hook to fetch generation history (prompt history) by brand
 * Used by History tab on page reload.
 */
export const useSunoGenerationHistory = (
  page: number = 1,
  pageSize: number = 20,
) => {
  return useQuery({
    queryKey: ['suno', 'generations', 'history', page, pageSize],
    queryFn: async () => {
      // Service returns PaginationResult directly (no Result wrapper)
      return (await getSunoGenerationHistory(
        page,
        pageSize,
      )) as PaginationResult<SunoGenerationStatusDto>;
    },
    staleTime: STALE_TIME.medium,
  });
};

/**
 * Hook to create new Suno generation
 */
export const useCreateSunoGeneration = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (data: SunoGenerationCreateRequest) => {
      const response = await createSunoGeneration(data);
      if (!response.isSuccess || !response.data) {
        throw new Error(response.message || 'Failed to create generation');
      }
      return response.data;
    },
    onSuccess: (data) => {
      // Cache the new generation
      queryClient.setQueryData(sunoGenerationKeys.detail(data.id), data);
      // Refresh history lists (prompt history + history tab) so new generation appears instantly
      queryClient.invalidateQueries({
        queryKey: ['suno', 'generations', 'history'],
      });
      message.success('Music generation started! This may take 1-2 minutes.');
    },
    onError: (error: unknown) => {
      // Prefer backend message (including ValidationFailed errors)
      message.error(getErrorMessage(error, 'Failed to start music generation'));
    },
  });
};

/**
 * Hook to cancel ongoing generation
 */
export const useCancelSunoGeneration = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const response = await cancelSunoGeneration(id);
      if (!response.isSuccess) {
        throw new Error(response.message || 'Failed to cancel generation');
      }
      return id;
    },
    onSuccess: (id) => {
      // Invalidate the generation query to refetch updated status
      queryClient.invalidateQueries({
        queryKey: sunoGenerationKeys.detail(id),
      });
      message.success('Generation cancelled');
    },
    onError: (error: unknown) => {
      message.error(getErrorMessage(error, 'Failed to cancel generation'));
    },
  });
};

/**
 * Hook to update generation status from SignalR
 * Call this when receiving SunoGenerationStatusChanged event
 */
export const useUpdateGenerationFromSignalR = () => {
  const queryClient = useQueryClient();

  return (generation: SunoGenerationStatusDto) => {
    queryClient.setQueryData(
      sunoGenerationKeys.detail(generation.id),
      generation,
    );
  };
};
