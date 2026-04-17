import { useState, useEffect, useRef } from 'react';
import { storeHubService } from '../services';
import type {
  PlayStreamPayload,
  PlaybackStateChangedPayload,
  SpaceStateDto,
} from '../types';

type EventHandlers = {
  onPlayStream?: (payload: PlayStreamPayload) => void;
  onPlaybackStateChanged?: (payload: PlaybackStateChangedPayload) => void;
  onSpaceStateSync?: (spaceId: string, state: SpaceStateDto) => void;
  onConnected?: () => void;
  onDisconnected?: () => void;
  onReconnected?: () => void;
};

/**
 * Hook to connect to StoreHub and listen for real-time events
 * Used by both SpaceList (manager) and Tablet
 *
 * ⚠️ Handles React Strict Mode double-invoke
 */
export const useStoreHub = (
  storeId: string | null,
  token: string | null,
  handlers: EventHandlers = {},
) => {
  // ✅ Initialize state outside effect to avoid setState warning
  const [isConnected, setIsConnected] = useState(false);
  const [isConnecting, setIsConnecting] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  // ✅ Use ref to track connection state across renders
  const connectionRef = useRef<{
    isConnecting: boolean;
    shouldConnect: boolean;
  }>({
    isConnecting: false,
    shouldConnect: false,
  });

  // ✅ Memoize handlers to avoid re-creating effect
  const handlersRef = useRef(handlers);
  useEffect(() => {
    handlersRef.current = handlers;
  }, [handlers]);

  useEffect(() => {
    const connectionState = connectionRef.current;

    // ✅ Early return without setState
    if (!storeId || !token) {
      console.log('❌ Cannot connect to StoreHub: Missing storeId or token', {
        hasStoreId: !!storeId,
        hasToken: !!token,
      });
      return;
    }

    // ✅ Mark that we should connect
    connectionState.shouldConnect = true;

    const connect = async () => {
      // ✅ Prevent double-connect in Strict Mode
      if (connectionState.isConnecting) {
        console.log('⏭️ Connection already in progress, skipping...');
        return;
      }

      // ✅ Check if we should still connect (not unmounted)
      if (!connectionState.shouldConnect) {
        console.log('⏭️ Component unmounted before connect, aborting...');
        return;
      }

      try {
        connectionState.isConnecting = true;
        setIsConnecting(true);
        setError(null);

        console.log('🔌 Attempting to connect to StoreHub...', {
          storeId,
          hasToken: !!token,
        });

        await storeHubService.connect(storeId, token, {
          onPlayStream: (payload) => {
            console.log('🎵 PlayStream event received:', payload);
            handlersRef.current.onPlayStream?.(payload);
          },
          onPlaybackStateChanged: (payload) => {
            console.log('⏯️ PlaybackStateChanged event received:', payload);
            handlersRef.current.onPlaybackStateChanged?.(payload);
          },
          onSpaceStateSync: (spaceId, state) => {
            console.log('🔄 SpaceStateSync event received:', spaceId, state);
            handlersRef.current.onSpaceStateSync?.(spaceId, state);
          },
          onConnected: () => {
            // ✅ Only update state if still mounted
            if (connectionState.shouldConnect) {
              console.log('✅ StoreHub connected successfully');
              setIsConnected(true);
              setIsConnecting(false);
              handlersRef.current.onConnected?.();
            }
          },
          onDisconnected: () => {
            console.log('❌ StoreHub disconnected');
            setIsConnected(false);
            setIsConnecting(false);
            connectionState.isConnecting = false;
            handlersRef.current.onDisconnected?.();
          },
          onReconnecting: () => {
            console.log('🔄 StoreHub reconnecting...');
            setIsConnecting(true);
          },
          onReconnected: () => {
            console.log('✅ StoreHub reconnected');
            setIsConnected(true);
            setIsConnecting(false);
            handlersRef.current.onReconnected?.();
          },
        });

        connectionState.isConnecting = false;
      } catch (err) {
        console.error('❌ Failed to connect to StoreHub:', err);

        // ✅ Only update state if still mounted
        if (connectionRef.current.shouldConnect) {
          setError(err instanceof Error ? err : new Error('Connection failed'));
          setIsConnected(false);
          setIsConnecting(false);
        }

        connectionRef.current.isConnecting = false;
      }
    };

    // ✅ Small delay to avoid double-connect in Strict Mode
    const timer = setTimeout(() => {
      if (connectionState.shouldConnect) {
        connect();
      }
    }, 100);

    return () => {
      const shouldCleanup = connectionState.shouldConnect;

      // ✅ Mark that we should NOT connect anymore
      connectionState.shouldConnect = false;
      connectionState.isConnecting = false;

      clearTimeout(timer);

      console.log('👋 Disconnecting from StoreHub...');

      // ✅ Only disconnect if we were actually trying to connect
      if (shouldCleanup && storeHubService.isConnected()) {
        storeHubService.disconnect();
      }

      setIsConnected(false);
    };
  }, [storeId, token]);

  return {
    isConnected,
    isConnecting,
    error,
  };
};
