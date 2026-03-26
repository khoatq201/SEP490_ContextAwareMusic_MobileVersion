import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';
import { QUERY_KEYS } from '@/config';
import { handleApiError } from '@/shared/utils';
import { camsService } from '../services';
import type {
  AddTracksToQueueRequest,
  AddPlaylistToQueueRequest,
  ReorderQueueRequest,
} from '../types';

/**
 * Hook: Get space queue
 * ⚠️ NEW (2026-03-23): Queue management
 *
 * GET /api/cams/spaces/{spaceId}/queue
 * Auth: Any authenticated user
 */
export const useSpaceQueue = (spaceId: string, enabled = true) => {
  return useQuery({
    queryKey: [...QUERY_KEYS.cams.queue(spaceId)],
    queryFn: () => camsService.getQueue(spaceId),
    enabled: !!spaceId && enabled,
    select: (response) => response.data.data, // Unwrap AxiosResponse.data.data
  });
};

/**
 * Hook: Add tracks to space queue
 * ⚠️ NEW (2026-03-23): Queue management
 *
 * POST /api/cams/spaces/{spaceId}/queue/tracks
 * Auth: BrandManager, StoreManager
 */
export const useAddTracksToQueue = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      spaceId,
      data,
    }: {
      spaceId: string;
      data: AddTracksToQueueRequest;
    }) => camsService.addTracksToQueue(spaceId, data),
    onSuccess: (_, { spaceId }) => {
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.cams.queue(spaceId),
      });
      message.success('Tracks added to queue');
    },
    onError: (error) => {
      handleApiError(error);
    },
  });
};

/**
 * Hook: Add playlist to space queue
 * ⚠️ NEW (2026-03-23): Queue management
 *
 * POST /api/cams/spaces/{spaceId}/queue/playlist
 * Auth: BrandManager, StoreManager
 */
export const useAddPlaylistToQueue = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      spaceId,
      data,
    }: {
      spaceId: string;
      data: AddPlaylistToQueueRequest;
    }) => camsService.addPlaylistToQueue(spaceId, data),
    onSuccess: (_, { spaceId }) => {
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.cams.queue(spaceId),
      });
      message.success('Playlist added to queue');
    },
    onError: (error) => {
      handleApiError(error);
    },
  });
};

/**
 * Hook: Reorder queue items
 * ⚠️ NEW (2026-03-23): Queue management
 *
 * PATCH /api/cams/spaces/{spaceId}/queue/reorder
 * Auth: BrandManager, StoreManager
 */
export const useReorderQueue = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      spaceId,
      data,
    }: {
      spaceId: string;
      data: ReorderQueueRequest;
    }) => camsService.reorderQueue(spaceId, data),
    onSuccess: (_, { spaceId }) => {
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.cams.queue(spaceId),
      });
      message.success('Queue reordered');
    },
    onError: (error) => {
      handleApiError(error);
    },
  });
};

/**
 * Hook: Clear all queue items
 * ⚠️ NEW (2026-03-23): Queue management
 *
 * DELETE /api/cams/spaces/{spaceId}/queue/all
 * Auth: BrandManager, StoreManager
 */
export const useClearQueue = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (spaceId: string) => camsService.clearQueue(spaceId),
    onSuccess: (_, spaceId) => {
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.cams.queue(spaceId),
      });
      message.success('Queue cleared');
    },
    onError: (error) => {
      handleApiError(error);
    },
  });
};

/**
 * Hook: Remove single queue item
 * ⚠️ NEW (2026-03-23): Queue management
 *
 * DELETE /api/cams/spaces/{spaceId}/queue/{queueItemId}
 * Auth: BrandManager, StoreManager
 */
export const useRemoveQueueItem = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      spaceId,
      queueItemId,
    }: {
      spaceId: string;
      queueItemId: string;
    }) => camsService.removeQueueItem(spaceId, queueItemId),
    onSuccess: (_, { spaceId }) => {
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.cams.queue(spaceId),
      });
      message.success('Queue item removed');
    },
    onError: (error) => {
      handleApiError(error);
    },
  });
};
