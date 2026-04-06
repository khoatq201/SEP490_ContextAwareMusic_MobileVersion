import { useState, useEffect, useRef } from 'react';
import {
  HubConnection,
  HubConnectionBuilder,
  LogLevel,
} from '@microsoft/signalr';
import { getAccessToken, getSignalRUrl } from '@/config';

interface UseSignalROptions {
  autoConnect?: boolean;
  onConnected?: () => void;
  onDisconnected?: () => void;
  onReconnecting?: () => void;
  onReconnected?: () => void;
}

/**
 * Generic SignalR hook for connecting to any hub
 * @param hubPath - Hub path (e.g., '/hubs/store')
 * @param options - Connection options
 */
export const useSignalR = (
  hubPath: string,
  options: UseSignalROptions = {},
) => {
  const {
    autoConnect = true,
    onConnected,
    onDisconnected,
    onReconnecting,
    onReconnected,
  } = options;

  const [connection, setConnection] = useState<HubConnection | null>(null);
  const [isConnected, setIsConnected] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const connectionRef = useRef<HubConnection | null>(null);

  useEffect(() => {
    if (!autoConnect) return;

    const connect = async () => {
      try {
        const token = getAccessToken();
        if (!token) {
          throw new Error('No access token available');
        }

        const hubUrl = `${getSignalRUrl()}${hubPath}`;

        const newConnection = new HubConnectionBuilder()
          .withUrl(hubUrl, {
            accessTokenFactory: () => token,
          })
          .withAutomaticReconnect()
          .configureLogging(LogLevel.Information)
          .build();

        // Register lifecycle events
        newConnection.onreconnecting(() => {
          console.log(`🔄 SignalR reconnecting to ${hubPath}...`);
          setIsConnected(false);
          onReconnecting?.();
        });

        newConnection.onreconnected(() => {
          console.log(`✅ SignalR reconnected to ${hubPath}`);
          setIsConnected(true);
          onReconnected?.();
        });

        newConnection.onclose(() => {
          console.log(`❌ SignalR connection closed for ${hubPath}`);
          setIsConnected(false);
          onDisconnected?.();
        });

        await newConnection.start();
        console.log(`✅ SignalR connected to ${hubPath}`);

        setConnection(newConnection);
        connectionRef.current = newConnection;
        setIsConnected(true);
        setError(null);
        onConnected?.();
      } catch (err) {
        console.error(`❌ SignalR connection failed for ${hubPath}:`, err);
        setError(err as Error);
        setIsConnected(false);
      }
    };

    connect();

    // Cleanup on unmount
    return () => {
      if (connectionRef.current) {
        connectionRef.current
          .stop()
          .then(() => {
            console.log(`🛑 SignalR connection stopped for ${hubPath}`);
          })
          .catch((err) => {
            console.error(`Error stopping SignalR connection:`, err);
          });
      }
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hubPath, autoConnect]);

  return {
    connection,
    isConnected,
    error,
  };
};
