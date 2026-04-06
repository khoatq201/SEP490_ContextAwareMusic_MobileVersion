import { useEffect, useRef, useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { message } from 'antd';
import { TrackMetadataStatus } from '../types';
import { getTrackMetadataStatus } from '../utils';
import { useTrack } from './useTrack';

interface UseTrackMetadataPollingOptions {
  enabled?: boolean; // Enable/disable polling
  maxAttempts?: number; // Max polling attempts (default: 12 = 2 minutes at 10s interval)
  intervalMs?: number; // Polling interval in milliseconds (default: 10000 = 10s)
  onComplete?: (status: TrackMetadataStatus) => void; // Callback when polling completes
  onTimeout?: () => void; // Callback when polling times out
}

/**
 * Hook to poll track metadata status after upload
 * Automatically stops when metadata is ready or timeout is reached
 *
 * @param trackId - Track ID to poll
 * @param options - Polling options
 * @returns Polling state
 *
 * @example
 * ```tsx
 * const { isPolling, attempts, status } = useTrackMetadataPolling(trackId, {
 *   enabled: true,
 *   onComplete: (status) => {
 *     if (status === TrackMetadataStatus.Ready) {
 *       message.success('Metadata extraction completed!');
 *     }
 *   },
 * });
 * ```
 */
export const useTrackMetadataPolling = (
  trackId: string | undefined,
  options: UseTrackMetadataPollingOptions = {},
) => {
  const {
    enabled = true,
    maxAttempts = 12, // 2 minutes at 10s interval
    intervalMs = 10000, // 10 seconds
    onComplete,
    onTimeout,
  } = options;

  const queryClient = useQueryClient();
  const [isPolling, setIsPolling] = useState(false);
  const [attempts, setAttempts] = useState(0);
  const [currentStatus, setCurrentStatus] =
    useState<TrackMetadataStatus | null>(null);

  const intervalRef = useRef<number | null>(null);
  const attemptsRef = useRef(0);

  // Fetch track data (disabled by default, only enabled during polling)
  const { data: track, refetch } = useTrack(trackId, false);

  // Start polling
  const startPolling = () => {
    if (!trackId || !enabled) return;

    setIsPolling(true);
    setAttempts(0);
    attemptsRef.current = 0;

    // Initial fetch
    refetch();

    // Set up interval
    intervalRef.current = window.setInterval(async () => {
      attemptsRef.current += 1;
      setAttempts(attemptsRef.current);

      // Refetch track data
      const result = await refetch();

      if (result.data) {
        const status = getTrackMetadataStatus(result.data);
        setCurrentStatus(status);

        // Stop polling if metadata is ready or partial
        if (
          status === TrackMetadataStatus.Ready ||
          status === TrackMetadataStatus.Partial
        ) {
          stopPolling();
          onComplete?.(status);

          // Show success message
          if (status === TrackMetadataStatus.Ready) {
            message.success('Metadata extraction completed!');
          } else {
            message.info('Partial metadata extracted');
          }

          // Invalidate queries to refresh UI
          queryClient.invalidateQueries({
            queryKey: ['tracks'],
          });

          return;
        }
      }

      // Stop polling if max attempts reached
      if (attemptsRef.current >= maxAttempts) {
        stopPolling();
        setCurrentStatus(TrackMetadataStatus.Unknown);
        onTimeout?.();
        message.warning(
          'Metadata extraction is taking longer than expected. Please check back later.',
        );
      }
    }, intervalMs);
  };

  // Stop polling
  const stopPolling = () => {
    if (intervalRef.current) {
      window.clearInterval(intervalRef.current);
      intervalRef.current = null;
    }
    setIsPolling(false);
  };

  // Check initial status when track data is available
  useEffect(() => {
    if (track && enabled && !isPolling) {
      const status = getTrackMetadataStatus(track);
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setCurrentStatus(status);

      // Auto-start polling if status is Pending
      if (status === TrackMetadataStatus.Pending) {
        startPolling();
      }
    }
  }, [track, enabled]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      stopPolling();
    };
  }, []);

  return {
    isPolling,
    attempts,
    maxAttempts,
    status: currentStatus,
    startPolling,
    stopPolling,
  };
};
