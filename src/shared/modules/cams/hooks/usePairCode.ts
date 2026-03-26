import { useMutation, useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';
import { camsService } from '../services';
import { handleApiError } from '@/shared/utils';

/**
 * Hook to generate pair code for a space
 * POST /api/cams/spaces/{spaceId}/pair-code
 */
export const useGeneratePairCode = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (spaceId: string) => camsService.generatePairCode(spaceId),
    onSuccess: (response) => {
      if (response.data.isSuccess) {
        message.success('Pair code generated successfully');
        queryClient.invalidateQueries({ queryKey: ['pairDeviceInfo'] });
      } else {
        message.error(response.data.message || 'Failed to generate pair code');
      }
    },
    onError: (error) => {
      handleApiError(error, undefined, 'Failed to generate pair code');
    },
  });
};

/**
 * Hook to revoke pair code for a space
 * DELETE /api/cams/spaces/{spaceId}/pair-code
 */
export const useRevokePairCode = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (spaceId: string) => camsService.revokePairCode(spaceId),
    onSuccess: (response) => {
      if (response.data.isSuccess) {
        message.success('Pair code revoked successfully');
        queryClient.invalidateQueries({ queryKey: ['pairDeviceInfo'] });
      } else {
        message.error(response.data.message || 'Failed to revoke pair code');
      }
    },
    onError: (error) => {
      handleApiError(error, undefined, 'Failed to revoke pair code');
    },
  });
};

/**
 * Hook to unpair device from a space
 * DELETE /api/cams/spaces/{spaceId}/unpair
 */
export const useUnpairDevice = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (spaceId: string) => camsService.unpairDevice(spaceId),
    onSuccess: (response) => {
      if (response.data.isSuccess) {
        message.success('Device unpaired successfully');
        queryClient.invalidateQueries({ queryKey: ['pairDeviceInfo'] });
      } else {
        message.error(response.data.message || 'Failed to unpair device');
      }
    },
    onError: (error) => {
      handleApiError(error, undefined, 'Failed to unpair device');
    },
  });
};
